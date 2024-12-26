# BUILD INSTRUCTIONS & README
#   1) docker build --build-arg sshkey=<local public key file> --build-arg apikey=<RECON API KEY> -t collector:test1 .
#   2) docker run -d collector_test

# Start from base ubuntu 20.04 image
FROM ubuntu:22.04

ENV TZ=America/New_York

# Dockerfile metadata
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezoneLABEL version="1.0"

LABEL desription="Collector Docker Image"

# Setup initial environment
ENV DEBIAN_FRONTEND noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /tmp

RUN apt update
RUN apt install -y sudo git supervisor
RUN git clone https://github.com/securifera/reverge_collector.git /tmp/
RUN chmod +x /tmp/install.sh
RUN /tmp/install.sh

# Install SSH
RUN apt install -y openssh-server
RUN mkdir -p /var/run/sshd \
  && mkdir /root/.ssh \
  && chmod 700 /root/.ssh \
  && touch /root/.ssh/authorized_keys
ARG sshkey
ADD $sshkey /root/.ssh/authorized_keys

# Setup scan service
ARG apikey
RUN echo $apikey > /root/.collector_api_key

COPY ./supervisor_sshd.conf /etc/supervisor/conf.d/sshd.conf
COPY /tmp/supervisor_collector.conf /etc/supervisor/conf.d/collector.conf
CMD  /usr/bin/supervisord
