# Select your Subscription
$ResourceGroup = "RG NAME"
$Subscription = "SUB ID"
$Path = "PATH-TO-ZONE-FILES"
 
az account set --subscription $Subscription
 
# Get DNS Files
$DNSFiles = Get-ChildItem -Path $Path | select name, FullName
 
$Count = 1
foreach($file in $DNSFiles) {
    $name = ($file.Name).Substring(0, ($file.Name).Length-4)
 
    Write-Progress -Id 0 -Activity "Prcoessing DNS" -Status "$Count of $($DNSFiles.Count)" -PercentComplete (($Count / $DNSFiles.Count) * 100)

    # Import the DNS zone file
    az network dns zone import -g $ResourceGroup -n $name -f $file.FullName
 
    $Count++
}
