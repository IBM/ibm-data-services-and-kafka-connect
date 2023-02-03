resource "ibm_iam_service_id" "serviceID" {
  name        = "kafkaconnectSID"
  description = "The service id that Code Engine will use to access Container Registry"
}

resource "ibm_iam_service_policy" "kafkaConnectPolicy" {
  iam_service_id = ibm_iam_service_id.serviceID.id
  roles          = ["Writer"]

  resources {
    region = var.region
    service = "container-registry"
  }
}

resource "ibm_iam_service_api_key" "kafkaConnectApiKey" {
  name = "kafkaconnectkey"
  iam_service_id = ibm_iam_service_id.serviceID.iam_id
}

output "containerKey" {
  value =   ibm_iam_service_api_key.kafkaConnectApiKey.apikey
  sensitive = true
}