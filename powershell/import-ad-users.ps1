<#
.SYNOPSIS
Imports users from a CSV file and creates Active Directory accounts.

.DESCRIPTION
Imports employee data from a CSV file, generates normalized
SAMAccountNames and UPNs, checks for existing accounts and creates
users in a target Organizational Unit.

The script uses a SecureString parameter for the temporary password
and does not store credentials in source code.

.EXAMPLE
$password = Read-Host "Enter temporary password" -AsSecureString
.\import-ad-users.ps1 -CsvPath ".\employees.example.csv" -DefaultPassword $password
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$CsvPath,

    [Parameter(Mandatory = $true)]
    [SecureString]$DefaultPassword,

    [string]$TargetOU = "OU=Users,OU=Stockholm,DC=example,DC=local",

    [string]$UpnSuffix = "example.local"
)

Import-Module ActiveDirectory -ErrorAction Stop

function ConvertTo-SamAccountName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FirstName,

        [Parameter(Mandatory = $true)]
        [string]$LastName
    )

    $sam = "$FirstName.$LastName".ToLowerInvariant()
    $sam = $sam.Replace("å", "a").Replace("ä", "a").Replace("ö", "o")
    return ($sam -replace "\s", "")
}

$users = Import-Csv -Path $CsvPath -Encoding UTF8

foreach ($user in $users) {
    $firstName = $user.FirstName
    $lastName = $user.LastName
    $fullName = "$firstName $lastName"

    $samAccountName = ConvertTo-SamAccountName `
        -FirstName $firstName `
        -LastName $lastName

    $userPrincipalName = "$samAccountName@$UpnSuffix"

    $existingUser = Get-ADUser `
        -Filter "SamAccountName -eq '$samAccountName'" `
        -ErrorAction SilentlyContinue

    if ($existingUser) {
        Write-Warning "Account '$samAccountName' already exists. Skipping."
        continue
    }

    $parameters = @{
        Name                  = $fullName
        DisplayName           = $fullName
        GivenName             = $firstName
        Surname               = $lastName
        SamAccountName        = $samAccountName
        UserPrincipalName     = $userPrincipalName
        Path                  = $TargetOU
        AccountPassword       = $DefaultPassword
        Enabled               = $true
        ChangePasswordAtLogon = $true
    }

    if ($user.Title) {
        $parameters.Title = $user.Title
        $parameters.Description = $user.Title
    }

    New-ADUser @parameters
    Write-Host "Created Active Directory account: $samAccountName"
}