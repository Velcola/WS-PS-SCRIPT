if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "[ERROR] Active Directory module not found. Install it first." -ForegroundColor Red
    exit
}

# Det er bare å forandre på "parentOU" og "defaultOUs" variablene for enkle forandringer :)
# --------------------

$parentOU = "bedrift"
$defaultOUs = @{
    "salg" = 10
    "produksjon" = 20
    "drift" = 8
}

# --------------------

$domainDN = (Get-ADDomain).DistinguishedName

function Display-Menu {
    Clear-Host
    Write-Host @"
   ___  _   _   __  __   _   _  _   _   ___ ___ ___ 
  / _ \| | | | |  \/  | /_\ | \| | /_\ / __| __| _ \
 | (_) | |_| | | |\/| |/ _ \| .` |/ _ \ (_ | _||   /
  \___/ \___/  |_|  |_/_/ \_\_|\_/_/ \_\___|___|_|_\
                (Laget av Patrick :>)

  Auto-recognized domain: $($domainDN)
===========================================================
"@ -ForegroundColor Cyan
    Write-Host "1. View settings" -ForegroundColor Cyan
    Write-Host "2. Proceed with default settings" -ForegroundColor Cyan
    Write-Host "3. Exit" -ForegroundColor Cyan
    Write-Host "`n"
    Write-Host "IMPORTANT: Make sure CSV file is in the same directory as this script. Name has to be 'users.csv'." -ForegroundColor Yellow

    $choice = Read-Host "$>> "
    return $choice
}

function View-Settings {
    Write-Host "Parent OU: $parentOU" -ForegroundColor Cyan
    Write-Host "\nUser Distribution in OUs:" -ForegroundColor Cyan
    foreach ($ou in $defaultOUs.Keys) {
        $userCount = $defaultOUs[$ou]
        Write-Host "$ou : $userCount users" -ForegroundColor Green
    }
    Pause
}

function Create-OUs {
    $parentOUPath = "OU=$parentOU,$domainDN"
    try {
        if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$parentOU'")) {
            New-ADOrganizationalUnit -Name $parentOU -Path $domainDN -ErrorAction Stop
            Write-Host "Created Parent OU: $parentOU" -ForegroundColor Green
        } else {
            Write-Host "Parent OU '$parentOU' already exists. Skipping." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[ERROR] Failed to create Parent OU: $_" -ForegroundColor Red
        return
    }
    
    foreach ($ou in $defaultOUs.Keys) {
        $ouPath = "OU=$ou,$parentOUPath"
        try {
            if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ou'")) {
                New-ADOrganizationalUnit -Name $ou -Path $parentOUPath -ErrorAction Stop
                Write-Host "Created OU: $ou under '$parentOU'" -ForegroundColor Green
            } else {
                Write-Host "OU '$ou' already exists under '$parentOU'. Skipping." -ForegroundColor Yellow
            }
        } catch {
            Write-Host "[ERROR] Failed to create OU '$ou': $_" -ForegroundColor Red
        }
    }
}

function Import-Users {
    $scriptPath = $PSScriptRoot # mappen hvor scriptet befinner seg
    $csvPath = Join-Path -Path $scriptPath -ChildPath "users.csv"

    # sjekk om users.csv finnes i samme mappe som script
    if (!(Test-Path $csvPath)) {
        Write-Host "`n[ERROR] Could not find 'users.csv' in the script directory: $scriptPath" -ForegroundColor Red
        Write-Host "Please place 'users.csv' in the same folder as this script and try again." -ForegroundColor Yellow
        return
    }

    Write-Host "Found users.csv in the script directory. Proceeding with import..." -ForegroundColor Green
    
    $users = Import-Csv $csvPath
    $parentOUPath = "OU=bedrift,$domainDN"
    
    foreach ($ou in $defaultOUs.Keys) {
        $ouPath = "OU=$ou,$parentOUPath"
        $filteredUsers = $users | Where-Object { $_.Department -eq $ou } | Select-Object -First $defaultOUs[$ou]
        
        foreach ($user in $filteredUsers) {
            $username = $user.SAMAccountName
            $fullname = $user.Name
            $password = "Passord1"  # Standard passord, forandre ved behov
            
            try {
                if (-not (Get-ADUser -Filter "SamAccountName -eq '$username'")) {
                    New-ADUser -Name $fullname -GivenName $user.GivenName -Surname $user.Surname -DisplayName $fullname -SamAccountName $username -UserPrincipalName "$username@$env:USERDNSDOMAIN" -Path $ouPath -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -ErrorAction Stop
                    Write-Host "Created $fullname in $ou ($ouPath)" -ForegroundColor Green
                } else {
                    Write-Host "User $fullname already exists. Skipping." -ForegroundColor Yellow
                }
            } catch {
                Write-Host "[ERROR] Failed to create user '$fullname': $_" -ForegroundColor Red
            }
        }
    }
}


while ($true) {
    $choice = Display-Menu

    switch ($choice) {
        "1" { View-Settings }
        "2" {
            Create-OUs
            Import-Users
            Pause
        }
        "3" { exit }
        default { Write-Host "Invalid option, please try again." -ForegroundColor Red }
    }
}