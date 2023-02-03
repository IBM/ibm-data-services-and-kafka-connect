FROM ubuntu:22.04
WORKDIR /usr/src/app

# Install jq
RUN apt -y update
RUN apt -y upgrade
RUN apt -y install jq

# Install Java
RUN apt -y install openjdk-17-jdk openjdk-17-jre

# Install our template properties files
COPY *.properties ./

# our run.sh
COPY run.sh ./

# our Kafka connect plugins
COPY plugins ./plugins

# and Kafka itself
COPY kafka ./kafka

# Kafka exposes a web service on port 8083
EXPOSE 8083

# when running the container, execute run.sh
ENTRYPOINT ["./run.sh"]
