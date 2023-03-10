

resource "ibm_resource_instance" "event_streams_instance" {
  name              = "eventStreamsService"
  service           = "messagehub"
  plan              = "standard" 
  location          = var.region
  resource_group_id = ibm_resource_group.resource_group.id

}

resource "ibm_event_streams_topic" "es_topic" {
  resource_instance_id = ibm_resource_instance.event_streams_instance.id
  name                 = var.es_topic
  partitions           = 1
  config = {
    "cleanup.policy"  = "compact,delete"
    "retention.ms"    = "86400000"
    "retention.bytes" = "1073741824"
    "segment.bytes"   = "536870912"
  }
}

resource "ibm_event_streams_topic" "offset_topic" {
  resource_instance_id = ibm_resource_instance.event_streams_instance.id
  name                 = "connect-offsets"
  partitions           = 1
  config = {
    "cleanup.policy"  = "compact,delete"
    "retention.ms"    = "86400000"
    "retention.bytes" = "1073741824"
    "segment.bytes"   = "536870912"
  }
}


resource "ibm_resource_key" "eventstreams_credentials" {
  name                  = "my-db-key"
  role                  = "Manager"
  resource_instance_id  = ibm_resource_instance.event_streams_instance.id
}

output "eventstreams_credentials" {
  value = ibm_resource_key.eventstreams_credentials.credentials
  sensitive = true
}

output "es_url" {
  value = ibm_event_streams_topic.es_topic.kafka_http_url
  description = "The URL to access eventstreams"
}

output "kafka_brokers_sasl" {
  value = ibm_resource_instance.event_streams_instance.extensions
  description = "the kafka brokers"
}

output "offset_topic" {
  value = ibm_event_streams_topic.offset_topic.name
}

output "data_topic" {
  value = ibm_event_streams_topic.es_topic.name
}