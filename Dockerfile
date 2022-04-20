# BUILD INSTRUCTIONS & README
#   1) docker build --build-arg sshkey=<local public key file> --build-arg apikey=<RECON API KEY> --build-arg gituser=<git username> --build-arg gitpwd=<git token> -t collector:test1 .
#   2) docker run -d collector_test

# Start from base ubuntu 20.04 image
FROM ubuntu:20.04

# Dockerfile metadata
LABEL version="1.0"
LABEL desription="Test Collector Docker Image"

# Setup initial environment
ENV DEBIAN_FRONTEND noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /root
ARG gitpwd
ARG gituser

ARG cafile
ADD $cafile /usr/local/share/ca-certificates/

# install initial tools
RUN apt update
RUN apt install -y ca-certificates
RUN apt install -y sudo wget curl net-tools git screen
RUN update-ca-certificates

# install python pip
RUN apt install -y python3-pip

# install luigi/waluigi
RUN python3 -m pip install luigi
RUN python3 -m pip install pycryptodomex
RUN python3 -m pip install --upgrade requests

WORKDIR /opt
RUN git clone -c http.sslVerify=false https://$gituser:$gitpwd@github.com/reconsec/waluigi.git
RUN cd waluigi && sudo python3 setup.py install

# Luigi workaround for signal issues
RUN mkdir /opt/collector
RUN echo [worker] | tee /opt/collector/luigi.cfg
RUN echo no_install_shutdown_handler=True | tee -a /opt/collector/luigi.cfg


###############
# scanner stuff
###############

# dependencies
RUN apt install -y libssl-dev libpcap-dev masscan autoconf

# install nmap
RUN apt install -y build-essential
RUN git clone https://github.com/nmap/nmap.git
RUN cd nmap && ./configure --without-ncat --without-zenmap --without-nping && make && sudo make install

# python modules
RUN python3 -m pip install netaddr
RUN python3 -m pip install python-libnmap
RUN python3 -m pip install tqdm
RUN python3 -m pip install shodan

# Install nuclei
RUN apt install -y jq unzip
RUN curl -s https://api.github.com/repos/projectdiscovery/nuclei/releases/latest | jq -r ".assets[] | select(.name | contains(\"linux_amd64\")) | .browser_download_url" | wget --no-check-certificate -i -
RUN unzip nuclei*.zip
RUN mv nuclei /usr/local/bin
RUN rm nuclei*.zip

# Install nuclei templates
WORKDIR /opt
RUN git clone https://github.com/reconsec/nuclei-templates.git
    
# Screenshot dependencies
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/New_York
RUN apt install -y fonts-liberation libgbm1 libappindicator3-1 openssl

WORKDIR /opt
RUN git clone https://github.com/securifera/pyshot.git
RUN cd pyshot && sudo python3 setup.py install

RUN wget --no-check-certificate -O /tmp/phantomjs-2.1.1-linux-x86_64.tar.bz2 https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2
RUN tar -C /tmp -xvf /tmp/phantomjs-2.1.1-linux-x86_64.tar.bz2
RUN cp /tmp/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/bin

# Crobat
RUN curl -s https://api.github.com/repos/reconsec/SonarSearch/releases/latest | jq -r ".assets[] | select(.name | contains(\"linux-amd64\")) | .browser_download_url" | wget --no-check-certificate -i -
RUN unzip crobat*.zip
RUN mv crobat /usr/local/bin
RUN chmod +x /usr/local/bin/crobat
RUN rm crobat*.zip

# Install and configure SSHD.
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
ADD scan-poller /etc/init.d/scan-poller
RUN chmod 755 /etc/init.d/scan-poller

RUN echo "#!/bin/bash" > /root/start.sh
RUN echo "service scan-poller start" >> /root/start.sh
RUN echo "/usr/sbin/sshd -D -o ListenAddress=0.0.0.0" >> /root/start.sh
RUN chmod +x /root/start.sh

# Setup default command and/or parameters.
EXPOSE 22
CMD ["/root/start.sh"]
