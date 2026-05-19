variable "project" {
  description = "Project name used in resource naming."
  type        = string
}

variable "environment" {
  description = "Environment name used in resource naming."
  type        = string
}

variable "name" {
  description = "Component name used in resource naming."
  type        = string
}

variable "load_balancer_id" {
  description = "OCID of the load balancer. All resources are skipped when null."
  type        = string
  default     = null
}

variable "backend_set_policy" {
  description = "Load balancing policy for the backend set (e.g. ROUND_ROBIN, LEAST_CONNECTIONS, IP_HASH)."
  type        = string
  default     = "ROUND_ROBIN"
}

variable "health_checker" {
  description = "Health checker configuration. Required when load_balancer_id is set."
  type = object({
    protocol    = string
    port        = number
    url_path    = optional(string, "/")
    return_code = optional(number, 200)
  })
  default = null
}

variable "backend_ip_address" {
  description = "Private IP address of the backend instance. Required when load_balancer_id is set."
  type        = string
  default     = null
}

variable "backend_port" {
  description = "Port on the backend instance to forward traffic to. Required when load_balancer_id is set."
  type        = number
  default     = null
}

variable "hostname" {
  description = "Hostname used for host-header routing policy. When null, no routing policy is created."
  type        = string
  default     = null
}
