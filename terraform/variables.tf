# locals = [
#   "1",
#   "3"
# ]


variable "regions" {
  description = "(Optional) Specifies one or more Azure region where the resource is deployed. Defaults to `[]`."
  type        = set(string)
  default = [
    "UK South" #,
    # "UK West"
  ]
}

variable "addr_space" {
  default = "131.200.2.0/24"
}
