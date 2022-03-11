#Connect-AzureAD -TenantId <Tenant_ID>
#Using this old fashin PSv1 connect for listing all AD groups,PS V2 sometimes does not list all Azure AD groups
Connect-MsolService

$admUnits = Get-AzureADMSAdministrativeUnit | Where-Object {$_.DisplayName -like "*AU-Helpdesk"}
foreach ($admUnit in $admUnits) {
    #Get Azure AD IT groups - this means you already have some Azure AD group created before with naming e.g. "Branch-IT-Helpdesk"
    #If no group created just modify line below and uncomment
    #New-AzureADMSGroup -DisplayName "Branch-IT-Helpdesk" -Description "Helpdesk agents for <Branch> users." -MailEnabled $False -MailNickname "BranchHelpdesk" -SecurityEnabled $True -IsAssignableToRole $True
    $unit = $admUnit.DisplayName
    $separator = "-"
    $parts = $unit.split($separator)
    $ADgroup = $parts[0]+"-IT-"+$parts[2]
    #$ITgroup = Get-AzureADGroup | Where-Object {$_.DisplayName -eq $ADgroup} - does not always return all wanted Azure AD groups
    $ADgroup = Get-MsolGroup | Where-Object {$_.DisplayName -eq $ADgroup}

    <# Just for testing with PIM roles directly
    $UArole = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId <tenant_ID> | Where-Object -Property DisplayName -EQ -Value "User Administrator"
    $LArole = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId <tenant_ID> | Where-Object -Property DisplayName -EQ -Value "License Administrator"
    #>

    #Get Azure AD roles 
    $HArole = Get-AzureADDirectoryRole | Where-Object -Property DisplayName -EQ -Value "Helpdesk administrator"
    $AArole = Get-AzureADDirectoryRole | Where-Object -Property DisplayName -EQ -Value "Authentication administrator"
    $roleMember = New-Object -TypeName Microsoft.Open.MSGraph.Model.MsRoleMemberInfo
    $roleMember.Id = $ADgroup.ObjectId

    <#Just for testing with PIM directly
    #Configure schedule
    $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
    $schedule.Type = "Once"
    $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    $schedule.endDateTime = $null
    #Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId "aadRoles" -Schedule $schedule -ResourceId <tenant_ID> -RoleDefinitionId $UArole.Id -SubjectId $roleMember.ObjectId -AssignmentState "Active" -Type "AdminAdd" -Reason "AdvOperations"
    #Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId "aadRoles" -Schedule $schedule -ResourceId <tenant_ID> -RoleDefinitionId $LArole.Id -SubjectId $roleMember.ObjectId -AssignmentState "Active" -Type "AdminAdd" -Reason "AdvOperations"
    #>

    #Assign roles to IT group
    Add-AzureADMSScopedRoleMembership -Id $admUnit.Id -RoleId $HArole.ObjectId -RoleMemberInfo $roleMember
    Add-AzureADMSScopedRoleMembership -Id $admUnit.Id -RoleId $AArole.ObjectId -RoleMemberInfo $roleMember 
}
