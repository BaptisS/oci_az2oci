#!/bin/sh
#sudo -s

#Variables
export comp_ID=ocid1.compartment.oc1..aaaaa
export vhd_URL="'https://md-ssd-xyzxyz.blob.core.windows.net/xyzxyzxyz/abcd?sv=2017-04-17jhdjlmk'"
export img_NAME=UBNVM02
export objst_NS=oracsmemeaspec
export objst_BN=AZ2OCI
export img_LM=PARAVIRTUALIZED
export vm_AD=QLMB:EU-FRANKFURT-1-AD-1
export vm_SP=VM.Standard2.1
export vm_SN=ocid1.subnet.oc1.eu-frankfurt-1.aaaaaaaaqviqixxxxxx

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

/root/bin/oci compute instance launch --availability-domain $vm_AD --compartment-id $comp_ID --shape $vm_SP --display-name $img_NAME --subnet-id $vm_SN --image-id $custom_img_id
