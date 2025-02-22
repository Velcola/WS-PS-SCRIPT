# Active Directory OU and User Management Script

This PowerShell script automates the process of creating Organizational Units in Active Directory, importing users from a CSV file, and organizing users into their respective OUs based on department information. It also allows you to view the current settings, such as the parent OU and the number of users in each organizational unit.

## Features

- **Create Parent and Sub-OUs:** Automatically creates the parent OU and sub-OUs based on predefined settings.
- **Import Users:** Imports users from a CSV file (`users.csv`) and places them into their respective OUs.
- **View Settings:** Allows you to view the current parent OU and the number of users assigned to each OU.

## Setup

1. Clone or download this repository to your local machine.
2. Ensure that the `users.csv` file is placed in the same directory as this script. The CSV file must have the correct structure.
3. Open the PowerShell script (`script.ps1`) in PowerShell.

## Usage

### 1. **View Settings**
   - When prompted, choose option `1` to view the current settings, including the parent OU and the distribution of users in each sub-OU.

### 2. **Proceed with Default Settings**
   - Option `2` will create the OUs and import users into them based on the `defaultOUs` settings in the script.
   - The script will automatically check if the parent OU and sub-OUs exist. If they do not, they will be created.
   - The users will be imported from the `users.csv` file and placed into the corresponding OUs based on their `Department`.

### 3. **Exit**
   - Option `3` will exit the script.

### Customize Script Settings

To modify the OUs or user distribution, change the following variables in the script:

- `$parentOU = "bedrift"`: Modify the name of the parent organizational unit.
- `$defaultOUs = @{ "salg" = 10; "produksjon" = 20; "drift" = 8 }`: Modify the sub-OUs and the number of users assigned to each. The keys are the OU names, and the values are the number of users.
