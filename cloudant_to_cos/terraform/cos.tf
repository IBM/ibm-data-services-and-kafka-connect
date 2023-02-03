resource "ibm_resource_instance" "kafkaCOS" {
  name              = "COSSink"
  resource_group_id = ibm_resource_group.resource_group.id
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
}

resource "ibm_cos_bucket" "kafkaBucket" {
  bucket_name          = var.cos_bucket
  resource_instance_id = ibm_resource_instance.kafkaCOS.id
  region_location      = var.region
  storage_class        = "standard"
}

resource "ibm_resource_key" "resourceKey" {
  name                 = "kakfka-bucket-key"
  resource_instance_id = ibm_resource_instance.kafkaCOS.id
  role                 = "Manager"
}

output "bucketcrn" {
  value = ibm_cos_bucket.kafkaBucket.crn
}

output "cos_endpoint" {
  value = ibm_cos_bucket.kafkaBucket.s3_endpoint_public
}

output "cos_credentials" {
  value = ibm_resource_key.resourceKey.credentials
  sensitive = true
}

output "cos_region" {
  value = ibm_cos_bucket.kafkaBucket.region_location
}

output "bucket_name" {
  value = ibm_cos_bucket.kafkaBucket.bucket_name
}