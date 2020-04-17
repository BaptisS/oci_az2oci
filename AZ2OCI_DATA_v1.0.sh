#!/bin/sh
#sudo -s

#Variables
export comp_ID=ocid1.compartment.oc1..aaaaaaaa2
export vhd_URL="'https://'"
export img_NAME=UBNVM01_DATA
export objst_NS=
export objst_BN=
export img_LM=EMULATED
export vm_AD=XXXX:EU-FRANKFURT-1-AD-1
export vm_SP=VM.Standard2.1
export vm_SN=ocid1.subnet.oc1.eu-frankfurt-1.aaaaaaaa
export target_vm_name=UBNVM01
export bv_data_attype=iscsi
#emulated, iscsi, paravirtualized, service_determined

#

#Download VHD file
echo "Downloading VHD file"
curtime=$(date)
echo $curtime
 lftp -e "pget -n 50 -c ${vhd_URL} -o ${img_NAME}.vhd; exit"

#Convert VHD File
echo "Converting VHD file to VMDK format"
curtime=$(date)
echo $curtime

vboxmanage  clonehd $img_NAME.vhd $img_NAME.vmdk --format VMDK

#Upload VMDK file
echo "Uploading VMDK file to OCI Object Storage"
curtime=$(date)
echo $curtime

/root/bin/oci os object put -ns $objst_NS -bn $objst_BN --file $img_NAME.vmdk --part-size 100 --parallel-upload-count 32

#Import Custom Image
echo "Importing OCI Custom Image from Object Storage file"
echo "Please be patient as it can take +-10min to complete."
curtime=$(date)
echo $curtime

export custom_img=$(/root/bin/oci compute image import from-object -ns $objst_NS -bn $objst_BN --name $img_NAME.vmdk -c $comp_ID --display-name $img_NAME --launch-mode $img_LM --source-image-type VMDK)

export custom_img_id=$(echo $custom_img | jq -r '.data.id')

#Check Custom Image Import status

export custom_img_info=$(/root/bin/oci compute image get --image-id $custom_img_id)
export custom_img_statref=$(echo $custom_img_info | jq '.data."lifecycle-state"')

custom_img_status=$custom_img_statref

while [[ $custom_img_status = $custom_img_statref ]]
do
export custom_img_info=$(/root/bin/oci compute image get --image-id $custom_img_id)
export custom_img_status=$(echo $custom_img_info | jq '.data."lifecycle-state"')
#echo "Custom Image Import in Progress"
#echo $custom_img_status
sleep 5
done

echo "OCI Custom Image Import completed"
#echo $custom_img_status


#Launch Instance from Image
echo "Provisioning VM Instance from Custom Image"
curtime=$(date)
echo $curtime

export new_instance=$(/root/bin/oci compute instance launch --availability-domain $vm_AD --compartment-id $comp_ID --shape $vm_SP --display-name $img_NAME --subnet-id $vm_SN --image-id $custom_img_id)

export new_instance_id=$(echo $new_instance | jq -r '.data.id')

export new_instance_info=$(/root/bin/oci compute instance get --instance-id $new_instance_id)
export new_instance_statref=$(echo $new_instance_info | jq '.data."lifecycle-state"')

new_instance_status=$new_instance_statref

while [[ $new_instance_status = $new_instance_statref ]]
do
export new_instance_info=$(/root/bin/oci compute instance get --instance-id $new_instance_id)
export new_instance_status=$(echo $new_instance_info | jq '.data."lifecycle-state"')
#echo "Custom Image Import in Progress"
#echo $custom_img_status
sleep 5
done

echo "OCI Instance Provisionning completed"

#Delete Instance and keep boot volume
echo "Terminating VM Instance"
curtime=$(date)
echo $curtime


/root/bin/oci compute instance terminate --instance-id $new_instance_id --preserve-boot-volume true --force

export new_instance_info=$(/root/bin/oci compute instance get --instance-id $new_instance_id)
export new_instance_statref=$(echo $new_instance_info | jq '.data."lifecycle-state"')

new_instance_status=$new_instance_statref

while [[ $new_instance_status = $new_instance_statref ]]
do
export new_instance_info=$(/root/bin/oci compute instance get --instance-id $new_instance_id)
export new_instance_status=$(echo $new_instance_info | jq '.data."lifecycle-state"')
#echo "Custom Image Import in Progress"
#echo $custom_img_status
sleep 5
done
echo "VM Instance Terminated"


## BV 
export bv_name=$img_NAME\ \(Boot\ Volume\)
export bv_id=$(/root/bin/oci bv boot-volume list --compartment-id $comp_ID --availability-domain $vm_AD | jq --arg bv_nm "$bv_name" -r '.data[] | select( ."display-name" == $bv_nm ).id')
export target_vm_id=$(/root/bin/oci compute instance list --compartment-id $comp_ID --availability-domain $vm_AD | jq --arg target_vm_nm "$target_vm_name" -r '.data[] | select( ."display-name" == $target_vm_nm ).id')

#export target_instance_info=$(/root/bin/oci compute instance get --instance-id $target_vm)
#export target_instance_statref=$(echo $new_instance_info | jq '.data."lifecycle-state"')

export target_instance_info=$(/root/bin/oci compute instance get --instance-id $target_vm_id)
export target_instance_statref=RUNNING

export target_instance_status=init

while [[ $target_instance_status -ne $target_instance_statref ]]
do
export target_instance_info=$(/root/bin/oci compute instance get --instance-id $target_vm_id)
export target_instance_status=$(echo $target_instance_info | jq '.data."lifecycle-state"')
#echo "Target VM Instance not AVAILABLE"
#echo $target_instance_status
sleep 5
done
echo "Target VM Instance AVAILABLE"
echo "Attaching DATA Disk."


export target_disk_attach=$(/root/bin/oci compute volume-attachment attach --instance-id $target_vm_id --type $bv_data_attype --volume-id $bv_id --display-name $img_NAME)
echo $target_disk_attach
