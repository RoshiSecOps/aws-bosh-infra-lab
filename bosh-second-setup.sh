#!usr/bin/env/bash

# Upload Stemcell
bosh upload-stemcell --sha1 3b0dca8c1dea88381043d7ade95870dd9974385a \
  "https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-resolute?v=0.184"

# Create cloud config
cat <<EOF > cloud-config.yml
azs:
- name: z1

vm_types:
- name: default

disk_types:
- name: default
  disk_size: 1024

networks:
- name: default
  type: manual
  subnets:
  - range: 10.245.0.0/16
    gateway: 10.245.0.1
    azs: [z1]
    dns: [8.8.8.8]
    reserved: [10.245.0.2-10.245.0.20]
    static: [10.245.0.21-10.245.0.40]
    cloud_properties:
      name: bosh-net

compilation:
  workers: 2
  reuse_compilation_vms: true
  vm_type: default
  network: default
  az: z1
EOF

# Upload cloud config
bosh update-cloud-config cloud-config.yml

# Upload the release
bosh upload-release https://bosh.io/d/github.com/cloudfoundry-community/prometheus-boshrelease

# Get release manifest
cd ~/workspace
git clone https://github.com/bosh-prometheus/prometheus-boshrelease.git
ls prometheus-boshrelease/manifests
