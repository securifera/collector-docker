
#!/bin/bash

arch="linux_amd64"

while getopts ":p:a:" opt; do
  case $opt in
    p) gitpwd="$OPTARG"
    ;;
    a) arch="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    exit 1
    ;;
  esac

  case $OPTARG in
    -*) echo "Option $opt needs a valid argument"
    exit 1
    ;;
  esac
done

if [ -z "$gitpwd" ]
then
      echo "[-] Usage: collector_install.sh -p github_credentials (-a 'CPU Arch')"
      exit 1
fi


# install initial tools
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y ca-certificates
sudo DEBIAN_FRONTEND=noninteractive apt install -y sudo wget curl net-tools git screen

openssl s_client -showcerts -connect google.com:443 < /dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ca.crt
cp ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# install python pip
sudo DEBIAN_FRONTEND=noninteractive apt install -y python3-pip
pip config set global.trusted-host "pypi.org files.pythonhosted.org pypi.python.org" --trusted-host=pypi.python.org --trusted-host=pypi.org --trusted-host=files.pythonhosted.org

# install luigi/waluigi
sudo python3 -m pip install luigi
sudo python3 -m pip install pycryptodomex
sudo python3 -m pip install --upgrade requests
sudo python3 -m pip install netifaces

# Create luigi config file
sudo mkdir /opt/collector
echo "[worker]" | sudo tee /opt/collector/luigi.cfg
echo "no_install_shutdown_handler=True" | sudo tee -a /opt/collector/luigi.cfg

cd /opt
sudo git clone -c http.sslVerify=false https://$gitpwd@github.com/reconsec/waluigi.git
cd waluigi && sudo python3 setup.py install

###############
# scanner stuff
###############

# dependencies
sudo DEBIAN_FRONTEND=noninteractive apt install -y libssl-dev libpcap-dev masscan autoconf

# install nmap
cd /opt
sudo DEBIAN_FRONTEND=noninteractive apt install -y build-essential
sudo git clone -c http.sslVerify=false https://$gitpwd@github.com/reconsec/nmap.git
cd nmap && sudo ./configure --without-ncat --without-zenmap --without-nping && sudo make && sudo make install

# python modules
sudo python3 -m pip install netaddr
sudo python3 -m pip install python-libnmap
sudo python3 -m pip install tqdm
sudo python3 -m pip install shodan

# Install nuclei
sudo DEBIAN_FRONTEND=noninteractive apt install -y jq unzip
cd /tmp; curl -k -s https://api.github.com/repos/projectdiscovery/nuclei/releases/latest | jq -r ".assets[] | select(.name | contains(\"$arch\")) | .browser_download_url" | sudo wget --no-check-certificate -i - ; sudo unzip nuclei*.zip; sudo mv nuclei /usr/local/bin/ ; sudo rm nuclei*.zip
sudo chmod +x /usr/local/bin/nuclei

# Install nuclei templates
cd /opt
sudo git clone -c http.sslVerify=false https://$gitpwd@github.com/reconsec/nuclei-templates.git
    
# Screenshot dependencies
sudo DEBIAN_FRONTEND=noninteractive apt install -y fonts-liberation libgbm1 libappindicator3-1 openssl

# Pyshot
cd /opt
sudo git clone -c http.sslVerify=false https://github.com/securifera/pyshot.git
cd pyshot && sudo python3 setup.py install

# PhantomJs
if [ "$arch" = "linux_amd64" ]
then
  cd /opt
  wget --no-check-certificate -O /tmp/phantomjs-2.1.1.tar.bz2 https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2
  tar -C /tmp -xvf /tmp/phantomjs-2.1.1.tar.bz2
  sudo cp /tmp/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/bin
else
  echo "No phantom JS release for arch $arch. Consider building from source."
fi

# Install HTTPX
cd /tmp; curl -k -s https://api.github.com/repos/projectdiscovery/httpx/releases/latest | jq -r ".assets[] | select(.name | contains(\"$arch\")) | .browser_download_url" | sudo wget --no-check-certificate -i - ; sudo unzip httpx*.zip; sudo mv httpx /usr/local/bin/ ; sudo rm httpx*.zip
sudo chmod +x /usr/local/bin/httpx

# Install Subfinder
cd /tmp; curl -k -s https://api.github.com/repos/projectdiscovery/subfinder/releases/latest | jq -r ".assets[] | select(.name | contains(\"$arch\")) | .browser_download_url" | sudo wget --no-check-certificate -i - ; sudo unzip subfinder*.zip; sudo mv subfinder /usr/local/bin/; sudo rm subfinder*.zip
sudo chmod +x /usr/local/bin/subfinder

if [ "$arch" = "linux_arm64" ]
then
    ferox_version="aarch64"
else
    ferox_version="x86_64-linux"
fi

# Install FeroxBuster
cd /tmp; curl -k -s https://api.github.com/repos/epi052/feroxbuster/releases/latest | jq -r ".assets[] | select(.name | contains(\"$ferox_version-feroxbuster.zip\")) | .browser_download_url" | sudo wget --no-check-certificate -i - ; sudo unzip *feroxbuster*.zip; sudo mv feroxbuster /usr/local/bin/ ; sudo rm *feroxbuster*.zip
sudo chmod +x /usr/local/bin/feroxbuster

# Badsecrets
sudo python3 -m pip install badsecrets
