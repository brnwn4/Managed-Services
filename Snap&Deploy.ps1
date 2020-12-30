################################################################################
# Author: Brandon Wong                                                         #
#                                                                              #
# Purpose: To create a snapshot of a VM and deploy the snapshot to a fresh VM. #                                                         #
#                                                                              #
################################################################################

<# 
Statically set values here if you dont want to be prompted, replace null with actual values. Fill out these variables to get the Disk ID and to create a Snapshot. After you will 
create a VM from the snapshot that was take. You will need to know the Resource group and the VMName of the VM to Snapshot, as well as additonal info for where to build the VM. 
#>

# **** Variables to take the snapshot ****
$Resourcegroup = 'bw-test'
$VMName = 'bw-test-vm'
$SnapshotName = $(az vm show --resource-group $Resourcegroup --name $VMName --query "storageProfile.osDisk.name" -o tsv)
$SnapShotRG = 'bw-test'

$osDiskId = $(az vm show --resource-group $Resourcegroup --name $VMName --query "storageProfile.osDisk.managedDisk.id" -o tsv)

# Create the Snapshot! 
az snapshot create -g $SnapShotRG --source "$osDiskId" --name "${SnapshotName}-snap" | Out-Null
Write-Host "Your Snapshot has been created as <$SnapshotName-snap> ! " -ForegroundColor Yellow


<#
The following will help define where to build and deploy the VM from the specified snapshot
#>

# **** Variables to build out new VM with newly created Snapshot ****
#Provide the subscription Id of the subscription where you want to create Managed Disks
$newvmsubscriptionId = '7e948898-d1c0-49c2-8895-94d7d8f8fd36'

#Provide the name of your resource group
$newvmresourceGroupName = 'bw-test'

#Provide the name of the snapshot that will be used to create Managed Disks
$newvmsnapshotName = 'mySnapshotName'

#Provide the name of the Managed Disk
$newvmosDiskName = 'testsnapshotOSdisk'

#Provide the size of the disks in GB. It should be greater than the VHD file size.
$newvmdiskSize = '246'

#Provide the storage type for Managed Disk. Premium_LRS or Standard_LRS.
$newvmstorageType = 'Premium_LRS'

#Provide the OS type
$newvmosType = 'windows'

#Provide the name of the virtual machine
$newvmvirtualMachineName = 'snapshot-test'


#Set the context to the subscription Id where Managed Disk will be created
az account set --subscription $newvmsubscriptionId

#Get the snapshot Id 
$snapshotId = $(az snapshot show --name "${SnapshotName}-snap" --resource-group $Resourcegroup --query [id] -o tsv)

#Create a new Managed Disks using the snapshot Id
az disk create --resource-group $newvmresourceGroupName --name $newvmosDiskName --sku $newvmstorageType --size-gb $newvmdiskSize --source $snapshotId 

#Create VM by attaching created managed disks as OS
az vm create --name $newvmvirtualMachineName --resource-group $newvmresourceGroupName --attach-os-disk $newvmosDiskName --os-type $newvmosType


