<#
.Author : Brandon Wong

.Purpose: This script will go through all subscriptions and query for the extensions related to log analytics. If the extension is present
          it will go through and match the workspace id to the list of all workspaces in the subscription. 



#>
###########################################

#for windows vm, the value is fixed as below
$1_extension_name = "MicrosoftMonitoringAgent"

#for Linux vm, the value is fixed as below
$2_extension_name = "OMSExtension"

# Where CSV is saved (file name can be changed here)
$reportPath = ".\LA_output.csv"

# Extension Query
# $windows_query = Get-AzVMExtension -ResourceGroupName $vm.resourcegroup -VMName $vm.name -Name $windows_extension_name
# $linux_query = Get-AzVMExtension -ResourceGroupName $vm.resourcegroup -VMName $vm.name -Name $linux_extension_name

# # Workspace Query
# $windows_workspace_id = ($windows_query.PublicSettings | ConvertFrom-Json).workspaceId
# $linux_workspace_id = ($linux_query.PublicSettings | ConvertFrom-Json).workspaceId

# Function to create csv
function UpdateCSV($item) {
    Add-Content -Path $reportPath -Value "$($item.subscription_name),$($item.vm_name),$($item.LA_Workspace),$($item.Agent_type),$($item.Status)"
}

$subs = @(
    "Eversource-IT-Dev-01",
    "Eversource-IT-Prd-01",
    "Eversource-IT-Hub",
    "Eversource-IT-Tst-01")

# Loop through each sub and output the data to csv
$all_workspaces = @()
# $windows_vms = @()
# $linux_vms = @()


foreach ($sub in $subs) {
    # Get all Workspaces
    set-azcontext -subscription $sub
    $all_workspaces += Get-AzOperationalInsightsWorkspace
}

# c2fd3a29-12f2-4bd2-a073-92b4f8df63fd 214513a0-bf91-44fa-9bfa-c6050950bf7b

# Get all Windows VMs
# $windows_vm = Get-AzVM | Where-Object { $_.StorageProfile.OSDisk.OSType -eq "Windows" }
foreach ($sub in $subs) {
    set-azcontext -subscription $sub
    $vms = Get-AzVM 
    foreach ($vm in $vms) {
        Write-Host "Testing VM $($vm.name)"
        $extension1_query = Get-AzVMExtension -ResourceGroupName $vm.resourcegroupname -VMName $vm.name -Name $1_extension_name -Erroraction SilentlyContinue -errorvariable ext1err
        $extension2_query = Get-AzVMExtension -ResourceGroupName $vm.resourcegroupname -VMName $vm.name -Name $2_extension_name -Erroraction SilentlyContinue -errorvariable ext2err
        if (!$ext1err-AND $ext2err) {
            $workspace = $all_workspaces | Where-Object { $_.CustomerId -eq ($extension1_query.PublicSettings | ConvertFrom-Json).workspaceId }
            Write-Host "Found extension $($1_extension_name) on $($vm.name)"
            UpdateCSV -item @{
                "subscription_name" = (Get-AzContext).Subscription.Name
                "vm_name"           = $($vm.name)
                "LA_Workspace"      = $workspace.Name
                "Agent_type"        = $1_extension_name # ext1 only
                "Status"            = $extension1_query.ProvisioningState
            }
        }
        elseif (!$ext1err -AND !$ext2err) {
            $workspace = $all_workspaces | Where-Object { $_.CustomerId -eq ($extension1_query.PublicSettings | ConvertFrom-Json).workspaceId }
            Write-Host "Found extension $($1_extension_name) and $($2_extension_name) on $($vm.name)"
            UpdateCSV -item @{
                "subscription_name" = (Get-AzContext).Subscription.Name
                "vm_name"           = $($vm.name)
                "LA_Workspace"      = $workspace.Name
                "Agent_type"        = "$($1_extension_name),$($2_extension_name)" # both
                "Status"            = $extension1_query.ProvisioningState
            }
        }
        elseif ($ext1err -and !$ext2err) {
            Write-Host "Found extension $($2_extension_name) on $($vm.name)"
            UpdateCSV -item @{
                "subscription_name" = (Get-AzContext).Subscription.Name
                "vm_name"           = $($vm.name)
                "LA_Workspace"      = $workspace.Name
                "Agent_type"        = $2_extension_name # ext2 only
                "Status"            = $extension2_query.ProvisioningState
            }
        }
        else {
            Write-Host "Did not fine extension.. on $($vm.name)"
            UpdateCSV -item @{
                "subscription_name" = (Get-AzContext).Subscription.Name
                "vm_name"           = $($vm.name)
                "LA_Workspace"      = $null
                "Agent_type"        = "Not_Installed"
                "Status"            = $null
            }
        }
    }
}
