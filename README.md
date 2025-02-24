# Active Directory OU and User Management Script

This PowerShell script automates the process of creating Organizational Units in Active Directory, importing users from a CSV file, and organizing users into their respective OUs based on department information. It also allows you to view the current settings, such as the parent OU and the number of users in each organizational unit.

## Features

- **Create Parent and Sub-OUs:** Automatically creates the parent OU and sub-OUs based on predefined settings.
- **Import Users:** Imports users from a CSV file (`users.csv`) and places them into their respective OUs.
- **View Settings:** Allows you to view the current parent OU and the number of users assigned to each OU.
- **Flexible CSV Input:** The script supports a variety of CSV formats, allowing you to provide only the necessary fields while ignoring any missing or extra fields.

## CSV Input Flexibility

This script is **highly flexible** and can handle different CSV formats. Below are examples of various CSV structures that are supported by the script. The fields that are missing will simply be ignored, and the script will still function correctly.

### Example 1: **Minimal CSV (Only Required Fields)**

```csv
SAMAccountName,Name,GivenName,Surname,Department
jdoe,John Doe,John,Doe,salg
asmith,Alice Smith,Alice,Smith,produksjon
```

### Example 2: **Standard CSV (Common Fields)**

```csv
SAMAccountName,Name,GivenName,Surname,Email,MobilePhone,WorkPhone,Department
jdoe,John Doe,John,Doe,john.doe@example.com,123456789,987654321,salg
asmith,Alice Smith,Alice,Smith,alice.smith@example.com,555123456,,produksjon
```

### Example 3: **Extended CSV (Including Address Details)**

```csv
SAMAccountName,Name,GivenName,Surname,Email,MobilePhone,StreetAddress,City,State,PostalCode,Country,Department
jdoe,John Doe,John,Doe,john.doe@example.com,123456789,123 Main St,New York,NY,10001,USA,salg
asmith,Alice Smith,Alice,Smith,alice.smith@example.com,,456 Elm St,Los Angeles,CA,90001,USA,produksjon
```

### Example 4: **Password Expiry Options**

```csv
SAMAccountName,Name,GivenName,Surname,Email,PasswordNeverExpires,PasswordExpiryDate,Department
jdoe,John Doe,John,Doe,john.doe@example.com,TRUE,,
asmith,Alice Smith,Alice,Smith,alice.smith@example.com,,2025-06-30,produksjon
btaylor,Bob Taylor,Bob,Taylor,bob.taylor@example.com,,,drift
```

### Example 5: **Mixed CSV (Demonstrates Robustness)**

```csv
SAMAccountName,Name,GivenName,Surname,Email,MobilePhone,StreetAddress,City,Department,PasswordNeverExpires,PasswordExpiryDate,ExtraColumn
jdoe,John Doe,John,Doe,john.doe@example.com,123456789,123 Main St,New York,salg,TRUE,,
asmith,Alice Smith,Alice,Smith,alice.smith@example.com,,456 Elm St,,produksjon,,2025-06-30,SomeData
btaylor,Bob Taylor,Bob,Taylor,bob.taylor@example.com,,,drift,,,
```

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