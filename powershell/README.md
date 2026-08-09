# Active Directory User Import

This directory contains a PowerShell automation example for creating Active Directory users from CSV data.

## Flow

```mermaid
flowchart TD
    A[employees.example.csv] --> B[Import-Csv]
    B --> C[import-ad-users.ps1]

    C --> D[Read FirstName, LastName and Title]
    D --> E[Generate SAMAccountName]
    E --> F[Generate User Principal Name]
    F --> G{Account already exists?}

    G -->|Yes| H[Skip account]
    G -->|No| I[Create Active Directory user]

    I --> J[Assign target Organizational Unit]
    J --> K[Enable account]
    K --> L[Require password change at first logon]

    L --> M[Active Directory]
```

## Files

`import-ad-users.ps1` imports user data, generates account identifiers, checks for existing accounts and creates new Active Directory users.

`employees.example.csv` provides fictitious example data matching the input format expected by the script.

## Usage

```powershell
$password = Read-Host "Enter temporary password" -AsSecureString

.\import-ad-users.ps1 `
    -CsvPath ".\employees.example.csv" `
    -DefaultPassword $password
```

The target Organizational Unit and UPN suffix can be overridden through the script parameters.