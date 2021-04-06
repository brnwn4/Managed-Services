<#
.Author - Brandon Wong

.Purpose - This Runbook is desgined to create a snapshot of DISKS marked with Snapshot=True

.Requirements - This Runbook will use the RunAs account if provisioned with an Automation Account, and will use need to use the AZ.Accounts an AZ.Compute Modules, which will be imported.
                Module which should come out of the gate.

                Disks to backup will require a Key:Value of Snapshot=True in order to be backed up by this runbook.

To Modify the retention of the old snapshots, just modify the $retention variable. "-7" will keep snapshots for a week (7 days).

#>
param(
    [Parameter(Mandatory=$false)]
    [String]$retention="-7"
)

#Import AZ ps Modules
Import-Module Az.Accounts
Import-Module Az.Compute

#Login
$connectionName = "AzureRunAsConnection"
try {
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Connect-AzAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection) {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
#Create snapshots from Tagged Disks
$disks=Get-AzDisk | Select Name,Tags,Id,Location,ResourceGroupName 
foreach($disk in $disks) { 
    foreach($tag in $disk.Tags) {
        if($tag.Snapshot -eq 'True') {
        $snapshotconfig = New-AzSnapshotConfig -SourceUri $disk.Id -CreateOption Copy -Location $disk.Location -AccountType Premium_LRS
        $SnapshotName=$disk.Name+"_"+(Get-Date -Format "yyyy-MM-dd")+"_Fromtag"
        New-AzSnapshot -Snapshot $snapshotconfig -SnapshotName $SnapshotName -ResourceGroupName $disk.ResourceGroupName
        }
    }
}

#Remove Old Snapshots
Get-AzSnapshot | select Name, ResourceGroupName, TimeCreated , DiskSizeGB | Where-Object {($_.TimeCreated -lt [datetime]::UtcNow.AddDays($retention) -and $_.Name -cLike "*Fromtag")} | remove-azsnapshot -force
