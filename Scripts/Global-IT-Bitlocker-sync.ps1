# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process | Out-Null

#login to AAD
$context = (Connect-AzAccount -Identity).context
$aadToken = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, "https://graph.windows.net").AccessToken
Connect-AzureAD -AadAccessToken $aadToken -AccountId $context.Account.Id -TenantId $context.tenant.id

#Adds PC admins from their groups to Bitlocker group
$GroupName = "<WANTED GROUPS>"
$Groups = Get-AzureADGroup -All:$true | Where-Object {$_.DisplayName -like $GroupName}
$BitLockerGroup = Get-AzureADGroup -ObjectId <GROUP ID>
foreach ($Group in $Groups) {
    $PCAdmins = Get-AzureADGroupMember -ObjectId $Group.ObjectId
    foreach ($PCAdmin in $PCAdmins) {
        $ExistMembers = Get-AzureADGroupMember -ObjectId $BitLockerGroup.ObjectId
        if ($ExistMembers.ObjectId -notcontains $PCAdmin.ObjectId) {
            Add-AzureADGroupMember -ObjectId $BitLockerGroup.ObjectId -RefObjectId $PCadmin.ObjectId
        }
    }
}    
