# Simple User Offboarding Script using Microsoft Graph PowerShell
# Disables a user, removes licenses, removes group memberships, and exports a summary

# 1. Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All","Directory.ReadWrite.All"
Select-MgProfile -Name "beta"

# 2. Collect user information
$UserPrincipalName = Read-Host "Enter the User Principal Name of the user to offboard"
$User = Get-MgUser -UserId $UserPrincipalName

Write-Host "User Found: $($User.DisplayName)" -Foregroundcolor Green

# 3. Disable the user account
Update-MgUser -UserId $User.Id -AccountEnabled:$false
Write-Host "User Account Disabled." -ForegroundColor Yellow

# 4. Remove all assigned Licenses
$AssignedLicenses = $User.AssignedLicenses.SkuId
$LicenseParams = @{
    AddLicenses = @()
    RemoveLicenses = $AssignedLicenses
}
Set-MgUserLicense -UserId $User.Id -BodyParameter $LicenseParams
Write-Host "All Licenses removed" -ForegroundColor Yellow

# 5. Remove User from all groups
$Groups = Get-MgUserMemberOf -UserId $User.Id

foreach($Group in $Groups) {
    if ($Group.Id) {
        Remove-MgGroupMember -GroupId $Group.Id -MemberId $User.Id
        Write-Host "Removed from group: $($Group.Id)"
    }
}

#6 Export offboarding Summary
$Summary = [PSCustomObject]@{
    DisplayName = $User.DisplayName
    UserPrincipalName = $User.UserPrincipalName
    DisabledOn = (Get-Date)
    LicensesRemoved = $AssignedLicenses -join ", "
    GroupsRemoved = $Groups.Id -join ", "
}

$Summary | Export-Csv -Path "./Offboarding-Summary.csv" -NoTypeInformation
Write-Host "Offboadrding summary exported"