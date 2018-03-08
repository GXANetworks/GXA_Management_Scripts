Write-Host "GXA Customer Portal is not running"
Write-Host "Checking if installed..."
    
New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT

If ( Test-Path 'HKCR:\ddportal\shell\open\command' ) {

    Write-Host "GXA Customer Portal is installed"

} Else {

    Write-Host "GXA Customer Portal is not installed for user. Checking machine-wide"

    If ( Test-Path "${env:ProgramFiles(x86)}\GXA Customer Portal Installer\deskdirectorportal.exe" ) {
        
        Write-Host "Executable exists. Launching..."
        Start-Process -FilePath "${env:ProgramFiles(x86)}\GXA Customer Portal Installer\deskdirectorportal.exe" -ArgumentList "-s"

    } ElseIf ( Test-Path "${env:ProgramFiles}\GXA Customer Portal Installer\deskdirectorportal.exe" ) {

        Write-Host "Executable exists. Launching..."
        Start-Process -FilePath "${env:ProgramFiles}\GXA Customer Portal Installer\deskdirectorportal.exe" -ArgumentList "-s"
        
    } Else {

        Write-Host "Executable does not exist. Installing..."

        New-Item -ItemType Directory -Force -Path "$env:systemdrive\GXA\Software\GXA Customer Portal" | Out-Null
        
        Write-Host "Downloading Installer"
        $url = "https://downloads.deskdirector.com/gxanetworks/GXA%20Customer%20Portal.msi"
        $output = "$env:systemdrive\GXA\Software\GXA Customer Portal\GXA%20Customer%20Portal.msi"
    
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($url, $output)
            
        $args = "/i'$output' /qn"
            
        Write-Host "Installing Machine Wide"
        Start-Process "msiexec.exe" -ArgumentList "/i `"$output`" /qn" -Wait
            
        If ( Test-Path "${env:ProgramFiles(x86)}\GXA Customer Portal Installer\deskdirectorportal.exe" ) {
        
            Write-Host "Executable exists. Launching..."
            Start-Process -FilePath "${env:ProgramFiles(x86)}\GXA Customer Portal Installer\deskdirectorportal.exe" -ArgumentList "-s"

        } ElseIf ( Test-Path "${env:ProgramFiles}\GXA Customer Portal Installer\deskdirectorportal.exe" ) {

            Write-Host "Executable exists. Launching..."
            Start-Process -FilePath "${env:ProgramFiles}\GXA Customer Portal Installer\deskdirectorportal.exe" -ArgumentList "-s"

        }

    }
        
}

Remove-PSDrive -Name HKCR

Changes!