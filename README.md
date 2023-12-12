# Azure VM Creation

## Overview

Welcome to the Azure VM Creation project! 🚀 This repository allows you to effortlessly provision a Windows Server virtual machine in your Azure subscription. Please take a moment to review the information below before executing the provided scripts.

### Prerequisites

Before proceeding, ensure you have the necessary Azure credentials. If you don't already have a `Credential.xml` file, you can create one using the `CreateCred.ps1` script, providing your Azure credentials. Alternatively, you can input your credentials manually when prompted during execution.

## Project Structure

```
ProjectRoot
│ README.md
│ 
├── Scripts
│ ├── CreateAzureVM.ps1
│ └── CreateCred.ps1
│
├── Data
│ └── Credential.xml
│
└── Logs
   └── "YourDate"_AzVM.log
```

## Important Note

This project relies on a specific folder and file structure. To ensure proper functionality, **DO NOT** modify:

- Folder names.
- File names.
- The structure outlined in the "Project Structure" section.

Any alterations to these elements may lead to unexpected behavior and could compromise the project's functionality.

## Execution

To provision the Azure VM, follow these steps:

1. Navigate to the `Scripts` directory.
2. Run 🏃‍♂️ `CreateCred.ps1` to create the `Credential.xml` file if you don't have one (optional).
3. Execute 🚀 `CreateAzureVM.ps1` to initiate the VM creation process.

## Author

**Giacomo Caruso** 👨‍💻

For any questions or issues, feel free to contact the author.

Enjoy your Azure VM creation experience! 🎉