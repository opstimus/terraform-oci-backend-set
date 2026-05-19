output "backend_set_name" {
  description = "Name of the created backend set, or null if skipped."
  value       = length(oci_load_balancer_backend_set.main) > 0 ? oci_load_balancer_backend_set.main[0].name : null
}

output "backend_set_id" {
  description = "OCID-based identifier of the backend set, or null if skipped."
  value       = length(oci_load_balancer_backend_set.main) > 0 ? oci_load_balancer_backend_set.main[0].id : null
}

output "routing_policy_name" {
  description = "Name of the routing policy, or null if not created."
  value       = length(oci_load_balancer_routing_policy.main) > 0 ? oci_load_balancer_routing_policy.main[0].name : null
}
