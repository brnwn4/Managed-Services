$usercontext = az account show | convertfrom-json
$accinfo = ""
if ($usercontext.user.type -eq "user") {
    $accinfo = az ad user list --upn $usercontext.user.name --query "[0].objectId" --output tsv 
}
if ($usercontext.user.type -eq "servicePrincipal") {
    $accinfo = az ad sp list --spn $usercontext.user.name --query "[0].objectId" --output tsv 
}
if ($usercontext.user.type -eq "") {
    write-host "Could not find account info"
    }

# Uncomment this section if running manually
#$subscriptionName = "Eversource-IT-Tst-01"
#$subscriptionId = "dc212303-893e-404d-a787-3a960b14e8bf"
#Select-AzSubscription -Subscription $subscriptionName
$days = 31
$skip = $false
#

# Call in CreateReportItem function
. "./createReportFunction.ps1"

#Get the KeyVaults for current signed in user
$keyvaults = @()
$keyvaults = az keyvault list | ConvertFrom-Json

# Empty objects that will be updated during runtime
$today = Get-Date

#Set Access Policy on KV's
Write-Host "Setting Access Policy" -ForegroundColor Yellow
foreach ($keyvault in $keyvaults){
    az keyvault set-policy --name $keyvault.name --object-id $accinfo --secret-permissions get list --key-permissions get list --certificate-permissions get list | Out-Null
    # Create a report per keyvault
    $expiringCertificates = @()
    $expiringKeys = @()
    $expiringSecrets = @()
    <#
    Check for all ceritificates in the keyvault and report if any will expire in x number of days.
    #>
    Write-Host "Checking for Expired Certs" -ForegroundColor Green
    $certificates = az keyvault certificate list --vault-name $keyvault.name | ConvertFrom-Json
    Foreach ($certificate in $certificates) {
        # Check certificate expiration date
        # $todaysdate = Get-Date -Format "yyyy-mm-ddHH:mm K"
        if([datetime]$certificate.attributes.expires -lt $today.addDays($days)) {
            $expiringCertificates += $certificate
            Write-Host "##[warning] Azure Key Vault Certificate - $($certificate.name) Will expire on $($certificate.attributes.expires)"
            CreateReportItem -item @{
                "subscriptionId"= $subscriptionId
                "subscriptionName" = $subscriptionName
                "impact" = "medium"
                "category" = "Key Vault"
                "recommendation" = "Certificate Expiration Warning - $($certificate.name) will expire on $($certificate.attributes.expires)"
                "resourceGroup" = "$($keyvault.resourceGroup)"
                "resource" = "$($keyvault.name)/$($certificate.name)"
            }
        }
    }

    <#
    Check for all secrets in the keyvault and report if any will expire in x number of days.
    #>
    Write-Host "Checking for Expired Secrets" -ForegroundColor Green
    $secrets = @()
    $secrets = az keyvault secret list --vault-name $keyvault.name | ConvertFrom-Json
    Foreach ($secret in $secrets) {
        # Check secret expiration date
        if([datetime]$secret.attributes.expires -lt $today.addDays($days)) {
            $expiringSecrets += $secret
            Write-Host "##[warning] Azure Key Vault Secret - $($secret.name) Will expire on $($secret.attributes.expires)"
            CreateReportItem -item @{
                "subscriptionId"= $subscriptionId
                "subscriptionName" = $subscriptionName
                "impact" = "medium"
                "category" = "Key Vault"
                "recommendation" = "Secret Expiration Warning - $($secret.name) will expire on $($secret.attributes.expires)"
                "resourceGroup" = "$($keyvault.resourceGroup)"
                "resource" = "$($keyvault.name)/$($secret.name)"
            }
        }
    }

    <#
    Check for all keys in the keyvault and report if any will expire in x number of days.
    #>
    Write-Host "Checking for Expired Keys" -ForegroundColor Green
    $keys = @()
    $keys = az keyvault key list --vault-name $keyvault.name | ConvertFrom-Json
    Foreach ($key in $keys) {
        # Check key expiration date
        if([datetime]$key.attributes.expires -lt $today.addDays($days)) {
            $expiringKeys += $key
            Write-Host "##[warning] Azure Key Vault Key - $($key.name) Will expire on $($key.attributes.expires)"
            CreateReportItem -item @{
                "subscriptionId"= $subscriptionId
                "subscriptionName" = $subscriptionName
                "impact" = "medium"
                "category" = "Key Vault"
                "recommendation" = "Key Expiration Warning - $($key.name) will expire on $($key.attributes.expires)"
                "resourceGroup" = "$($keyvault.resourceGroup)"
                "resource" = "$($keyvault.name)/$($key.name)"
            }
        }
    }
#Removing Access Policy
Write-Host "Removing Access Policy" -ForegroundColor Yellow
    az keyvault delete-policy --name $keyvault.name --object-id $accinfo | Out-Null

}
