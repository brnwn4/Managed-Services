<#
Author: Brandon W
Date: 11/4/2021
Purpose: This will go through for all VMs in listed subscriptions and output their Private IPs into a csv.
#>

$subs = @(
)
$reportPath = ".\ip_output.csv"
Add-Content -Path $reportPath -Value "SubscriptionID,ResourceGroupName,VMName,PrivateIP"

function UpdateCSV($item) {
    Add-Content -Path $reportPath -Value "$($item.SubscriptionID),$($item.ResourceGroupName),$($item.VMName),$($item.PrivateIP)"
}
foreach ($sub in $subs) {
    $vms = az vm list-ip-addresses --subscription=$sub | convertfrom-json
    foreach ($vm in $vms) {
        UpdateCSV -item @{
            "SubscriptionID"= $sub
            "ResourceGroupName" = "$($vm.virtualmachine.resourceGroup)"
            "VMName" = "$($vm.virtualmachine.name )"
            "PrivateIP" = "$($vm.virtualmachine.network.privateIpAddresses)"
        }
    }
}
