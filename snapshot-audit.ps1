<#
.Author - Brandon Wong
.Description - This script will allow all snapshotted disks in a subscription to be queried against for Name, RG, and date/time to a CSV
.Example - .\snapshot-audit.ps1 <subscription_id> | Then the output will be in snapshot-report.csv in the local folder.
#>

[CmdletBinding()]
param(
  $subscription
)

# Create CSV Headers
Add-Content -Path ./snapshot-report.csv -Value "NAME,RG,Date/Time,"


az account set --subscription $subscription
$snapshots = az snapshot list --query '[].{name:name, resourceGroup:resourceGroup, timeCreated:timeCreated}' --output json | ConvertFrom-Json

foreach ($snapshot in $snapshots){
  Add-Content -Path ./snapshot-report.csv -Value "$($snapshot.name),$($snapshot.resourceGroup),$($snapshot.timeCreated)"
} 
