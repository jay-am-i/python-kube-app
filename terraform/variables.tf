variable "prefix" {
  type    = string
  default = "kubedemo"
}

variable "vm_size" {
  type    = string
  default = "Standard_A2_v2"
}

variable "node_count" {
  type    = number
  default = 1
}

variable "max_pods" {
  type    = number
  default = 30
}