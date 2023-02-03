variable "ibmcloud_api_key" {}
variable "region" {
  default = "eu-gb"
}
variable "es_topic" {
  default = "es_topic"
}
variable "resource_group" {
  default = "mongo_mongo_kafka_demo"
}

variable "source_version" {
  default = "4.2"
}

variable "sink_version" {
  default = "4.4"
}