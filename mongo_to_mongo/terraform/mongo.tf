resource "random_string" "mongoPassword" {
  length           = 20
  special          = false
}

resource "ibm_database" "mongoSource" {
  resource_group_id = ibm_resource_group.resource_group.id
  name              = "mongodb-source"
  service           = "databases-for-mongodb"
  plan              = "standard"
  location          = var.region
  version           = var.source_version
  adminpassword = random_string.mongoPassword.result

 
  timeouts {
    create = "120m"
    update = "120m"
    delete = "15m"
  }
}

resource "ibm_database" "mongoSink" {
  resource_group_id = ibm_resource_group.resource_group.id
  name              = "mongodb-sink"
  service           = "databases-for-mongodb"
  plan              = "standard"
  location          = var.region
  version           = var.sink_version
  adminpassword = random_string.mongoPassword.result

 
  timeouts {
    create = "120m"
    update = "120m"
    delete = "15m"
  }
}
data "ibm_database_connection" "source_connection" {
    endpoint_type = "public"
    deployment_id = ibm_database.mongoSource.id
    user_id = "admin"
    user_type = "database"
}

data "ibm_database_connection" "sink_connection" {
    endpoint_type = "public"
    deployment_id = ibm_database.mongoSink.id
    user_id = "admin"
    user_type = "database"
}
output "sourceUrl" {
  value = data.ibm_database_connection.source_connection.mongodb[0].composed[0]
}

output "sinkUrl" {
  value = data.ibm_database_connection.sink_connection.mongodb[0].composed[0]
}

output "sourceHost" {
value = data.ibm_database_connection.source_connection.mongodb[0].hosts[0].hostname
}

output "sinkHost" {
value = data.ibm_database_connection.sink_connection.mongodb[0].hosts[0].hostname
}

output "sourcePort" {
value = data.ibm_database_connection.source_connection.mongodb[0].hosts[0].port
}

output "sinkPort" {
value = data.ibm_database_connection.sink_connection.mongodb[0].hosts[0].port
}

output "mongoPassword" {
  value = random_string.mongoPassword.result
  sensitive = true
}

output "sourceCert" {
  value = data.ibm_database_connection.source_connection.mongodb[0].certificate[0].certificate_base64
}

output "sinkCert" {
  value = data.ibm_database_connection.sink_connection.mongodb[0].certificate[0].certificate_base64
}