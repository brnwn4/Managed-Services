<#
.Author : Brandon Wong

.Purpose: This script will go through all subscriptions and query for the extensions related to log analytics. If the extension is present
          it will go through and match the workspace id to the list of all workspaces in the subscription. Not that this will not reflect accurate data
          if the VM is connected to a log analytics workspace that IS NOT located in the same subscription.  



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
  Add-Content -Path $reportPath -Value "$($item.subscription_name),$($item.vm_name),$($item.LA_Workspace)"
  }

$subs = @()

# Loop through each sub and output the data to csv
foreach ($sub in $subs){
  set-azcontext -subscription $sub
  $all_workspace = Get-AzOperationalInsightsWorkspace
  $windows_vms = Get-AzVM | Where-Object {$_.StorageProfile.OSDisk.OSType -eq "Windows"}
  $linux_vms = Get-AzVM | Where-Object {$_.StorageProfile.OSDisk.OSType -eq "Linux"}
    foreach ($vm in $windows_vms){
        $windows_query = $null
        $windows_query = Get-AzVMExtension -ResourceGroupName $vm.resourcegroupname -VMName $vm.name -Name $1_extension_name -erroraction 0
          if ($windows_query -eq $null) {
            $windows_query = Get-AzVMExtension -ResourceGroupName $vm.resourcegroupname -VMName $vm.name -Name $2_extension_name -erroraction 0
            if ($windows_query -eq $null) {
                $errormessage = "The VM: $($vm.name) does not have the agent installed, and is NOT CONNECTED"
                Write-Output "$errormessage"
                UpdateCSV -item @{
                  "subscription_name" = $sub
                  "vm_name" = $($vm.name)
                  "LA_Workspace" = "Agent not detected"
                  }
            }
        }
      foreach ($item in $windows_query) {
        $windows_workspace_id = ($item.PublicSettings | ConvertFrom-Json).workspaceId
        foreach ($w in $all_workspace) {
            if($w.CustomerId.Guid -eq $windows_workspace_id){ 
                #here, print the vm and it's related log analytics workspace
                Write-Output "the VM: $($vm.name) writes log to Log Analytics workspace named: $($w.name)"
                UpdateCSV -item @{
                    "subscription_name" = $sub
                    "vm_name" = $($vm.name)
                    "LA_Workspace" = $($w.name)
                    }
                }
            }
        }
    }
      foreach ($vm in $linux_vms){
        $linux_query = $null
        $linux_query = Get-AzVMExtension -ResourceGroupName $vm.resourcegroupname -VMName $vm.name -Name $2_extension_name -erroraction 0
          if ($linux_query -eq $null) {
            $errormessage = "The VM: $($vm.name) does not have the agent installed, and is NOT CONNECTED"
            Write-Output "$errormessage"
            UpdateCSV -item @{
              "subscription_name" = $sub
              "vm_name" = $($vm.name)
              "LA_Workspace" = "Agent not detected"
              }
            }
        foreach ($item in $linux_query) {
          $linux_workspace_id = ($item.PublicSettings | ConvertFrom-Json).workspaceId
              foreach ($w in $all_workspace) {
                  if($w.CustomerId.Guid -eq $linux_workspace_id){ 
                  #here, print the vm and it's related log analytics workspace
                  Write-Output "the VM: $($vm.name) writes log to Log Analytics workspace named: $($w.name)"
                  UpdateCSV -item @{
                      "subscription_name" = $sub
                      "vm_name" = $($vm.name)
                      "LA_Workspace" = $($w.name)
                      }
                  }
              }
          }
      }
  }
