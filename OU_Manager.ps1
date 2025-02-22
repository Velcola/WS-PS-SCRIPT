$defaultOUs = @{
    "salg" = 10
    "produksjon" = 20
    "drift" = 8
}

$domainDN = (Get-ADDomain).DistinguishedName

function Display-Menu {
    Clear-Host
    Write-Host @"
   ___  _   _   __  __   _   _  _   _   ___ ___ ___ 
  / _ \| | | | |  \/  | /_\ | \| | /_\ / __| __| _ \
 | (_) | |_| | | |\/| |/ _ \| .` |/ _ \ (_ | _||   /
  \___/ \___/  |_|  |_/_/ \_\_|\_/_/ \_\___|___|_|_\

  Recognized domain: $($domainDN)
===========================================================
"@
    Write-Host "1. Modify Organizational Units and user limits"
    Write-Host "2. Proceed with default settings"
    Write-Host "3. Exit"
    Write-Host "`n"

    $choice = Read-Host "$>> "
    return $choice
}

function Modify-OUs {
    foreach ($ou in $defaultOUs.Keys) {
        $newLimit = Read-Host "Input number of users for $ou (Current: $($defaultOUs[$ou]))"

        if($newLimit -match "^\d+$") {
            $defaultOUs[$ou] = [int]$newLimit
        } else {
            Write-Host "Invalid user input, keeping the default value of $($defaultOUs[$ou])"
        }
    }
}

function Create-OUs {
    foreach ($ou in $defaultOUs.Keys) {
        $ouPath = "OU=$ou,$domainDN"

        if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ou'")) {
            New-ADOrganizationalUnit -Name $ou -Path $domainDN
            Write-Host "Created OU: $ou"
        } else {
            Write-Host "OU $ou already exists. Skipping."
        }
    }
}

function Import-Users {
    $csvPath = Read-Host "Enter path to the CSV file (e.g., C:\\users.csv)"
    if (!(Test-Path $csvPath)) {
        Write-Host "CSV file not found. Exiting."
        return
    }
    
    $users = Import-Csv $csvPath
    foreach ($ou in $defaultOUs.Keys) {
        $ouPath = (Get-ADOrganizationalUnit -Filter "Name -eq '$ou'" | Select-Object -ExpandProperty DistinguishedName)
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
                Write-Host "Adding user to: $ouPath"
                Write-Host "Created user: $fullname in $ou"
            } else {
                Write-Host "User $fullname already exists. Skipping."
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
            break
        }
        "3" { exit }
        default { Write-Host "Invalid option, please try again." }
    }
}