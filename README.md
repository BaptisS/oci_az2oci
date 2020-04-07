# Azure to OCI VM Migration #
_An easy way to move your Compute workload from Azure to OCI _ 


You can natively import your own Custom images in OCI using QCOW2 or VMDK disk file format.
The following document will guide you trough the steps needed to import an Azure VM Instance into OCI.   



> ***Important Note:*** 
> If you are using a Load Balancer in front of your Web Application, Security rules must be applied to your Load Balancer subnet (if using Security Lists) or Load Balancer Network Interfaces (if using network Security Groups).


***Prerequisites:***

- An OCI user account with enough permissions to import custom images and create instances. 
    - User OCID (ie. ocid1.user.oc1..aaaaaaaxx )
    - API key pair. (https://docs.cloud.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm)
    -	OCI API Key Fingerprint. (ie.  c5:12:34:45:67:89:ab:cd:ef:12:34:56:78:90:e0 ) 

- SSH key pair. (https://docs.cloud.oracle.com/en-us/iaas/Content/GSG/Tasks/creatingkeys.htm) 
- An Object Storage bucket 
- One Virtual Cloud Network and one Public Subnet already created. 
    -	Target Subnet OCID (ie. ocid1.subnet.oc1.eu-frankfurt-1.aaaaaaaaqviqixxx ) 

-	Target Tenancy OCID (ie. ocid1.tenancy.oc1..aaaaaaaa3ed2)
-	Target Region Name (ie. me-jeddah-1)
-	Target Compartment OCID (ie. ocid1.compartment.oc1..aaaaaaaa2xb )
-	Target Availability Domain Name. (ie. XYZ:ME-JEDDAH-1-AD-1)

-	VHD URL (ie. https://md-ssd-xyzxyz.blob.core.windows.net/xyzxyzxyz/abcd?sv=2020-04-06jhdjlmk )

 
 
### 1- Create a New (empty) Security List.    

 1.1-	Sign-in to the OCI web console with your OCI user account. 



![PMScreens](/img/01.jpg)

1.4-	Click on the ***‘Create Security List’*** button. 

![PMScreens](/img/02.jpg)

1.5-	Provide a meaningful name for this new security list. (Ie. ‘OCIWAF-SL’)

