output "backend_set_name" {
  description = "Name of the created backend set."
  value       = oci_load_balancer_backend_set.main.name
}

output "backend_set_id" {
  description = "Composite identifier (loadBalancers/{lb-ocid}/backendSets/{name}) of the backend set. This is not an OCID."
  value       = oci_load_balancer_backend_set.main.id
}

output "routing_policy_name" {
  description = "Name of the routing policy."
  value       = oci_load_balancer_load_balancer_routing_policy.main.name
}

output "backend_address" {
  description = "Registered backend address in ip:port format."
  value       = "${oci_load_balancer_backend.main.ip_address}:${oci_load_balancer_backend.main.port}"
}
