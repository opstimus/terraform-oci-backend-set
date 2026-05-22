terraform {
  required_version = ">= 1.3.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 8.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2"
    }
  }
}
