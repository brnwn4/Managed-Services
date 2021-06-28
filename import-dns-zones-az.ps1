$logfilelocaiton = "C:\Logs\DNS_to_Azure_Log.txt"
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
 
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Information','Warning','Error')]
        [string]$Severity = 'Information'
    )
 
    [pscustomobject]@{
        Time = (Get-Date -f g)
        Message = $Message
        Severity = $Severity
    } | Export-Csv -Path $logfilelocaiton -Append -NoTypeInformation
 }

# Local
$localzone = "test.com"
$LocalRecords = Get-DnsServerResourceRecord -ZoneName $localzone | Where-Object -property RecordType -eq "A"

# Az
$AzZone = "test.com"
$AzRG = "bwong-testing"
$AzRecords = Get-AzPrivateDnsRecordSet -ResourceGroupName $AzRG -ZoneName $AzZone| Where-Object -property RecordType -eq "A"

foreach ($record in $LocalRecords) {
    if ($AzRecords.Name -contains $record.HostName ) {
        $localrecord = $LocalRecords | Where-Object -Property HostName -eq $record.HostName
        $localip = $localrecord.recorddata.ipv4address.ipaddresstostring
        $azref = $AzRecords | Where-Object -Property Name -eq $record.HostName
        $azip = $azref.records.ipv4address
        if ($localip -eq $azip) {
            Write-Log -Message "The record IPs match for $($record.HostName).. Moving on" -Severity Information
        }
        if ($localip -ne $azip) {
            Write-Log -Message "The Record IPs do not match... Lets update our Local DNS for $($record.HostName) and change the IP from $localip to $azip" -Severity Warning
            $oldobj = get-dnsserverresourcerecord -Name $record.HostName -ZoneName $localzone -RRType "A"
            $newobj = get-dnsserverresourcerecord -Name $record.HostName -ZoneName $localzone -RRType "A"
            $updateip = $azip
            $newobj.recorddata.ipv4address=[System.Net.IPAddress]::parse($updateip)
            Set-dnsserverresourcerecord -newinputobject $newobj -OldInputObject $oldobj -zonename $localzone -passthru
            # az network private-dns record-set a add-record -g $AzRG -z $AzZone -n $record.HostName -a $azip
        }
        if ($localip -eq $null) {
           Write-Log -Message 'There was an error with Grabbing the local IP of the Record... Logging' -Severity Error 
        }
            if ($azip -eq $null) {
           Write-Log -Message 'There was an error with Grabbing the local IP of the Record... Logging' -Severity Error 
        }
    }
}
