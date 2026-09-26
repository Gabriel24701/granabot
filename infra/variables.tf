variable "project" {
  type    = string
  default = "granabot"
}

variable "environment" {
  type    = string
  default = "prod" # personal project, no staging environment for now
}

variable "location" {
  type    = string
  default = "brazilsouth"
}

variable "tags" {
  type = map(string)
  default = {
    project     = "granabot"
    environment = "prod"
    managed-by  = "terraform"
    owner       = "bielllb"
  }
}