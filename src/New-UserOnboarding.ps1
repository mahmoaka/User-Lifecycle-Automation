# Simple User Onboarding Script using Microsoft Graph PowerShell
# Creates a new user, assign a license, adds groups, and exports a summary

# 1. Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All","Directory.ReadWrite.All"
Select-MgProfile -Name "beta"

# 2. Collect basic user information
$DisplayName = Read-Host "Enter Display Name"
$UserPrincipalName = Read-Host "Enter User Principal Name (e.g. john.doe@tenant.onmicrosoft.com)"
$Department = Read-Host "Enter Department"
$JobTitle = Read-Host "Enter Job Title"

# 3. Temporary Password
$Temppassword = "TemP@ssw0rd123!"

# 4. Create the user
$UserParams = @{
    DisplayName = $DisplayName
    UserPrincipalName = $UserPrincipalName
    AccountEnabled = $true
    Department = $Department
    JobTitle = $JobTitle
    PasswordProfile = @{
        Password = $Temppassword
        ForceChangePasswordNextSignIn = $true
    } 
}
$User = New-MgUser @UserParams
Write-Host "User created: $($User.Id)" -ForegroundColor Green

# Assign M365 License
$SkuId = "Enter your SKUID HERE"

$LicenseParams = @{
    AddLicenses = @(
        @{
            SkuId = $SkuId
        }
    )
    RemoveLicenses = @()
}
Set-MgUserLicense -UserId $User.Id -BodyParameter $LicenseParams
Write-Host "License Assigned" -ForegroundColor Green

# 6. Add user to groups
$GroupIds = @(
    "GROUP-ID-1",
    "GROUP-ID-2"
)
foreach ($GroupId in $GroupIds){
    New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $User.Id
    Write-Host "Added to Group: $GroupId"
}

#7. Export onboarding summary
$Summary = [PSCustomObject]@{
    DisplayName = $DisplayName
    UserPrincipalName = $UserPrincipalName
    Department = $Department
    JobTitle = $JobTitle
    TemporaryPassword = $Temppassword
    CreatedOn = (Get-Date)
}

$Summary | Export-Csv -path "./Onboarding-Summary.csv" -NoTypeInformation
Write-Host "Onboarding Summary exported."