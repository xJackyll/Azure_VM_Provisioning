# Declaring the variables
$FileName = "Credential.xml"
$FolderPath = "$PSScriptRoot\..\Data"
$FullPath = Join-Path -Path $FolderPath -ChildPath $FileName

try {
    # Check if the folder exists, and prompt the user to create it if it doesn't
    if (-not (Test-Path -Path $FolderPath -PathType Container)) {
        $createFolder = Read-Host -Prompt "The folder $FolderPath does not exist. Do you want to create it? (Y/N)"

        if ($createFolder -eq 'Y') {
            Write-Host "Creating folder: $FolderPath"
            New-Item -Path $FolderPath -ItemType Directory
        } else {
            Write-Host "Operation canceled. Exiting." -ForegroundColor Yellow
            exit
        }
    }

    # Check if the XML file already exists
    if (Test-Path -Path $FullPath -PathType Leaf) {
        # Ask the user if they want to replace the existing file
        $replaceFile = Read-Host -Prompt "The XML file already exists. Do you want to replace it? (Y/N)"

        if ($replaceFile -eq 'N') {
            Write-Host "Operation canceled. Exiting." -ForegroundColor Yellow
            exit
        }
    }

    # Prompt the user for credentials and save them to an XML file
    $credential = Get-Credential -Message "Enter your credentials"
    $username = $credential.UserName
    $password = $credential.Password

    $cred = New-Object System.Management.Automation.PSCredential($username, $password)
    $cred | Export-Clixml -Path $FullPath

    Write-Host "File created successfully at: $FullPath" -ForegroundColor Green
}
catch {
    Write-Host "Something went wrong and the file was not generated properly" -ForegroundColor Red
}
