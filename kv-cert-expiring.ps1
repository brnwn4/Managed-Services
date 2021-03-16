$subs = @("")

# init permissions report
$reportPath = ".\allSubsAndRGs-keyVaultCerts.csv"
Add-Content -Path $reportPath -Value "SubscriptionName,ResourceGroupName,KeyVault,CertificateName,Created,Enabled,Expires,NotBeforeTime,Updated"

function UpdateCSV($item) {
    Add-Content -Path $reportPath -Value "$($item.SubscriptionName),$($item.ResourceGroupName),$($item.KeyVault),$($item.CertificateName),$($item.Created),$($item.Enabled),$($item.Expires),$($item.NotBeforeTime),$($item.Updated)"
}

$myUserId = ""
$myhomeip = ""
Foreach ($sub in $subs){

    az account set --subscription $sub

    # Get all keyvaults in subscription
    $keyvaults = @()
    $keyvaults = az keyvault list | ConvertFrom-Json
    Foreach($keyvault in $keyvaults) {
        try{
            #assign access policy to read certificates
            az keyvault set-policy --name $keyVault.Name --object-id $myUserId --secret-permissions get list --key-permissions get list --certificate-permissions get list
            ##### Adding the below to add network rule from IP you are querying from
            az keyvault network-rule add --name $keyVault.Name --ip-adress $myhomeip

            $certificates = @()
            $certificates = az keyvault certificate list --vault-name $keyvault.name | ConvertFrom-Json
            Foreach ($certificate in $certificates) {
                Write-Output $certificate
                updateCSV @{
                    "SubscriptionName" = $sub
                    "ResourceGroupName" = $keyVault.ResourceGroup
                    "KeyVault" = $keyVault.Name
                    "CertificateName" = $certificate.Name
                    "Created" = $certificate.attributes.created
                    "Enabled" = $certificate.attributes.enabled
                    "Expires" = $certificate.attributes.expires
                    "NotBeforeTime" = $certificate.attributes.notBefore
                    "Updated" = $certificate.attributes.updated
                    
        
                }
            }
            #remove access policy to read certificates
            az keyvault delete-policy --name $keyVault.Name --object-id $myUserId
            az keyvault network-rule remove --name $keyVault.Name --ip-address $myhomeip
        }catch{
            Write-Output "Unable to obtain secrets list from $($keyvault.name)"
        }
    }
}
