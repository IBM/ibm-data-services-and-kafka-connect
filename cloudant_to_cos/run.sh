#!/bin/bash

# configure the connect-standalone.properties
BROKER1=`echo $CONFIG | jq -r '.eventstreams_credentials.value["kafka_brokers_sasl.0"]'`
BROKER2=`echo $CONFIG | jq -r '.eventstreams_credentials.value["kafka_brokers_sasl.1"]'`
BROKER3=`echo $CONFIG | jq -r '.eventstreams_credentials.value["kafka_brokers_sasl.2"]'`
BROKER4=`echo $CONFIG | jq -r '.eventstreams_credentials.value["kafka_brokers_sasl.3"]'`
BROKER5=`echo $CONFIG | jq -r '.eventstreams_credentials.value["kafka_brokers_sasl.4"]'`
BROKER6=`echo $CONFIG | jq -r '.eventstreams_credentials.value["kafka_brokers_sasl.5"]'`
BROKER_LIST="${BROKER1},${BROKER2},${BROKER3},${BROKER4},${BROKER5},${BROKER6}"
KAFKA_PASSWORD=`echo $CONFIG | jq -r '.eventstreams_credentials.value.apikey'`
KAFKA_USERNAME=`echo $CONFIG | jq -r '.eventstreams_credentials.value.user'`
OFFSET_TOPIC=`echo $CONFIG | jq -r '.offset_topic.value'`
PLUGIN_PATH="$PWD/plugins"

# substitute our configuration data into the template.
# Note the last substitution contains / characters so we use ? as a sed delimiter.
sed -e "s/<BROKER_LIST>/$BROKER_LIST/g" \
    -e "s/<KAFKA_PASSWORD>/$KAFKA_PASSWORD/g" \
    -e "s/<KAFKA_USERNAME>/$KAFKA_USERNAME/g" \
    -e "s/<OFFSET_TOPIC>/$OFFSET_TOPIC/g" \
    -e "s?<PLUGIN_PATH>?${PLUGIN_PATH}?g" \
    template-connect-standalone.properties > kafka/config/connect-standalone.properties

# configure connect-cloudant-changes-source.properties
DATA_TOPIC=`echo $CONFIG | jq -r '.data_topic.value'`
CLOUDANT_URL=`echo $CONFIG | jq -r '.cloudant_credentials.value.url'`
CLOUDANT_API_KEY=`echo $CONFIG | jq -r '.cloudant_credentials.value.apikey'`
CLOUDANT_DB=`echo $CONFIG | jq -r '.cloudant_db.value'`
sed -e "s/<DATA_TOPIC>/$DATA_TOPIC/g" \
    -e "s?<CLOUDANT_URL>?$CLOUDANT_URL?g" \
    -e "s/<CLOUDANT_API_KEY>/$CLOUDANT_API_KEY/g" \
    -e "s/<CLOUDANT_DB>/$CLOUDANT_DB/g" \
    template-cloudant-source.properties > kafka/config/cloudant-source.properties

# configure cos-sink.properties
COS_API_KEY=`echo $CONFIG | jq -r '.cos_credentials.value.apikey'`
COS_CRN=`echo $CONFIG | jq -r '.bucketcrn.value'`
COS_REGION=`echo $CONFIG | jq -r '.cos_region.value'`
COS_BUCKET=`echo $CONFIG | jq -r '.bucket_name.value'`
sed -e "s/<DATA_TOPIC>/$DATA_TOPIC/g" \
    -e "s/<COS_API_KEY>/$COS_API_KEY/g" \
    -e "s?<COS_CRN>?$COS_CRN?g" \
    -e "s/<COS_REGION>/$COS_REGION/g" \
    -e "s/<COS_BUCKET>/$COS_BUCKET/g" \
    template-cos-sink.properties > kafka/config/cos-sink.properties

# run Kafka with connectors
./kafka/bin/connect-standalone.sh ./kafka/config/connect-standalone.properties ./kafka/config/cloudant-source.properties ./kafka/config/cos-sink.properties 
