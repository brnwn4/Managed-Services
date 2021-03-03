<#

.Author : Brandon Wong

.Purpose : This script will go through all subs and export a csv of Auto shut down status of all VMs 

#>


$reportPath = ".\Autoshutdown_output.csv"
function UpdateCSV($item) {
    Add-Content -Path $reportPath -Value "$($item.subscription_name),$($item.vm_name),$($item.status),$($item.timezoneid),$($item.dailyRecurrence)"
}

$subs = @("")

$allvms = $null

foreach ($sub in $subs) {
    set-azcontext -Subscription $sub
    $allvms = Get-AzVM -Status
    $subinfo = get-azsubscription -subscriptionname $sub
    foreach ($vm in $allvms) {
        Write-Host "step 1 for $($vm.name)"
        # $targetResourceId = (Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name).Id
        # $shutdownInformation = (Get-AzResource -ResourceGroupName $vm.ResourceGroupName -ResourceType Microsoft.DevTestLab/schedules -Expandproperties).Properties
        $info = (Get-AzResource -ResourceId /subscriptions/$($subinfo.id)/resourceGroups/$($vm.resourcegroupname)/providers/microsoft.devtestlab/schedules/shutdown-computevm-$($vm.name) -ExpandProperties -ErrorAction SilentlyContinue -errorvariable ext1err).Properties
        if (!$ext1err) {
            Write-Host "Step 2 for $($vm.name)"
            UpdateCSV -item @{
                "subscription_name" = $sub
                "vm_name"           = $vm.Name
                "Status"            = $info.status
                "timezoneid"        = $info.timezoneid
                "dailyRecurrence"   = $info.dailyRecurrence.time
            }
        }
        elseif ($info -eq $null) {
            Write-Host "VM $($vm.name) doest have Autoshutdown configured"
            UpdateCSV -item @{
                "subscription_name" = $sub
                "vm_name"           = $vm.Name
                "Status"            = "Disabled"
                "timezoneid"        = "NA"
                "dailyRecurrence"   = "NA"
            }
        }
        else {
            write-host "$($vm.name) doesnt have error or autoshutdown"
        }
    }
}
