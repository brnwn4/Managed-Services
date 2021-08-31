<#
Author : Brandon W

Purpose: This will loop through all subscriptions in $subs and if a resource doesnt have all of the five tags ("ApplicationOwner,ApplicationCategory,CapitalProject,
CapitalProjectName,BuildDate"), it will automatically tag it with default values. 

Upon completion an output csv stored in $path will be created depicting how many per tag were updated. So if Application owner has 5, that means 5
resources needed to have that tag applied, and so on..

#>
$path = "./tag_change_count.csv"
Add-Content -Path $path -Value "ApplicationOwner,ApplicationCategory,CapitalProject,CapitalProjectName,BuildDate"
function CreateReportItem($item) {
    Add-Content -Path $path -Value "$($item.ApplicationOwner),$($item.ApplicationCategory),$($item.CapitalProject),$($item.CapitalProjectName),$($item.BuildDate)"
    }

$subs = @("Eversource-IT-Dev-01",
    "Eversource-IT-Prd-01",
    "Eversource-IT-Hub",
    "Eversource-IT-Tst-01")

$ApplicationOwner_Count = 0
$ApplicationCategory_Count = 0
$CapitalProject_Count = 0
$CapitalProjectName_Count = 0
$BuildDate_Count = 0

foreach ($sub in $subs) {
    set-azcontext -Subscription $sub
    $resources = Get-AzResource
        foreach ($resource in $resources) {
            if ($resource.tags.keys -notcontains "ApplicationOwner") {
                $tags = (Get-AzResource -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name).Tags
                $tags += @{ApplicationOwner="unknown@eversource.com"}
                Set-AzResource -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name -ResourceType $resource.ResourceType -Tag $tags -Force
                $ApplicationOwner_Count +=1 
            }
            if ($resource.tags.keys -notcontains "ApplicationCategory") {
                $tags = (Get-AzResource -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name).Tags
                $tags += @{ApplicationCategory="4"}
                Set-AzResource -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name -ResourceType $resource.ResourceType -Tag $tags -Force
                $ApplicationCategory_Count += 1
            }
            if ($resource.tags.keys -notcontains "CapitalProject") {
                $tags = (Get-AzResource -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name).Tags
                $tags += @{CapitalProject="N"}
                Set-AzResource -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name -ResourceType $resource.ResourceType -Tag $tags -Force
                $CapitalProject_Count += 1
            }
            if ($resource.tags.keys -notcontains "CapitalProjectName") {
                $tags = (Get-AzResource -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name).Tags
                $tags += @{CapitalProjectName="None"}
                Set-AzResource -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name -ResourceType $resource.ResourceType -Tag $tags -Force
                $CapitalProjectName_Count += 1
            }
            if ($resource.tags.keys -notcontains "BuildDate") {
                $tags = (Get-AzResource -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name).Tags
                $tags += @{BuildDate="99/99/99"}
                Set-AzResource -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name -ResourceType $resource.ResourceType -Tag $tags -Force
                $BuildDate_Count += 1
            }
        }
}

CreateReportItem -item @{
    "ApplicationOwner" = $ApplicationOwner_Count
    "ApplicationCategory" = $ApplicationCategory_Count
    "CapitalProject" = $CapitalProject_Count
    "CapitalProjectName" = $CapitalProjectName_Count
    "BuildDate" = $BuildDate_Count
}
