output "backend_set_name" {
  description = "Name of the created backend set."
  value       = oci_load_balancer_backend_set.main.name
}

output "backend_set_id" {
  description = "Composite identifier (loadBalancers/{lb-ocid}/backendSets/{name}) of the backend set. This is not an OCID."
  value       = oci_load_balancer_backend_set.main.id
}

output "rule_name" {
  description = "Name of the routing rule upserted into the shared routing policy."
  value       = local.rule_name
}

output "backend_address" {
  description = "Registered backend address in ip:port format."
  value       = "${var.backend_ip_address}:${var.backend_port}"
}
