# Mongo/EventStreams/Mongo - Kafka Connect demo

This repo contains a demonstration of streaming Mongo 4.2 changes to Mongo 4.4 via IBM Event Streams using "Kafka Connect" connectors.

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
cd kafkaconnect/mongo_to_mongo
```

## Create an IBM Cloud API Key

Follow the steps in [this document](https://cloud.ibm.com/docs/account?topic=account-userapikey&interface=ui#create_user_key) to create an API key and make a note of it.

## Deploying infrastructure
The following IBM Cloud services will be deployed via Terraform

- IBM Cloud resource group
- IBM MongoDB v4.2 as a source DB
- IBM MongoDB v4.4 as a destination (sink) DB
- IBM Event Streams
- Various credentials

Create a `terraform/terraform.tfvars` file containing:

```
ibmcloud_api_key = <YOUR_IBM_CLOUD_API_KEY>
region = eu-gb 
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

Download the latest version of [Apache Kafka](https://kafka.apache.org/downloads) to the `mongo_to_mongo` directory and unzip it with

```sh
tar -xavf kafka_2.12-3.3.1.tgz
mv kafka_2.12-3.3.1/* kafka
rmdir kafka_2.12-3.3.1
```



## Download the connector


### The MongoDB Kafka connector



The [MongoDB Kafka Connector](https://github.com/mongodb/mongo-kafka) can be downloaded from [here](https://github.com/mongodb/mongo-kafka/archive/refs/heads/master.zip) and unpacked

```sh
unzip mongo-kafka-master.zip
mv mongo-kafka-master/* plugins/mongo-kafka/
rmdir mongo-kafka-master
```

Then we need to build the connector with Gradle

```sh
cd plugins/mongo-kafka
./gradlew allJar
cd ..
cd ..
```

## Running locally

We are now in a position to run locally.

```sh
export CONFIG=`cat config.json`
./run.sh local
```

This takes configuration from our Terraform config.json file and places them in `.properties` files that can be consumed by the Java application.

### Watch your data replicate
The last command in the `run.sh` file should have started Kafka Connect with a connection to both source and sink databases. The first time it runs it will attempt to copy all the existing data in the source database into the target database. Then it pauses, listening for changes.
At this point you should be able to add a document to your source database and see it replicate almost instantly to the target database.

NOTE: If your Kafka Connect instance fails to start properly, you may have a mismatch between your local version of Java and the one Kafka Connect is expecting.

## Running in Docker

### Build a docker image

```sh
docker build -t mongotomongo .
```

### Run in Docker

```sh
export CONFIG=`cat config.json`
echo "CONFIG=$CONFIG" > env.list
docker run -it --env-file env.list -p 8083:8083 mongotomongo
```


## Running in IBM Code Engine

For this you need to be logged into the [IBM Cloud CLI](https://www.ibm.com/uk-en/cloud/cli).

```
ibmcloud login --sso
```

Make sure your account is targeting a resource group

```
ibmcloud target -g mongo_mongo_kafka_demo 
```

Let docker access your ibm container registry

```
ibmcloud cr login
```

Push docker image to container registry

```
docker tag mongotomongo uk.icr.io/kafkaconnect/mongotomongo:latest
docker push uk.icr.io/kafkaconnect/mongotomongo:latest 
```

Create a Code Engine project

```
ibmcloud ce project create --name mongotomongo
ibmcloud ce project select -n mongotomongo
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
ibmcloud ce application create --name mongotomongo \
        --image uk.icr.io/kafkaconnect/mongotomongo \
        --port 8083  \
        --registry-secret contkey \
        --min 1 \
        --env-from-secret config
```