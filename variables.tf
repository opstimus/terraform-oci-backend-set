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
  description = "OCID of the load balancer."
  type        = string
}

variable "backend_set_policy" {
  description = "Load balancing policy for the backend set."
  type        = string
  default     = "ROUND_ROBIN"

  validation {
    condition     = contains(["ROUND_ROBIN", "LEAST_CONNECTIONS", "IP_HASH"], var.backend_set_policy)
    error_message = "backend_set_policy must be one of: ROUND_ROBIN, LEAST_CONNECTIONS, IP_HASH."
  }
}

variable "backend_set_health_checker_protocol" {
  description = "Protocol for health checks. One of: HTTP, HTTPS, TCP."
  type        = string

  validation {
    condition     = contains(["HTTP", "HTTPS", "TCP"], var.backend_set_health_checker_protocol)
    error_message = "backend_set_health_checker_protocol must be one of: HTTP, HTTPS, TCP."
  }
}

variable "backend_set_health_checker_port" {
  description = "Port on the backend to use for health checks."
  type        = number
}

variable "backend_set_health_checker_url_path" {
  description = "URL path for HTTP/HTTPS health checks."
  type        = string
  default     = "/"
}

variable "backend_set_health_checker_return_code" {
  description = "Expected HTTP return code for HTTP/HTTPS health checks."
  type        = number
  default     = 200
}

variable "backend_set_health_checker_interval_ms" {
  description = "Interval between health checks in milliseconds."
  type        = number
  default     = 10000
}

variable "backend_set_health_checker_timeout_in_millis" {
  description = "Timeout for each health check in milliseconds."
  type        = number
  default     = 3000
}

variable "backend_set_health_checker_retries" {
  description = "Number of retries before marking the backend as unhealthy."
  type        = number
  default     = 3
}

variable "backend_ip_address" {
  description = "Private IP address of the backend instance."
  type        = string
}

variable "backend_port" {
  description = "Port on the backend instance to forward traffic to."
  type        = number
}

variable "hostname" {
  description = "Hostname used in the host-header routing rule condition."
  type        = string
}

variable "routing_policy_condition_language_version" {
  description = "Condition language version for the routing policy."
  type        = string
  default     = "V1"
}
