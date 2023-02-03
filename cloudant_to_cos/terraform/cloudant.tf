resource "ibm_cloudant" "cloudant" {
  name     = "sourceCloudant"
  location = var.region
  plan     = "standard"
  resource_group_id = ibm_resource_group.resource_group.id
}

resource "ibm_cloudant_database" "cloudant_database" {
  instance_crn  = ibm_cloudant.cloudant.crn
  db            = var.db_name
}

resource "ibm_resource_key" "cloudant_credentials" {
  name                  = "cloudant-key"
  role                  = "Manager"
  resource_instance_id  = ibm_cloudant.cloudant.id
}

output "cloudant_credentials" {
  value = ibm_resource_key.cloudant_credentials.credentials
  sensitive = true
}

output "cloudant_db" {
  value = var.db_name
}