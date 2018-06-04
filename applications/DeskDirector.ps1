#requires -version 3
<#
.SYNOPSIS
  Collection of functions to manage DeskDirector: https://www.deskdirector.com/
.DESCRIPTION
  Developed for GXA 
  .PARAMETER Verbose
  Provides additional detail to console during execution
.INPUTS None
.OUTPUTS None
.NOTES
  Version:        1.0
  Author:         Rusty Franks
  Creation Date:  2018-03-08
  Purpose/Change: Initial script development
.EXAMPLE
  <Example explanation goes here>
  
  <Example goes here. Repeat this attribute for more than one example>
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

param (
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Import Modules & Snap-ins

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Any Global Declarations go here

#-----------------------------------------------------------[Functions]------------------------------------------------------------
Function Get-DeskDirectorInstallStatus {
    <#
    .SYNOPSIS
      Gets current install status for Desk Director Portal
    .DESCRIPTION
      Checks if the user portal is registered in HKEY_CLASSES_ROOT and if Machine wide .exe exists
    .PARAMETER ProductName
      Product Name is listed in the Desk Director Admin console under DD Portal Installer > Configuration > Product Name
    .PARAMETER PortalType
      User, Machine or Both (Default)
    .INPUTS None
    .OUTPUTS Boolean Response
    .NOTES
      Version:        1.0
      Author:         Rusty Franks
      Creation Date:  2018-03-08
      Purpose/Change: Initial script development
    .EXAMPLE
      Get-DDInstallStatus -ProductName "GXA Customer Portal" -PortalType Both
    #>

    [CmdletBinding()]  
    param (
        [Parameter(Mandatory = $True)]
        [string]$ProductName,
        
        [Parameter(Mandatory = $False)]
        [ValidateSet("User", "Machine", "Both")]
        [string]$PortalType = "Both"
    )

    begin {
        Write-Verbose "$(Get-Date -Format u) : Begin $($MyInvocation.MyCommand)"
        Write-Verbose "$(Get-Date -Format u) : Checking Install locations for existence of DeskDirector Portal components."
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
        $UserInstall = $False
        $MachineInstall = $False
        $Return = $False
    }

    process {
          try {
              if ( Test-Path 'HKCR:\ddportal\shell\open\command' ) {
                  $UserCommand = ( Get-ItemProperty 'HKCR:\ddportal\shell\open\command' ).'(default)'
                  if ( $UserCommand -match "^.+\\" + ($ProductName -replace " ", "_") + "\.exe.+$" ) {
                      Write-Verbose "$(Get-Date -Format u) : DeskDirector User Portal is installed."
                      $UserInstall = $true
                  }                
              }            

              if ( (Test-Path "${env:ProgramFiles(x86)}\$ProductName Installer\deskdirectorportal.exe") -or (Test-Path "${env:ProgramFiles}\$ProductName Installer\deskdirectorportal.exe") ) {
                  Write-Verbose "$(Get-Date -Format u) : DeskDirector Machine-Wide installer exists."
                  $MachineInstall = $True
              }

              switch ($PortalType) {
                  "User" {
                      if ( $UserInstall -eq $True ) { $Return = $True }
                  }
                  "Machine" {
                      if ( $MachineInstall -eq $True ) { $Return = $True }
                  }
                  "Both" {
                      if ( $UserInstall -eq $True -and $MachineInstall -eq $True ) { $Return = $True }
                  }
              }
          }

          catch {
              $errorMessage = $_.Exception.Message
              Write-Error -Message "$(Get-Date -Format u) : Error: [$errorMessage]"
          }

    }

    end {
        Remove-PSDrive -Name HKCR
        Write-Verbose -Message "$(Get-Date -Format u) : Ending $($MyInvocation.InvocationName)..."
        return $Return    
    }
}

Function Install-DeskDirector {
    <#
    .SYNOPSIS
      Gets current install status for Desk Director Portal
    .DESCRIPTION
      Checks if the user portal is registered in HKEY_CLASSES_ROOT and if Machine wide .exe exists
    .PARAMETER ProductName
      Product Name is listed in the Desk Director Admin console under DD Portal Installer > Configuration > Product Name
    .PARAMETER PortalType
      User, Machine or Both (Default)
    .INPUTS None
    .OUTPUTS Boolean Response
    .NOTES
      Version:        1.0
      Author:         Rusty Franks
      Creation Date:  2018-03-08
      Purpose/Change: Initial script development
    .EXAMPLE
      Get-DDInstallStatus -ProductName "GXA Customer Portal" -PortalType Both
    #>

    [CmdletBinding()]  
    param (
        [Parameter(Mandatory = $True)]
        [string]$ProductName,

        [Parameter(Mandatory = $True)]
        [string]$url
    )

    begin {
        Write-Verbose "$(Get-Date -Format u) : Begin $($MyInvocation.MyCommand)"
        Write-Verbose "$(Get-Date -Format u) : Checking Install locations for existence of DeskDirector Portal components."
        $InstallerName = "DeskDirector.msi"

    }

    process {
        try {
        
            Write-Verbose "$(Get-Date -Format u) : Downloading Installer from $url"
            $output = "$env:temp\$InstallerName"
    
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($url, $output)
            
            $args = "/i'$output' /qn"
            
            Start-Process "msiexec.exe" -ArgumentList "/i `"$output`" /qn" -Wait

            If ( Test-Path "${env:ProgramFiles(x86)}\$ProductName Installer\deskdirectorportal.exe" ) {
        
                Write-Verbose "Executable exists. Launching..."
                Start-Process -FilePath "${env:ProgramFiles(x86)}\$ProductName Installer\deskdirectorportal.exe" -ArgumentList "-s"

            }
            ElseIf ( Test-Path "${env:ProgramFiles}\$ProductName Installer\deskdirectorportal.exe" ) {

                Write-Verbose "Executable exists. Launching..."
                Start-Process -FilePath "${env:ProgramFiles}\$ProductName Installer\deskdirectorportal.exe" -ArgumentList "-s"

            }

        }

        catch {
            $errorMessage = $_.Exception.Message
            Write-Error -Message "$(Get-Date -Format u) : Error: [$errorMessage]"
        }

    }

    end {
        Write-Verbose -Message "$(Get-Date -Format u) : Ending $($MyInvocation.InvocationName)..."
        return $Return    
    }
}

Function Uninstall-DeskDirector { 
    <#
    .SYNOPSIS
      Uninstall Desk Director 
    .DESCRIPTION
      Completely remove Desk Director from the target system
    .PARAMETER ProductName
      Product Name is listed in the Desk Director Admin console under DD Portal Installer > Configuration > Product Name
    .INPUTS None
    .OUTPUTS Boolean Response
    .NOTES
      Version:        1.0
      Author:         Rusty Franks
      Creation Date:  2018-03-08
      Purpose/Change: Initial script development
    .EXAMPLE
      Uninstall-DeskDirector -ProductName "GXA Customer Portal"
    #>

    [CmdletBinding()]  
    param (
        [Parameter(Mandatory = $True)]
        [string]$ProductName
    )

    begin {
        Write-Verbose "$(Get-Date -Format u) : Begin $($MyInvocation.MyCommand)"
        Write-Verbose "$(Get-Date -Format u) : Checking Install locations for existence of DeskDirector Portal components."

        $ProfileList = ( 'hklm:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' | `
                Get-ChildItem -ErrorAction SilentlyContinue | `
                Get-ItemProperty -ErrorAction SilentlyContinue )
        $Paths = ( $ProfileList | Where-Object {$_.PSChildName.Length -gt 10} | ForEach-Object {$_.ProfileImagePath} )
        $Executables = @()

    }

    process {
        try {
            
            
            $Paths | ForEach-Object {
                $Path = $_
                $LocalAppData = $Path + "\AppData\Local\deskdirectorportal"
                $RoamingAppData = $Path + "\AppData\Roaming\DeskDirector Portal"
                if ( (Test-Path $LocalAppData) -and (Test-Path $RoamingAppData) ) {
                    $Executables += Get-ChildItem $LocalAppData | Where-Object {$_.PSIsContainer -and $_.name -like 'app-*'} | ForEach-Object { Get-ChildItem $_.FullName *.exe }
                }
                $ExecutableNames = $Executables | Group-Object Name | ForEach-Object {$_.Name}
                $ExecutableNames | ForEach-Object {
                    taskkill /IM $_ /F 2>&1 | Out-Null
                }
                $updateExe = $LocalAppData + "\Update.exe"
                $uninstallParams = "--uninstall -s".Split("")
                if (Test-Path $updateExe) {
                    &"$updateExe" $uninstallParams | Write-Verbose "Waiting"
                }
                Remove-Item $LocalAppdata -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item $RoamingAppData -Recurse -Force -ErrorAction SilentlyContinue
            }

            $ProgramsToUninstall = 'hklm:/Software/Microsoft/Windows/CurrentVersion/Uninstall', 'hklm:/Software/WOW6432Node/Microsoft/Windows/CurrentVersion/Uninstall' | `
                Get-ChildItem -ErrorAction SilentlyContinue | `
                Get-ItemProperty -ErrorAction SilentlyContinue | `
                Where-Object {$_.DisplayName -like "$applicationName*Machine*"}

            $ProgramsToUninstall | ForEach-Object {
                $Program = $_
                $UninstallString = $Program.UninstallString.Replace("/I", "/X") + " /qn"
                Invoke-Expression "cmd /c '$UninstallString'"
            }
        }

        catch {
            $errorMessage = $_.Exception.Message
            Write-Error -Message "$(Get-Date -Format u) : Error: [$errorMessage]"
        }

    }

    end {
        Write-Verbose -Message "$(Get-Date -Format u) : Ending $($MyInvocation.InvocationName)..."    
    }
}

Function Update-DeskDirector {

}

Function Start-DeskDirector {

}

Function Stop-DeskDirector {

}

#-----------------------------------------------------------[Execution]------------------------------------------------------------
Install-DeskDirector -ProductName "GXA Customer Portal" -url "https://downloads.deskdirector.com/gxanetworks/GXA%20Customer%20Portal.msi" -Verbose