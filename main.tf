locals {
  rule_name = replace("${var.project}_${var.environment}_${var.name}_rule", "-", "_")
}

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

# resource "oci_load_balancer_backend" "main" {
#   load_balancer_id = var.load_balancer_id
#   backendset_name  = oci_load_balancer_backend_set.main.name
#   ip_address       = var.backend_ip_address
#   port             = var.backend_port
# }

resource "null_resource" "backend_register" {
  triggers = {
    load_balancer_id = var.load_balancer_id
    backendset_name  = oci_load_balancer_backend_set.main.name
    ip_address       = var.backend_ip_address
    port             = tostring(var.backend_port)
    script_path      = path.module
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash"]
    command     = "${path.module}/scripts/register_backend.sh"
    environment = {
      LB_ID            = var.load_balancer_id
      BACKEND_SET_NAME = oci_load_balancer_backend_set.main.name
      IP_ADDRESS       = var.backend_ip_address
      PORT             = tostring(var.backend_port)
    }
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash"]
    command     = "${self.triggers.script_path}/scripts/deregister_backend.sh"
    environment = {
      LB_ID            = self.triggers.load_balancer_id
      BACKEND_SET_NAME = self.triggers.backendset_name
      IP_ADDRESS       = self.triggers.ip_address
      PORT             = self.triggers.port
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "null_resource" "routing_rule" {
  triggers = {
    rule_name           = local.rule_name
    routing_condition   = var.routing_condition
    backend_set_name    = oci_load_balancer_backend_set.main.name
    routing_policy_name = var.routing_policy_name
    load_balancer_id    = var.load_balancer_id
    script_hash         = filesha256("${path.module}/scripts/upsert_routing_rule.sh")
  }

  provisioner "local-exec" {
    command     = "${path.module}/scripts/upsert_routing_rule.sh"
    interpreter = ["/bin/bash"]
    environment = {
      LB_ID            = var.load_balancer_id
      POLICY_NAME      = var.routing_policy_name
      RULE_NAME        = local.rule_name
      RULE_CONDITION   = var.routing_condition
      BACKEND_SET_NAME = oci_load_balancer_backend_set.main.name
    }
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "${path.module}/scripts/remove_routing_rule.sh"
    interpreter = ["/bin/bash"]
    environment = {
      LB_ID       = self.triggers.load_balancer_id
      POLICY_NAME = self.triggers.routing_policy_name
      RULE_NAME   = self.triggers.rule_name
    }
  }

}
