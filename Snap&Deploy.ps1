################################################################################
# Author: Brandon Wong                                                         #
#                                                                              #
# Purpose: To create a snapshot of a VM and deploy the snapshot to a fresh VM. #  
#                                                                              #
################################################################################

<# 
Statically set values here if you dont want to be prompted, replace null with actual values. Fill out these variables to get the Disk ID and to create a Snapshot. After you will 
create a VM from the snapshot that was taken. You will need to know the Resource group and the VMName of the VM to Snapshot, as well as additonal info for where to build the VM. 

** Make sure the VM to snapshot is "Deallocated" and "Shut down" ! A snapshot cannot be created properly if the VM is in a running state. 
#>

# **** FILL ME **** Variables for VM to take the snapshot of ****
$Resourcegroup = '$null'
$VMName = '$null'
#What RG to store the Snapshot in
$SnapShotRG = '$null'
### FILL OUT THE ($null) ABOVE ###


$SnapshotName = $(az vm show --resource-group $Resourcegroup --name $VMName --query "storageProfile.osDisk.name" -o tsv)
$osDiskId = $(az vm show --resource-group $Resourcegroup --name $VMName --query "storageProfile.osDisk.managedDisk.id" -o tsv)

# Checking for disk powerstate
$vminfo = az vm show -d --resource-group $Resourcegroup --name $VMName | ConvertFrom-Json
$vmstatus = $vminfo.PowerState

if ($vmstatus -eq "VM deallocated") {
    Write-Host " Your VM is deallocated! Great lets take a snapshot! " -ForegroundColor Yellow
}
else 
{
    Write-Host "Please deallocate your machine so we can take a snapshot! Exiting!!" -ForegroundColor Red
    Exit
}

# Create the Snapshot! 
az snapshot create -g $SnapShotRG --source "$osDiskId" --name "${SnapshotName}-snap" | Out-Null
Write-Host "Your Snapshot has been created as <$SnapshotName-snap> ! " -ForegroundColor Yellow


<#
The following will help define where to build and deploy the VM from the specified snapshot

**** FILL Out $null **** to build out new VM with newly created Snapshot
Provide the subscription Id of the subscription where you want to create Managed Disks 
#>
$newvmsubscriptionId = '$null'

#Provide the name of your resource group
$newvmresourceGroupName = '$null'

#Provide the size of the disks in GB. It should be greater than the VHD file size.
$newvmdiskSize = '$null'

#Provide the storage type for Managed Disk. Premium_LRS or Standard_LRS.
$newvmstorageType = '$null'

#Provide the OS type (linux or windows)
$newvmosType = '$null'

#Provide the name of the snapshot that will be used to create Managed Disks. Can leave as is. 
$snapshotfinalname = "${SnapshotName}-snap"

#Provide the name of the Managed Disk
$newvmosDiskName = "${VMName}-snapshot_disk"

#Provide the name of the virtual machine
$newvmvirtualMachineName = "${VMName}-snapshot_vm"

#Set the context to the subscription Id where Managed Disk will be created
az account set --subscription $newvmsubscriptionId

#Get the snapshot Id 
$snapshotId = $(az snapshot show --name $snapshotfinalname --resource-group $Resourcegroup --query [id] -o tsv)

#Create a new Managed Disks using the snapshot Id
az disk create --resource-group $newvmresourceGroupName --name $newvmosDiskName --sku $newvmstorageType --size-gb $newvmdiskSize --source $snapshotId | Out-Null
Write-Host "New Disk created! " -ForegroundColor Yellow

#Create VM by attaching created managed disks as OS
az vm create --name $newvmvirtualMachineName --resource-group $newvmresourceGroupName --attach-os-disk $newvmosDiskName --os-type $newvmosType | Out-Null
Write-Host "New VM created! " -ForegroundColor Yellow

$snapvminfo = az vm show -d --resource-group $newvmresourceGroupName --name $newvmvirtualMachineName | ConvertFrom-Json
$snapvmpip = $snapvminfo.publicIps

Write-Host "Access your VM Here:$snapvmpip " -ForegroundColor Green
