<#
Author: Brandon Wong

Description: Purpose of this script is to count the number of Virtual Machines with a certain tag
that is passed from an argument

Requirements: Two Arguments
                    [1] = Subscription ID
                    [2] = Tag to Query for EX: Alwaysrunning or AlwaysRunning=false

            Example Query: .\Count-tag.ps1 <subcription id> AlwaysRunning=true
#>

[CmdletBinding()]
param(
  $subscriptionId,
  $tag = 'AlwaysRunning=true'
)

# Set the correct Subscription ID
az account set --subscription $subscriptionId

# Query for results of the given tag for ONLY Virtual Machines
$results = $null
@($results)
$results = az resource list --tag "$tag" --query "[?type=='Microsoft.Compute/virtualMachines']" | ConvertFrom-Json
$count = $results.count

# Print out results
Write-host " You have " -f yellow -nonewline; Write-host "$count " -f green -nonewline; Write-host "Virtual Machines with tag" -f yellow -nonewline; Write-host " $tag ! " -Foregroundcolor green
