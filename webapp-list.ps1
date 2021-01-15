<#
Author: Brandon Wong
Description: This script will allow all app services in a tenant to be queried against for ID, Name, RG, and HostNames to a CSV
#>

[CmdletBinding()]
param(
  $tenant
)

# Create CSV Headers
Add-Content -Path ./report.csv -Value "NAME,ID,RESOURCEGROUP,ENABLEDHOSTNAMES"

$subs = @()
$subs = az account list --query "[?tenantId=='$tenant']" | ConvertFrom-Json

foreach ($sub in $subs) {
    az account set --subscription $sub.id
    $apps = az webapp list --query '[].{id:id, name:name, resourceGroup:resourceGroup, enabledHostNames:enabledHostNames}' --output json | ConvertFrom-Json
    foreach ($app in $apps){
        Add-Content -Path ./report.csv -Value "$($app.name),$($app.id),$($app.resourcegroup),$($app.enabledHostNames)"
    } 
}
