resource "oci_load_balancer_backend_set" "main" {
  count            = var.load_balancer_id != null ? 1 : 0
  load_balancer_id = var.load_balancer_id
  name             = "${var.project}-${var.environment}-${var.name}"
  policy           = var.backend_set_policy

  health_checker {
    protocol    = var.health_checker.protocol
    port        = var.health_checker.port
    url_path    = var.health_checker.url_path
    return_code = var.health_checker.return_code
  }

  lifecycle {
    precondition {
      condition     = var.health_checker != null
      error_message = "health_checker must be provided when load_balancer_id is set."
    }
    precondition {
      condition     = var.backend_port != null
      error_message = "backend_port must be provided when load_balancer_id is set."
    }
    precondition {
      condition     = var.backend_ip_address != null
      error_message = "backend_ip_address must be provided when load_balancer_id is set."
    }
  }
}

resource "oci_load_balancer_backend" "main" {
  count            = var.load_balancer_id != null ? 1 : 0
  load_balancer_id = var.load_balancer_id
  backendset_name  = oci_load_balancer_backend_set.main[0].name
  ip_address       = var.backend_ip_address
  port             = var.backend_port
}

resource "oci_load_balancer_routing_policy" "main" {
  count                      = var.load_balancer_id != null && var.hostname != null ? 1 : 0
  condition_language_version = "V1"
  load_balancer_id           = var.load_balancer_id
  name                       = "${var.project}-${var.environment}-${var.name}-routing"

  rules {
    name      = "${var.project}-${var.environment}-${var.name}-host-rule"
    condition = "http.request.headers[(i 'host')] eq (i '${var.hostname}')"
    actions {
      name             = "FORWARD_TO_BACKENDSET"
      backend_set_name = oci_load_balancer_backend_set.main[0].name
    }
  }

  depends_on = [oci_load_balancer_backend_set.main]
}
