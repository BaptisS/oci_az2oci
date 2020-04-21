# Azure to OCI VM Migration #
_An easy way to move your Compute workload from Azure to OCI _ 


You can natively import your own Custom images in OCI using QCOW2 or VMDK disk file format.
The following document will guide you trough the steps needed to import an Azure VM Instance into OCI.   





***Prerequisites:***

- An OCI user account with enough permissions to import custom images and create instances. 
    - User OCID (ie. ocid1.user.oc1..aaaaaaaxx )
    - API key pair. (https://docs.cloud.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm)
    -	OCI API Key Fingerprint. (ie.  c5:12:34:45:67:89:a1:cd:ef:12:34:56:78:90:e0 ) 


- SSH key pair. (https://docs.cloud.oracle.com/en-us/iaas/Content/GSG/Tasks/creatingkeys.htm) 
- An Object Storage bucket 
- One Virtual Cloud Network and one Public Subnet already created. 
    -	Target Subnet OCID (ie. ocid1.subnet.oc1.eu-frankfurt-1.aaaaaaaaqviqixxx ) 


-	Target Tenancy OCID (ie. ocid1.tenancy.oc1..aaaaaaaa3ed2)
-	Target Region Name (ie. me-jeddah-1)
-	Target Compartment OCID (ie. ocid1.compartment.oc1..aaaaaaaa2xb )
-	Target Availability Domain Name. (ie. XYZ:ME-JEDDAH-1-AD-1)


-	VHD URL (ie. https://md-ssd-xyzxyz.blob.core.windows.net/xyzxyzxyz/abcd?sv=2020-04-06jhdjlmk )

 
### 1- Prepare the CloudInit script for the migration server(AZ2OCIVM).

 1.1-	Download the following CloudInit script : https://raw.githubusercontent.com/BaptisS/oci_az2oci/master/AZ2OCI_CloudInit.txt 
 
 1.2-   Locate the section '[DEFAULT]' and update the variables with your own values : 
 
    -    User OCID 
    -    API key fingerprint 
    -    Tenancy OCID 
    -    Region Name 
    -    Compartment OCID 
 
 1.3-   Locate the API private key section ('-----BEGIN RSA PRIVATE KEY-----') and update the content with your own private key content. 
 
 1.4-   Save the updated CloudInit script.  
 
### 2- Prepare the Migration script (az2oci.sh).

 1.1-	Download the following bash script : https://raw.githubusercontent.com/BaptisS/oci_az2oci/master/AZ2OCI_v1.0.sh
 
 1.2-   Locate the section 'Variables' and update the following variables with your own values : 
 
    -    Compartment OCID (Target Compartment for the migrated VM Instance)  
    -    VHD_URL (Source VHD export URL)  
    -    IMG_NAME (Name for the target Custom Image & Instance) 
    -    OBJST_NS (Object Storage Namespace) 
    -    OBJST_BN (Object Storage Bucket Name) 
    -    IMG_LM (Target Image Launch Mode - EMULATED / PARAVIRTUALIZED / NATIVE / CUSTOM)
    -    VM_AD (Target VM's Availability Domain) 
    -    VM_SP (Target VM Shape) 
    -    VM_SN (Target Subnet OCID) 
 
 1.3-   Save the updated bash script.  

### 3- Provision the Migration server (AZ2OCIVM).    

 3.1-	Sign-in to the OCI web console with your OCI user account. 
 
 3.2-	Go to the OCI menu -> Compute -> Instances section . 
 
 3.3-   Click on 'Create Instance'.
 
 3.3.1-   Provide a Name such as 'AZ2OCIVM'.
 
 3.3.2-   Keep the default image selected (Oracle Linux 7.x).
 
 3.3.3-   Select the desired Availability Domain for the Migration VM. 
 
 3.3.4-   Choose a Shape based on your requirements. (+2.2 recommended)
 
 3.3.5-   Select destination Compartment, VCN and subnet for the Migartion VM. (Must be a Public Subnet)  
 
 3.3.6-   Ensure 'Assign a Public IP Address' is selected.
 
 3.3.7-   Check 'Specify a Custom Boot Volume Size' and define the desired size. (Custom Boot volume size should be equal to at least x2 times the size of the VHD file(s) you plan to import simultaneously. Currently OCI Custom Image import process is limited to two concurrent import tasks) 
 
 3.3.8-   Provide SSH Public Key for the Migration VM. 
 
 3.3.9-   Click the 'Show Advanced Options' link. 
 
 3.3.10-  Ensure proper Compartment is selected. 

 3.3.11-  Select/Paste the updated Cloud Init Script containing your variables. 
 
 3.3.12-  Click 'Create Button' to start provisioning the Migration VM. (End-to-end deployment including post-provisioning tasks should take approx. 7/8 min)


### 4- Execute the migration script (az2oci.sh).   

 4.1-	Once the migration server (AZ2OCIVM) has been provisionned successfully, take notes of it's public IP address and open an SSH session with your preferred SSH client.
 
 4.2-   Switch to the root user context 
        sudo -s
 
 4.3-   Copy the bash script (updated in Step 2) to the Migration VM. 
 
 4.4-   Update the script file permission to allow its execution : 
        chmod +x az2oci.sh
 
 4.5-   Execute the script : 
        ./az2oci.sh
 
 4.6-   Wait for the script execution to complete. 
 
 4.7-   Open the OCI web console and Navigate to the OCI -> Compute -> Instances section. 
 
 4.8-   Wait for the migrated VM to be in Available state then open a remote session using your preferred tools. 
 
 

![PMScreens](/img/01.jpg)

