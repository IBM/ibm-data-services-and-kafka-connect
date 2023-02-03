#!/bin/bash

#Certificate Management
#To connect to ICD MongoDB, Kafka connectors need a TLS certicate, which is part of the Terraform output in the config.json file. So , take the base64 certs from the config and convert them into files

echo $CONFIG | jq -r ".sourceCert.value" | base64 -d > source.cert
echo $CONFIG | jq -r ".sinkCert.value" | base64 -d > sink.cert


#These certificates then need to be added to the Java keystore

if [ $1 = 'local' ]; then
    sudo keytool -import -file ./source.cert -cacerts -alias sourceCert -trustcacerts -storepass changeit -noprompt
    sudo keytool -import -file ./sink.cert -cacerts -alias sinkCert -trustcacerts -storepass changeit -noprompt
else
    keytool -import -file ./source.cert -cacerts -alias sourceCert -trustcacerts -storepass changeit -noprompt
    keytool -import -file ./sink.cert -cacerts -alias sinkCert -trustcacerts -storepass changeit -noprompt
fi


#can now remove these because they have been stored in the keystore 

rm source.cert
rm sink.cert

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
 

# configure mongo-source.properties
DATA_TOPIC=`echo $CONFIG | jq -r '.data_topic.value'`
MONGO_PASS=`echo $CONFIG | jq -r '.mongoPassword.value'`
MONGO_URI_TEMP=`echo $CONFIG | jq -r '.sourceUrl.value' | sed -e 's/,.*$//'`
#echo $MONGO_URI_TEMP 
MONGO_URI=`echo $MONGO_URI_TEMP | sed -e s/\\$PASSWORD/$MONGO_PASS/g`
#echo $MONGO_URI
MONGO_DB="products"
MONGO_CLL="catalog"
sed -e "s/<DATA_TOPIC>/$DATA_TOPIC/g" \
    -e "s~<MONGO_URI>~$MONGO_URI~g" \
    -e "s/<MONGO_DB>/$MONGO_DB/g" \
    -e "s/<MONGO_CLL>/$MONGO_CLL/g"  template-mongo-source.properties > kafka/config/mongo-source.properties
   
# configure mongo-sink.properties
MONGO_URI_TEMP=`echo $CONFIG | jq -r '.sinkUrl.value' | sed -e 's/,.*$//'`
#echo $MONGO_URI_TEMP 
MONGO_URI=`echo $MONGO_URI_TEMP | sed -e s/\\$PASSWORD/$MONGO_PASS/g`
#echo $MONGO_URI
sed -e "s/<DATA_TOPIC>/$DATA_TOPIC/g" \
    -e "s~<MONGO_URI>~$MONGO_URI~g" \
    -e "s/<MONGO_DB>/$MONGO_DB/g" \
    -e "s/<MONGO_CLL>/$MONGO_CLL/g"  template-mongo-sink.properties > kafka/config/mongo-sink.properties


# run Kafka with connectors

./kafka/bin/connect-standalone.sh ./kafka/config/connect-standalone.properties ./kafka/config/mongo-source.properties ./kafka/config/mongo-sink.properties 
