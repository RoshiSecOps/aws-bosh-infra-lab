#!usr/bin/env/bash

# Install base packages and ruby
sudo apt-get install -y build-essential zlib1g-dev ruby ruby-dev openssl \
  libxslt1-dev libxml2-dev libssl-dev libreadline-dev libyaml-dev \
  libsqlite3-dev sqlite3 jq git curl iptables ca-certificates gnupg
ruby -v

# Install bosh cli
curl -Lo ./bosh "https://github.com/cloudfoundry/bosh-cli/releases/download/v7.8.6/bosh-cli-7.8.6-linux-amd64"
chmod +x ./bosh
sudo mv ./bosh /usr/local/bin/bosh
bosh --version

# Install and setup Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker $USER
sudo chmod 666 /var/run/docker.sock
docker ps
docker network create --subnet=10.245.0.0/16 bosh-net

# Create deployment dir and clone it
mkdir -p ~/workspace ~/deployments/docker
git clone https://github.com/cloudfoundry/bosh-deployment.git ~/workspace/bosh-deployment

# Create the director
cd ~/deployments/docker
bosh create-env ~/workspace/bosh-deployment/bosh.yml \
  --state=state.json \
  --vars-store=creds.yml \
  -o ~/workspace/bosh-deployment/docker/cpi.yml \
  -o ~/workspace/bosh-deployment/docker/unix-sock.yml \
  -o ~/workspace/bosh-deployment/bosh-lite.yml \
  -o ~/workspace/bosh-deployment/bosh-lite-runc.yml \
  -o ~/workspace/bosh-deployment/jumpbox-user.yml \
  -v director_name=docker-bosh \
  -v internal_cidr=10.245.0.0/16 \
  -v internal_gw=10.245.0.1 \
  -v internal_ip=10.245.0.10 \
  -v outbound_network_name=NatNetwork \
  -v network=bosh-net \
  -v docker_host="unix:///var/run/docker.sock"

# Login
bosh alias-env docker-bosh -e 10.245.0.10 --ca-cert <(bosh int ./creds.yml --path /director_ssl/ca)
export BOSH_ENVIRONMENT=docker-bosh
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=$(bosh int ./creds.yml --path /admin_password)
bosh env