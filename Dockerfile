# BUILD INSTRUCTIONS & README
#   1) docker build --build-arg sshkey=<local public key file> --build-arg gituser=<git username> --build-arg gitpwd=<git token> -t collector:test1 .
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
RUN apt install -y sudo wget curl net-tools git
RUN update-ca-certificates

# install python pip
RUN apt install -y python3-pip

# install luigi/waluigi
RUN python3 -m pip install luigi
RUN python3 -m pip install pycryptodomex
RUN git clone -c http.sslVerify=false https://$gituser:$gitpwd@github.com/reconsec/waluigi.git

###############
# scanner stuff
###############

# dependencies
RUN apt install -y libssl-dev libpcap-dev masscan autoconf

# golang
RUN wget https://golang.org/dl/go1.16.5.linux-amd64.tar.gz
RUN rm -rf /usr/local/go 
RUN tar -C /usr/local -xzf go1.16.5.linux-amd64.tar.gz
RUN rm go1.16.5.linux-amd64.tar.gz
RUN echo export PATH=$PATH:/usr/local/go/bin >> ~/.profile

# install nmap
RUN apt install -y build-essential
RUN git clone https://github.com/nmap/nmap.git
RUN cd nmap && ./configure && make && make install

# python modules
RUN python3 -m pip install netaddr
RUN python3 -m pip install python-libnmap

# Install nuclei
#RUN cd /opt && \
#    git clone https://github.com/projectdiscovery/nuclei.git && \
#    cd nuclei/v2/cmd/nuclei && \
#    /usr/local/go/bin/go build && \
#    mv nuclei /usr/local/bin/
RUN apt install -y jq unzip
RUN curl -s https://api.github.com/repos/projectdiscovery/nuclei/releases/latest | jq -r ".assets[] | select(.name | contains(\"linux_amd64\")) | .browser_download_url" | wget -i -
RUN unzip nuclei*.zip
RUN mv nuclei /usr/local/bin
RUN nuclei -ut
    
# Screenshot dependencies
RUN python3 -m pip install selenium
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/New_York
RUN apt install -y fonts-liberation libgbm1 libappindicator3-1 openssl
RUN apt install -y libxml2-utils imagemagick

WORKDIR /root/waluigi
RUN git clone https://github.com/securifera/pyshot.git
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
RUN apt install -y ./google-chrome-stable_current_amd64.deb
RUN curl --resolve chromedriver.storage.googleapis.com:443:142.250.114.128 --output chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/$(curl --resolve chromedriver.storage.googleapis.com:443:142.250.114.128 https://chromedriver.storage.googleapis.com/ 2>/dev/null | xmllint --format - | grep $(google-chrome-stable --version | awk '{print $3;}' | sed 's/\.[[:digit:]]\+$//') | grep linux | tail -1 | sed 's/<Key>//' | sed 's/<\/Key>//' | sed -e 's/^[[:space:]]*//')
RUN unzip chromedriver_linux64.zip
RUN mv chromedriver /usr/bin
RUN wget -O /tmp/phantomjs-2.1.1-linux-x86_64.tar.bz2 https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2
RUN tar -C /tmp -xvf /tmp/phantomjs-2.1.1-linux-x86_64.tar.bz2
RUN cp /tmp/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/bin
RUN rm chromedriver_linux64.zip
RUN rm google-chrome-stable_current_amd64.deb
RUN /usr/local/go/bin/go get github.com/cgboal/sonarsearch/cmd/crobat

# Install and configure SSHD.
RUN apt install -y openssh-server
RUN mkdir -p /var/run/sshd \
  && mkdir /root/.ssh \
  && chmod 700 /root/.ssh \
  && touch /root/.ssh/authorized_keys
ARG sshkey
ADD $sshkey /root/.ssh/authorized_keys

# Setup default command and/or parameters.
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D", "-o", "ListenAddress=0.0.0.0"]
