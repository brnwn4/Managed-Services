<#
Author: Brandon Wong

Purpose: This script will query a local DNS zone A records against a private DNS zone in azure. If the IP is different locally, it will match what is in Azure's Private DNS

Requirements: You will need to know the Local and Azure Zone Names, and the Azure Resource Group housing the Private DNS Zone

Date: Working on 6/28 


#>

# Local
$localzone = "test.com"
$LocalRecords = Get-DnsServerResourceRecord -ZoneName $localzone | Where-Object -property RecordType -eq "A"

# Az
$AzZone = "test.com"
$AzRG = "testing-rg"
$AzRecords = Get-AzPrivateDnsRecordSet -ResourceGroupName $AzRG -ZoneName $AzZone| Where-Object -property RecordType -eq "A"

foreach ($record in $LocalRecords) {
    if ($AzRecords.Name -contains $record.HostName ) {
        $localrecord = $LocalRecords | Where-Object -Property HostName -eq $record.HostName
        $localip = $localrecord.recorddata.ipv4address.ipaddresstostring
        $azref = $AzRecords | Where-Object -Property Name -eq $record.HostName
        $azip = $azref.records.ipv4address
        if ($localip -eq $azip) {
            Write-Host "The record IPs match for ""$($record.HostName)"".. Moving on"
        }
        if ($localip -ne $azip) {
            Write-Host "The Record IPs do not match... Lets update our Local DNS for ""$($record.HostName)"" and change the IP from ""$localip"" to ""$azip"""
            $oldobj = get-dnsserverresourcerecord -Name $record.HostName -ZoneName $localzone -RRType "A"
            $newobj = get-dnsserverresourcerecord -Name $record.HostName -ZoneName $localzone -RRType "A"
            $updateip = $azip
            $newobj.recorddata.ipv4address=[System.Net.IPAddress]::parse($updateip)
            Set-dnsserverresourcerecord -newinputobject $newobj -OldInputObject $oldobj -zonename $localzone -passthru
        }
    }
}
