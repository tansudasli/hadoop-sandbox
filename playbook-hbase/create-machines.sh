#!/usr/bin/env bash

source ../.gcp.env
source .env


# STEP: create static-IPs

# creates static-regional IPs, then assigns to compute-engines
# todo: normally only web interface servers need static-IP
serverCount=${#INSTANCE_NAMES[@]}

for i in $(seq 0 1 $(($serverCount-1)))
do

   gcloud compute addresses create ${INSTANCE_NAMES[i]} --project=${PROJECT_ID} --region=${REGION}
done

# STEP: create machines and assign static-IPs, and mount

# deletes data disks! keep in mind 
# creates compute engine w/ N additional-disk in N zone
# devicename is related to mount diskname in cloud-init.yaml!
for i in $(seq 0 1 $(($serverCount-1)))
do

   x="gcloud beta compute --project=${PROJECT_ID} instances create ${INSTANCE_NAMES[i]}"
   x=$x" --zone=${ZONES[i]}"
   x=$x" --address $(gcloud compute addresses describe ${INSTANCE_NAMES[i]} --project=${PROJECT_ID} --region=${REGION} --format='get(address)')"
   x=$x" --machine-type=${MACHINE_TYPES[i]}"
   x=$x" --subnet=default"
   x=$x" --network-tier=PREMIUM"
   x=$x" --maintenance-policy=MIGRATE"
   x=$x" --service-account=${SERVICE_ACCOUNT}"
   x=$x" --scopes=https://www.googleapis.com/auth/cloud-platform"
   x=$x" --tags=${TAGS[i]}"
   x=$x" --labels=${LABELS[i]}"
   x=$x" --image=${IMAGE}"
   x=$x" --image-project=ubuntu-os-cloud"
   x=$x" --boot-disk-size=250GB"
   x=$x" --boot-disk-type=pd-standard"
   x=$x" --boot-disk-device-name=${INSTANCE_NAMES[i]}"
   for j in $(seq 0 1 $(($ADDITIONAL_DISK_COUNT-1)))
   do 
      x=$x" --create-disk=mode=rw,auto-delete=yes,size=250,type=projects/${PROJECT_ID}/zones/${ZONES[i]}/diskTypes/pd-standard,name=${INSTANCE_NAMES[i]}-data-${j},device-name=${ADDITIONAL_DISKS[j]}" 
   done
   x=$x" --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any"
   x=$x" --metadata-from-file user-data=./cloud-init.yaml"
   echo $x | sh

done

echo "configure hdfs, then zookeeper, then hbase! "
echo "always switch to hadoop user (sudo -u hadoop -i), to do configurations"
echo "ssh to master-node then run configure-ssh... file on others"
echo "ssh to znodes then run configure-ssh... files on all"
echo "ssh to hmaster then run configure-ssh... files on others"
