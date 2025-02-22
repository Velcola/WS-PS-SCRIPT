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
    Write-Host "1. Modify Organizational Units and user limits" -ForegroundColor Cyan
    Write-Host "2. Proceed with default settings" -ForegroundColor Cyan
    Write-Host "3. Exit" -ForegroundColor Cyan
    Write-Host "`n"
    Write-Host "IMPORTANT: Make sure CSV file is in the same directory as this script. Name has to be 'users.csv'."

    $choice = Read-Host "$>> "
    return $choice
}

function Modify-OUs {
    foreach ($ou in $defaultOUs.Keys) {
        $newLimit = Read-Host "Input number of users for $ou (Current: $($defaultOUs[$ou]))"

        if($newLimit -match "^\d+$") {
            $defaultOUs[$ou] = [int]$newLimit
        } else {
            Write-Host "Invalid user input, keeping the default value of $($defaultOUs[$ou])" -ForegroundColor Red
        }
    }
}

function Create-OUs {
    $parentOUPath = "OU=$parentOU,$domainDN"

    # sjekk om parent ou eksisterer
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$parentOU'")) {
        New-ADOrganizationalUnit -Name $parentOU -Path $domainDN
        Write-Host "Created Parent OU: $parentOU" -ForegroundColor Green
    } else {
        Write-Host "Parent OU '$parentOU' already exists. Skipping." -ForegroundColor Yellow
    }

    # lag sub ous inni parent
    foreach ($ou in $defaultOUs.Keys) {
        $ouPath = "OU=$ou,$parentOUPath"

        if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ou'")) {
            New-ADOrganizationalUnit -Name $ou -Path $parentOUPath
            Write-Host "Created OU: $ou under '$parentOU'" -ForegroundColor Green
        } else {
            Write-Host "OU '$ou' already exists under '$parentOU'. Skipping." -ForegroundColor Yellow
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
        Pause
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
            
            if (-not (Get-ADUser -Filter "SamAccountName -eq '$username'")) {
                New-ADUser -Name $fullname -GivenName $user.GivenName -Surname $user.Surname -DisplayName $fullname -SamAccountName $username -UserPrincipalName "$username@$env:USERDNSDOMAIN" -path $ouPath -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force)
                #New-ADUser -Name $fullname -GivenName $user.GivenName -Surname $user.Surname -SamAccountName $username `
                #    -UserPrincipalName "$username@yourdomain.com" -Path $ouPath -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) `
                #    -PassThru | Enable-ADacc
                Write-Host "Created $fullname in $ou ---- ($ouPath)" -ForegroundColor Green
            } else {
                Write-Host "User $fullname already exists. Skipping." -ForegroundColor Yellow
            }
        }
    }
}


while ($true) {
    $choice = Display-Menu

    switch ($choice) {
        "1" { Modify-OUs }
        "2" {
            Create-OUs
            Import-Users
            Pause
        }
        "3" { exit }
        default { Write-Host "Invalid option, please try again." -ForegroundColor Red }
    }
}