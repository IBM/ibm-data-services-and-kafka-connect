# Cloudant/EventStreams/COS - Kafka Connect demo

This repo contains a demonstration of streaming Cloudant changes to Cloud Object Storage (COS) via IBM Event Streams using "Kafka Connect" connectors.

## Prequisites

- Java
- Gradle
- Git
- jq
- Terraform

Optionally, if you want to run this in Code Engine, you will need

- Docker
- IBM CLI


## Clone the repo

Clone this GitHub repo and then change directory into it e.g.

```sh
git clone https://github.ibm.com/glynn-bird/kafkaconnect.git
cd kafkaconnect/cloudant_to_cos
```

## Create an IBM Cloud API Key

Follow the steps in [this document](https://cloud.ibm.com/docs/account?topic=account-userapikey&interface=ui#create_user_key) to create an API key and make a note of it.

## Deploying infrastructure

The following IBM Cloud services will be deployed via Terraform

- IBM Cloud resource group
- IBM Cloudant Standard
- IBM Cloud Object Storage
- IBM Event Streams
- Various credentials

Create a `terraform/terraform.tfvars` file containing:

```
ibmcloud_api_key = <YOUR_IBM_CLOUD_API_KEY>
region = eu-gb
db_name = test
```
(NOTE: You can use any available IBM Cloud region)


Then 

```sh
cd terraform
terraform init
terraform apply
```

We can then output the various configuration paramaters to a file:

```sh
terraform output --json | jq -c . > ../config.json
cd ..
```

## Download Kafka

Download the latest version of [Apache Kafka](https://kafka.apache.org/downloads) to the `cloudant_to_cos` directory and unzip it with

```sh
tar -xavf kafka_2.12-3.3.1.tgz
mv kafka_2.12-3.3.1/* kafka
rmdir kafka_2.12-3.3.1
```

## Download the connectors

### The Cloudant Kafka connector

The [Cloudant Kafka Connector](https://github.com/IBM/cloudant-kafka-connector) has a [releases](https://github.com/IBM/cloudant-kafka-connector/releases) where assets can be download. Download the [zip file](https://github.com/IBM/cloudant-kafka-connector/releases/download/v0.200.0/cloudant-kafka-connector-0.200.0.zip) and unpack it:

```sh
unzip cloudant-kafka-connector-0.200.0.zip
mv cloudant-kafka-connector-0.200.0/* plugins/cloudant-kafka/
rm cloudant-kafka-connector-0.200.0.zip
rmdir cloudant-kafka-connector-0.200.0
```

### The COS Kafka connector

The [COS Kafka Connector](https://github.com/ibm-messaging/kafka-connect-ibmcos-sink) can be downloaded from [here](https://github.com/ibm-messaging/kafka-connect-ibmcos-sink/archive/refs/heads/master.zip) and unpacked

```sh
unzip kafka-connect-ibmcos-sink-master.zip
mv kafka-connect-ibmcos-sink-master/* plugins/cos-kafka/
rmdir kafka-connect-ibmcos-sink-master
```

Then we need to build the connector with Gradle

```sh
cd plugins/cos-kafka
gradle shadowJar
cd ..
cd ..
```

## Running locally

We are now in a position to run locally.

```sh
export CONFIG=`cat config.json`
./run.sh
```

> This takes configuration from our Terraform config.json file and places them in `.properties` files that can be consumed by the Java application.

## Running in Docker

### Build a docker image

```sh
docker build -t cloudanttocos .
```

### Run in Docker

```sh
export CONFIG=`cat config.json`
echo "CONFIG=$CONFIG" > env.list
docker run -it --env-file env.list -p 8083:8083 cloudanttocos
```


## Running in IBM Code Engine

For this you need to be logged into the [IBM Cloud CLI](https://www.ibm.com/uk-en/cloud/cli).

```
ibmcloud login --sso
```

Make sure your account is targeting a resource group

```
ibmcloud target -g cloudant_cos_kafka_demo 
```

Let docker access your ibm container registry

```
ibmcloud cr login
```

Push docker image to container registry

```
docker tag kafkaconnect uk.icr.io/kafkaconnect/cloudanttocos:latest
docker push uk.icr.io/kafkaconnect/cloudanttocos:latest 
```

Create a Code Engine project

```
ibmcloud ce project create --name cloudanttocos
ibmcloud ce project select -n cloudanttocos
```


Create the registry access secret.. we need data from the config file

```
export CONTKEY_PASS=`cat config.json | jq -r '.containerKey.value'`
ibmcloud ce registry create --name contkey --server uk.icr.io --password "${CONTKEY_PASS}"
```
Create CE Secret

```
ibmcloud ce secret create --name config --from-file CONFIG=config.json
```
Create a CE app 

```
ibmcloud ce application create --name cloudanttocos \
        --image uk.icr.io/kafkaconnect/cloudanttocos \
        --port 8083  \
        --registry-secret contkey \
        --min 1 \
        --env-from-secret config
```
