<#
.Author - Brandon Wong

.Purpose - This Runbook is desgined to create a snapshot of DISKS marked with Snapshot=True

.Requirements - This Runbook will use the RunAs account if provisioned with an Automation Account, and will use need to use the AzureRM.Compute
                Module which should come out of the gate.

To Modify the retention of the old snapshots, just modify line 41 in: " * Where-Object {($_.TimeCreated -lt [datetime]::UtcNow.AddDays(-14) <-- ) This example keeps snapshots as old as 14 days.

#>

#Login
$connectionName = "AzureRunAsConnection"
try {
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
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
$disks=Get-AzureRmDisk | Select Name,Tags,Id,Location,ResourceGroupName ; 
foreach($disk in $disks) { foreach($tag in $disk.Tags) { if($tag.Snapshot -eq 'True') {$snapshotconfig = New-AzureRmSnapshotConfig -SourceUri $disk.Id -CreateOption Copy -Location $disk.Location -AccountType Premium_LRS;$SnapshotName=$disk.Name+"_"+(Get-Date -Format "yyyy-MM-dd")+"_Fromtag";New-AzureRmSnapshot -Snapshot $snapshotconfig -SnapshotName $SnapshotName -ResourceGroupName $disk.ResourceGroupName }}}

#Remove Old Snapshots
Get-AzureRMSnapshot | select Name, ResourceGroupName, TimeCreated , DiskSizeGB | Where-Object {($_.TimeCreated -lt [datetime]::UtcNow.AddDays(-14) -and $_.Name -cLike "*Fromtag")} | remove-azurermsnapshot -force