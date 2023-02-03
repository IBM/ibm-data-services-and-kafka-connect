variable "ibmcloud_api_key" {}
variable "region" {
  default = "eu-gb"
}
variable "db_name" {
  default = "testdb"
}
variable "es_topic" {
  default = "es_topic"
}
variable "resource_group" {
  default = "cloudant_cos_kafka_demo"
}

variable "cos_bucket" {
  default = "cloudant-kafka-bucket"
  
}