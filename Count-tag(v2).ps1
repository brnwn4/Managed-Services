<#
Author: Brandon Wong

Description: Purpose of this script is to count the number of Virtual Machines with a certain tag
that is passed from an argument

Requirements: Two Arguments
                    [1] = Subscription ID
                    [2] = Tag to Query for EX: Alwaysrunning or AlwaysRunning=false

            Example Query .\Count-tag.ps1 6f882cde-0dd4-4e6d-9e62-09ccc96c786a AlwaysRunning=true
#>

[CmdletBinding()]
param(
  $subscriptionId,
  $tag
)

# Set the correct Subscription ID
az account set --subscription $subscriptionId

##
# Verson 1 of this
##

# # Query for results of the given tag for ONLY Virtual Machines
# $results = $()
# $results = az resource list --tag "$tag" --query "[?type=='Microsoft.Compute/virtualMachines']" | ConvertFrom-Json
# $count = $results.count

# # Print out results
# Write-host " You have " -f yellow -nonewline; Write-host "$count " -f green -nonewline; Write-host "Virtual Machines with tag" -f yellow -nonewline; Write-host " $tag ! " -Foregroundcolor green

### Better Version Below  ##
# set empty arrays to count
$vms = @()
$vmwithtag = @()
$vmwithnotag = @()
$vmwithkey = @()

# Query VMs
$vms = az vm list  | ConvertFrom-Json

# Split the Tag Key and Value 
$splice = $tag.split("=")
#Set the Key to a variable
$key = $splice[0]
#Set the Value as a variable
$value = $splice[1]

# Find out what has the exact tag, has the key, and doesnt match at all
foreach ($vm in $vms) {
  if ($vm.tags.$key -and $vm.tags.$key -eq $value ){
    Write-Host " $($vm.name) has the tag " 
    $vmwithtag = $vmwithtag += $vm
  } elseif ($vm.tags.$key -and $vm.tags.$key -ne $value ) {
    Write-Host " $($vm.name) has the tag key but NOT the value " 
    $vmwithkey = $vmwithkey += $vm
  } else { 
    Write-Host "VM is Missing Tag Compeltely!"
    $vmwithnotag = $vmwithnotag += $vm
  }
}

# Count Results
$count1 = $vmwithtag.Count
$count2 = $vmwithkey.Count
$count3 = $vmwithnotag.Count

# Print Out Results
Write-host " You have " -f yellow -nonewline; Write-host "$count3 " -f green -nonewline; Write-host "Virtual Machines without the Tag entirely" -f yellow
Write-host " You have " -f yellow -nonewline; Write-host "$count2 " -f green -nonewline; Write-host "Virtual Machines with the matching key of" -f yellow -nonewline; Write-host " $key " -Foregroundcolor green -NoNewline; Write-host "But not a matching value of " -f yellow -NoNewline; Write-Host "$value" -f green
Write-host " You have " -f yellow -nonewline; Write-host "$count1 " -f green -nonewline; Write-host "Virtual Machines with the exact tag" -f yellow -nonewline; Write-host " $tag " -Foregroundcolor green
