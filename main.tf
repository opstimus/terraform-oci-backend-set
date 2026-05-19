resource "oci_load_balancer_backend_set" "main" {
  load_balancer_id = var.load_balancer_id
  name             = "${var.project}-${var.environment}-${var.name}"
  policy           = var.backend_set_policy

  health_checker {
    protocol          = var.backend_set_health_checker_protocol
    port              = var.backend_set_health_checker_port
    url_path          = var.backend_set_health_checker_url_path
    return_code       = var.backend_set_health_checker_return_code
    interval_ms       = var.backend_set_health_checker_interval_ms
    timeout_in_millis = var.backend_set_health_checker_timeout_in_millis
    retries           = var.backend_set_health_checker_retries
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_load_balancer_backend" "main" {
  load_balancer_id = var.load_balancer_id
  backendset_name  = oci_load_balancer_backend_set.main.name
  ip_address       = var.backend_ip_address
  port             = var.backend_port
}

resource "oci_load_balancer_load_balancer_routing_policy" "main" {
  condition_language_version = var.routing_policy_condition_language_version
  load_balancer_id           = var.load_balancer_id
  name                       = "${var.project}-${var.environment}-${var.name}-routing"

  rules {
    name      = "${var.project}-${var.environment}-${var.name}-host-rule"
    condition = "http.request.headers[(i 'host')] eq (i '${var.hostname}')"
    actions {
      name             = "FORWARD_TO_BACKENDSET"
      backend_set_name = oci_load_balancer_backend_set.main.name
    }
  }

  depends_on = [oci_load_balancer_backend.main]
}
