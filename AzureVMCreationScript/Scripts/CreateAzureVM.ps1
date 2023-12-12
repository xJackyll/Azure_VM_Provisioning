# Data Creazione: 06/06/2023
# Versione: 1.0
# Autore: Giacomo Caruso 


# Set this variable to $true/$false for seeing/stop seeing debug messages
$Enable_Debug = $true


# Log Function Variables
$Color1 = "Green"
$Color2 = "yellow"
$Color3 = "Red"
$Color4 = "Cyan"

$Err = "Error"
$Warning = "Warning"
$Information = "Info"
$Debug = "Debug"

# Log Variables
$LogName ="Log_Powershell.txt"
$Today = (Get-Date).ToString("yyyy_MM_dd")
$LogPathFolder = "$PSScriptRoot\..\Logs\"
$Global:LogPath = "${LogPathFolder}${Today}${LogName}"

# Authentication Variables

$CredFileName = "Credential.xml"
$CredentialPath = "$PSScriptRoot\..\Data\$CredFileName"

# ------------------------------------------------------------------------------------------------------------------------------------------------
# Parameter Variables

$LocationName = "westeurope"
$Tags = @{                      # These are the tags we want to give to all the resources we are creating
    Environment = "Test"
    Ps = "True"
    Owner = "Giacomo Caruso"
}

# Resource Group Variables
$RgName = "PS-GC-RG"

# Subnet Group Variables
$SubnetName = "PS-GC-SNET01"
$SubnetAddressPrefix = "192.168.1.0/24"

# Vnet Variables
$VnetName = "PS-GC-VNET"
$VnetAddressPrefix = "192.168.0.0/16"

# PIP Variables
$PipName = "PS-GC-PIP"
$PipDomainNameLabel = "vm-full-its"

# NSG Variables
$NsgRuleRDPName = "PS-GC-RDP-RULE"
$NsgRuleRDPPortRange = 3389

$NsgName = "PS-GC-NSG"

# NIC Variables
$NicName = "PS-GC-VM-Full-NIC"

# VM Variables
$VmName = "PS-GC-VM-Full"
$VmSize = "Standard_B2ms"

$PublName = 'MicrosoftWindowsServer' 
$Offer = 'WindowsServer'
$Skus = '2022-Datacenter' 

# -------------------------------------------------------------------------------------------------------------

# Log Function
Function Logging {
    param(
    [string]$Log,
    [string]$MessageType,
    [bool]$DebugMex = $false
    )

    # Get the time
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Color the message
    $TextColor = switch ($MessageType) {
        'Info' { $Color1 }
        'Warning' { $Color2 }
        'Error' { $Color3 }
        'Debug' { $Color4 }
    }

    # Create the formatted string
    if ($Enable_debug -eq $true)
    {
        $logEntry = "$timestamp`t|`t$MessageType`t|`t$Log`t|`t(Line $($MyInvocation.ScriptLineNumber))"
        
    }
    else 
    {
       $logEntry = "$timestamp`t|`t$MessageType`t|`t$Log"
    }

    # Save the log string to the log file
    if (!($Enable_Debug -eq $false -and $MessageType -eq $Debug )) 
    {
        Write-Host $logEntry -ForegroundColor $TextColor
        Add-Content -Path $LogPath -Value $logEntry   
    }

}


# VM Username check Function
Function UsernameCheck {
    param (
        [string]$Username
    )

    # Check if the value is not empty
    if (-not $Username) {
       Logging -Log "Error: Username cannot be empty." -MessageType $Err
        return $false
    }

    # Check if the username follows the specified pattern using regex
    if ($Username -notmatch '^[a-zA-Z][a-zA-Z0-9_-]{0,63}$') {
       Logging -Log "Error: Invalid username format." -MessageType $Err
       Logging -Log "Username must start with a letter, followed by letters, numbers, hyphens, or underscores." -MessageType $Err
       Logging -Log "Username must be between 1 and 64 characters long." -MessageType $Err
        return $false
    }

    # Check if the username length is between 1 and 64 characters
    $length = $Username.Length
    if ($length -lt 1 -or $length -gt 64) {
       Logging -Log "Error: Username must be between 1 and 64 characters long." -MessageType $Err
        return $false
    }

    # If all conditions are met, the username is valid
    return $true
}


# VM Password check Function
Function PasswordCheck {
    param (
        [SecureString]$Password
    )

    # Check if the value is not empty
    if (-not $Password) {
       Logging -Log "Error: Password cannot be empty." -MessageType $Err
        return $false
    }

    # Check if the password meets the complexity requirements with regex
    $lowercase = $Password -cmatch '[a-z]'
    $uppercase = $Password -cmatch '[A-Z]'
    $number = $Password -cmatch '\d'
    $specialChar = $Password -cmatch '[^\w\d]'
    $complexityCount = [int]($lowercase + $uppercase + $number + $specialChar)

    if ($complexityCount -lt 3) {
       Logging -Log "Error: Password must have at least 3 of the following: lower case, upper case, number, special character." -MessageType $Err
        return $false
    }

    # Check if the password length is between 12 and 72 characters
    $length = $Password.Length
    if ($length -lt 12 -or $length -gt 72) {
       Logging -Log "Error: Password must be between 12 and 72 characters long." -MessageType $Err
        return $false
    }

    # If all conditions are met, the password is valid
    return $true
}


# VM Credential check Function
Function UsrPasswCheck {
    # Defining VM credential
    for ($i = 1; $i -le 3; $i++) {
        try {     
             # Entering the username of the VM
             $VmUsername = Read-Host "Enter username "
             if (UsernameCheck -Username $VmUsername) {
                Logging -Log "Username is valid." -MessageType $Information
             } else {
                Logging -Log "Username is not valid." -MessageType $Err
                throw
             }
 
             # Entering the password of the VM
             $VmPassword = Read-Host "Enter password "
             $VmPassword = ConvertTo-SecureString $VmPassword -AsPlainText -Force
             if (PasswordCheck -Password $VmPassword) {
                Logging -Log "Password is valid." -MessageType $Information
 
             } else {
                Logging -Log "Password is not valid." -MessageType $Err
                throw
            }
            # If both are valid return them
            return $VmUsername, $VmPassword
        }

        catch {
            #If username or pasword are invalid we enter the catch and redo the for loop
            Logging -Log "Retry" -MessageType $Warning
        }
    }
    # If the don't enter valid credentials after 3 try the script exits
    Logging -Log "Too many attempts. quitting the script" -MessageType $Err
    return $null
}


# -------------------------------------------------------------------------------------------------------------

# ---------------------
# START OF THE SCRIPT  
# ---------------------

Logging -Log "START OF THE SCRIPT" -MessageType $Information
Logging -Log "THIS SCRIPT CREATE A WINDOWS SERVER VIRTUALE MACHINE WITH ALL THE NECESSARY RESOURCES" -MessageType $Information

try {
    # Checking if the Log folder exists
    if (!(Test-Path -Path $LogPathFolder)) {
        Logging -Log "Log folder not found" -MessageType $Err
        throw
    }

    # Checking if the Az module is intalled
    if (!(Get-InstalledModule -Name Az -ErrorAction Ignore)) {
        Logging -Log "Az Module not found" -MessageType $Err

        if ((Read-Host "Do you want to install it for the current user? (Yes\No)") -ieq "Yes") {
            Logging -Log "Installing the Az Module..." -MessageType $Debug
            Install-Module -Name Az -AllowClobber -Scope CurrentUser
        }
        else {
            throw
        }
    }

    # Checking if the credential file exists
    if ((Test-Path -Path $CredentialPath)) {
        Logging -Log "Using the cred in $CredFileName" -MessageType $Information
        $CredPath = Import-Clixml -Path $CredentialPath
        $AzUsername = $CredPath.UserName
        $AzPassword = $CredPath.Password
        $Cred = New-Object System.Management.Automation.PSCredential($AzUsername, $AzPassword)
    }
    else {
        Logging -Log "Cred file not found" -MessageType $Warning
        Logging -Log "It's suggested using the Credential.xml file for the authentication. Consider using that" -MessageType $Debug
        $Cred = Get-Credential -Message "Enter a username and password for Azure "
    }

    # Connecting to Azure account 
    Connect-AzAccount -Credential $Cred
    Logging -Log "Connected to Azure" -MessageType $Debug

    # -------------------------------------------------------------------------------------------------------------

    $PresetConf = Read-Host "Do you want to use the preset configuration? (Yes/No)"
    if ($PresetConf -ieq "Yes") {
        Logging -Log "Location: $LocationName" -MessageType $Debug
        Logging -Log "VM Size: $VmSize" -MessageType $Debug
        Logging -Log "SKU: $Skus" -MessageType $Debug
        
    }
    else {

        # Get the list of locations
        $GetLocation = Get-AzLocation | Select-Object -ExpandProperty Location

        # If you want the list is printed
        if ((Read-Host "Do you want to have a list of the Location where you can create your resources? (Yes/No)") -ieq "Yes") {
            Write-Host $GetLocation -Separator " | " -ForegroundColor Green  
        }

        # The user enter a location
        $LocationName = Read-Host "Enter a location"

        # Compare user input with the obtained locations
        if ($GetLocation -contains $LocationName) {
            Logging -Log "The location '$LocationName' is valid."  -MessageType $Information
        } else {
            Logging -Log "The location '$LocationName' is not valid or does not exist."  -MessageType $Err
            throw
        }

        # Get the list of VM sizes
        $GetVmSize = Get-AzVMSize -Location $LocationName | Select-Object -ExpandProperty Name

        # If you want the list is printed
        if ((Read-Host "Do you want to have a list of the VM Sizes? (Yes/No)") -ieq "Yes") {
            Write-Host $GetVmSize -Separator " | " -ForegroundColor Green  
        }

        # The user enter a VM size
        $VmSize = Read-Host "Enter a VM size"

        # Compare user input with the obtained VM sizes
        if ($GetVmSize -contains $VmSize) {
            Logging -Log "The VM size '$VmSize' is valid."  -MessageType $Information
        } else {
            Logging -Log "The VM size '$VmSize' is not valid or does not exist."  -MessageType $Err
            throw
        }


        # Get the list of VM SKUs
        $GetVmSku = Get-AzVMImageSku -Location $LocationName -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' | Select-Object -ExpandProperty Skus

        # If you want the list is printed
        if ((Read-Host "Do you want to have a list of the SKUs? (Yes/No)") -ieq "Yes") {
            Write-Host $GetVmSku -Separator " | " -ForegroundColor Green  
        }

        # The user enter a VM SKU
        $Skus = Read-Host "Enter a VM SKU"

        # Compare user input with the obtained VM SKUs
        if ($GetVmSku -contains $Skus) {
            Logging -Log "The VM SKU '$Skus' is valid."  -MessageType $Information
        } else {
            Logging -Log "The VM SKU '$Skus' is not valid or does not exist."  -MessageType $Err
            throw
        }
    }

    # -------------------------------------------------------------------------------------------------------------
    # Creation\configuration of the Resource Group 
    $ResourceGroupParam = @{ 
        Name = $RgName
        Location = $LocationName
        Tag = $Tags
    }
    New-AzResourceGroup @ResourceGroupParam | Out-Null -ErrorAction Stop

    # Wait the resource to be created
    Get-Job | Wait-Job
    Logging -Log "RG created\configured!" -MessageType $Information

    # -------------------------------------------------------------------------------------------------------------
    # Creation\Configuration of the Subnet configuration
    $SubnetParam = @{
        Name = $SubnetName
        AddressPrefix = $SubnetAddressPrefix
    }
    $Subnet = New-AzVirtualNetworkSubnetConfig @SubnetParam -ErrorAction Stop

    # Wait the resource to be created
    Get-Job | Wait-Job
    Logging -Log "Subnet configuration created\configured!" -MessageType $Information

    # -------------------------------------------------------------------------------------------------------------
    # Creation\Configuration of the VNET
    $VnetParam = @{
        Name = $VnetName
        ResourceGroupName = $RgName
        Location = $LocationName
        AddressPrefix = $VnetAddressPrefix
        Subnet = $Subnet
        Tag = $Tags
    }
    $Vnet = New-AzVirtualNetwork @VnetParam -ErrorAction Stop

    # Wait the resource to be created
    Get-Job | Wait-Job
    Logging -Log "VNET created\configured!" -MessageType $Information


    # -------------------------------------------------------------------------------------------------------------
    # Creation\Configuration of the PIP
    $PipParam = @{
        Name = $PipName
        DomainNameLabel = $PipDomainNameLabel
        ResourceGroupName = $RgName
        Location = $LocationName
        Sku = "Basic"
        AllocationMethod = "Static"
        Tag = $Tags
    }
    $Pip = New-AzPublicIpAddress @PipParam -ErrorAction Stop

    # Wait the resource to be created
    Get-Job | Wait-Job
    Logging -Log "PIP created\configured!" -MessageType $Information

    # -------------------------------------------------------------------------------------------------------------
    # Creation\Configuration of the RDP Rule for the NSG
    $NsgRuleRDPParam = @{ 
        Name = $NsgRuleRDPName
        Protocol = "Tcp"
        Direction = "Inbound" 
        Priority = 1000
        SourceAddressPrefix = "*"
        SourcePortRange = "*"
        DestinationAddressPrefix = "*"
        DestinationPortRange = $NsgRuleRDPPortRange
        Access = "Allow"
    }
    $NsgRuleRDP = New-AzNetworkSecurityRuleConfig @NsgRuleRDPParam -ErrorAction Stop

    # Wait the resource to be created
    Get-Job | Wait-Job
    Logging -Log "NSG Rule created\configured!" -MessageType $Information

    # -------------------------------------------------------------------------------------------------------------
    # Creation\Configuration of the NSG
    $NsgParam = @{
        Name = $NsgName
        ResourceGroupName = $RgName
        Location = $LocationName
        SecurityRules = $NsgRuleRDP
        Tag = $Tags
    }
    $Nsg = New-AzNetworkSecurityGroup @NsgParam -ErrorAction Stop

    # Wait the resource to be created
    Get-Job | Wait-Job
    Logging -Log "NSG created\configured!" -MessageType $Information

    # -------------------------------------------------------------------------------------------------------------
    # Creation\Configuration of the NIC
    $NicParam = @{
        Name = $NicName
        ResourceGroupName = $RgName
        Location = $LocationName
        SubnetId = $Vnet.Subnets[0].Id
        PublicIpAddressId = $Pip.Id 
        NetworkSecurityGroupId = $Nsg.Id
        Tag = $Tags
    }
    $Nic = New-AzNetworkInterface @NicParam -ErrorAction Stop

    # Wait the resource to be created
    Get-Job | Wait-Job
    Logging -Log "NIC created\configured!" -MessageType $Information

    # -------------------------------------------------------------------------------------------------------------
    # Configuration of all the parameters of the VM
    $VmConfigParam = @{
        VMName = $VmName
        VMSize = $VmSize
    } 
    $Vm = New-AzVMConfig @VmConfigParam -ErrorAction Stop

    # Wait the resource to be created
    Get-Job | Wait-Job
    Logging -Log "Parameters of the VM configured!" -MessageType $Information

    # -------------------------------------------------------------------------------------------------------------
    # Defining VM credential
    $VmUsername, $VmPassword = UsrPasswCheck
    if ($null -eq $VmUsername, $VmPassword) {throw}

    $VmCred =  New-Object System.Management.Automation.PSCredential -argumentlist $VmUsername, $VmPassword


    $VmOsParam = @{
        VM = $Vm
        Windows = $null
        ComputerName = $VmName
        Credential = $vmCred 
        ProvisionVMAgent = $null
        EnableAutoUpdate = $null
    }
    $Vm = Set-AzVMOperatingSystem @VmOsParam -ErrorAction Stop
    
    # Wait the resource to be created
    Get-Job | Wait-Job
    Logging -Log "OS of the VM configured!" -MessageType $Information

    # -------------------------------------------------------------------------------------------------------------
    $VmNicParam = @{
        VM = $Vm
        Id = $Nic.Id
    }
    $Vm = Add-AzVMNetworkInterface @VmNicParam -ErrorAction Stop
    
    # Wait the resource to be created
    Get-Job | Wait-Job
    Logging -Log "NIC of the VM configured!" -MessageType $Information

    # -------------------------------------------------------------------------------------------------------------
    $VmImageParam = @{
        VM = $Vm
        PublisherName = $PublName
        Offer = $Offer
        Skus = $Skus
        Version = 'latest'
    }
    $Vm = Set-AzVMSourceImage @VmImageParam -ErrorAction Stop
    
    # Wait the resource to be created
    Get-Job | Wait-Job
    Logging -Log "Source Image of the VM configured!" -MessageType $Information

    # -------------------------------------------------------------------------------------------------------------
    # Creation of the VM
    $VMCreationParam = @{
        ResourceGroupName = $RgName
        Location = "$LocationName" 
        VM = $VM
        Verbose = $null
        Tag = $Tags
    }
    Logging -Log "Creating the VM" -MessageType $Information
    Logging -Log "This may take a while..." -MessageType $Information
    New-AzVM @VMCreationParam | Out-Null -ErrorAction Stop
    # Wait the resource to be created
    Get-Job | Wait-Job
    Logging -Log "VM created" -MessageType $Information

    # -------------------------------------------------------------------------------------------------------------
    $Conn = Read-Host "Do you want to connect to the machine? (Yes/No)"

    if ($Conn -ieq "yes") {
        # Connection to the VM
        $PipConnParam = @{
            ResourceGroupName = $RgName 
            Name = $PipName
        }
        
        # Getting the DNS Name of the Vm
        $PipAddr = Get-AzPublicIpAddress @PipConnParam | Select-Object IpAddress
        $GetPip = Get-AzPublicIpAddress -Name $PipName
        

        # A little sum of the information to keep in mind
        Logging -Log "The Username is: $($VmCred.UserName) " -MessageType $Information
        Logging -Log "The Public ip: $($PipAddr.IpAddress) " -MessageType $Information
        Logging -Log "The DNS name is: $($GetPip.DnsSettings.Fqdn) " -MessageType $Information
        mstsc /v:$($PipAddr.IpAddress) | Out-Null
        Logging -Log "Connection to the VM enstablished" -MessageType $Information
    }
    else{
        Logging -Log "Exiting the scipt..." -MessageType $Information
    }
}

# If there is an error it switches to this block and exit the program
catch {
    Logging -Log "Something went wrong. " -MessageType $Err
    Logging -Log "Error: $($_.Exception.Message)" -MessageType $Debug
}
