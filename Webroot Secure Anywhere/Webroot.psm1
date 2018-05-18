#requires -version 3
<#
.SYNOPSIS
  Collection of functions to manage Webroot SecureAnywhere
.DESCRIPTION
  Developed for GXA 
  .PARAMETER Verbose
  Provides additional detail to console during execution
.INPUTS None
.OUTPUTS None
.NOTES
  Version:        1.0
  Author:         Rusty Franks
  Creation Date:  2018-05-18
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
Function Get-WebrootStatus {
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

Function Install-Webroot {
    <#
    .SYNOPSIS
      Installs Webroot SecureAnywhere
    .DESCRIPTION
      Installs Webroot SecureAnywhere. Requires Keycode.
    .PARAMETER Keycode
      Customer Keycode for install
    .PARAMETER GroupId
      Group Id. Group must already exist in Webroot Console
    .INPUTS None
    .OUTPUTS Boolean Response
    .NOTES
      Version:        1.0
      Author:         Rusty Franks
      Creation Date:  2018-05-18
      Purpose/Change: Initial script development
    .EXAMPLE
      
    #>

    [CmdletBinding()]  
    param (
        [Parameter(Mandatory = $True)]
        [string]$KeyCode,

        [Parameter(Mandatory = $false)]
        [string]$GroupId,

        [Parameter(Mandatory = $false)]
        [string]$uninstallPassword
    )

    begin {
        Write-Verbose "$(Get-Date -Format u) : Begin $($MyInvocation.MyCommand)"
        Write-Verbose "$(Get-Date -Format u) : Checking if Webroot is installed"

        $regPath = "HKLM:\SOFTWARE\WOW6432Node\WRData"
        $installStatus = Test-Path $regPath

    }

    process {
        try {
        
            if ( $installStatus -eq $false ) {

                $args = "/silent /key=$KeyCode /lockautouninstall=$uninstallPassword"
           
                $url = "http://anywhere.webrootcloudav.com/zerol"
                $installerName = "wsasme.exe"
                $output = "$env:temp\$installerName"

                Write-Verbose "$(Get-Date -Format u) : Downloading $installerName from $url"
        
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile("$url/$installerName", $output)    

                Write-Verbose "$(Get-Date -Format u) : Running $output $args"
                Start-Process -FilePath $output -ArgumentList "$args"
                Start-Sleep -Seconds 30

                Write-Verbose "$(Get-Date -Format u) : Testing for success"
                $installStatus = Test-Path $regPath

                if ( $installStatus -eq $true ) {
                    Write-Verbose "$(Get-Date -Format u) : Webroot Successfully Installed"
                }
                else {                    
                    Write-Verbose "$(Get-Date -Format u) : Unable to determine install status"
                }

            }
            else {
                Write-Verbose "$(Get-Date -Format u) : Webroot already exists on machine. Run Reinstall Command"
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

Function Uninstall-Webroot { 
    <#
    .SYNOPSIS
      Uninstall Webroot SecureAnywhere
    .DESCRIPTION
      Completely remove Webroot SecureAnywhere from the target system
    .PARAMETER uninstallPassword
      
    .INPUTS None
    .OUTPUTS Boolean Response
    .NOTES
      Version:        1.0
      Author:         Rusty Franks
      Creation Date:  2018-05-18
      Purpose/Change: Initial script development
    .EXAMPLE
      
    #>

    [CmdletBinding()]  
    param (
        [Parameter(Mandatory = $True)]
        [string]$uninstallPassword
    )

    begin {
        Write-Verbose "$(Get-Date -Format u) : Begin $($MyInvocation.MyCommand)"
        $args = "/autouninstall=$UninstallPassword"
        Write-Verbose "$(Get-Date -Format u) : Checking if Webroot is installed"

        $regPath = "HKLM:\SOFTWARE\WOW6432Node\WRData"
        $installStatus = Test-Path $regPath       

    }

    process {
        try {

            if ( $installStatus -eq $false ) {
                Write-Verbose "$(Get-Date -Format u) : Webroot does not exist on machine."
            }
            else {

                $url = "http://anywhere.webrootcloudav.com/zerol"
                $installerName = "wsasme.exe"
                $output = "$env:temp\$installerName"

                Write-Verbose "$(Get-Date -Format u) : Downloading $installerName from $url"
        
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile("$url/$installerName", $output)  
                
                Write-Verbose "$(Get-Date -Format u) : Running $output with arguments: $args"
                Start-Process -FilePath $output -ArgumentList "$args" -Wait   
                Start-Sleep -Seconds 30

                Write-Verbose "$(Get-Date -Format u) : Testing for success"
                $installStatus = Test-Path $regPath

                if ( $installStatus -eq $false ) {
                    Write-Verbose "$(Get-Date -Format u) : Webroot successfully uninstalled"
                }
                else {                    
                    Write-Verbose "$(Get-Date -Format u) : Unable to remove Webroot SecureAnywhere"
                }
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

Function Update-Webroot {
    <#
    .SYNOPSIS
      Update Webroot SecureAnywhere
    .DESCRIPTION
      Update Webroot using -poll option
      
    .INPUTS None
    .OUTPUTS Boolean Response
    .NOTES
      Version:        1.0
      Author:         Rusty Franks
      Creation Date:  2018-05-18
      Purpose/Change: Initial script development
    .EXAMPLE
      
    #>

    [CmdletBinding()]  
    param (
    )

    begin {
        Write-Verbose "$(Get-Date -Format u) : Begin $($MyInvocation.MyCommand)"
        Write-Verbose "$(Get-Date -Format u) : Checking if Webroot is installed"

        $regPath = "HKLM:\SOFTWARE\WOW6432Node\WRData"
        $installStatus = Test-Path $regPath       

    }

    process {
        try {

            if ( $installStatus -eq $false ) {
                Write-Verbose "$(Get-Date -Format u) : Webroot does not exist on machine."
            }
            else {
                
                $installDirectory = (Get-ItemProperty Registry::HKLM\SOFTWARE\WOW6432Node\WRData).InstallDir
                Write-Verbose "$(Get-Date -Format u) : Webroot installed at $installDirectory."
                Write-Verbose "$(Get-Date -Format u) : Running Poll"

                Start-Process -FilePath $installDirectory -ArgumentList "-poll"
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

Function Start-Webroot {
    <#
    .SYNOPSIS
      Start Webroot SecureAnywhere Service
    .DESCRIPTION
      Start Webroot SecureAnywhere Service
      
    .INPUTS None
    .OUTPUTS Boolean Response
    .NOTES
      Version:        1.0
      Author:         Rusty Franks
      Creation Date:  2018-05-18
      Purpose/Change: Initial script development
    .EXAMPLE
      
    #>

    [CmdletBinding()]  
    param (
    )

    begin {
        Write-Verbose "$(Get-Date -Format u) : Begin $($MyInvocation.MyCommand)"
        Write-Verbose "$(Get-Date -Format u) : Checking if Webroot is installed"

        $regPath = "HKLM:\SOFTWARE\WOW6432Node\WRData"
        $installStatus = Test-Path $regPath       

    }

    process {
        try {

            if ( $installStatus -eq $false ) {
                Write-Verbose "$(Get-Date -Format u) : Webroot does not exist on machine."
            }
            else {
                
                if ( (Get-Service -Name WRSVC).Status -ne "Running" ) {
                    Write-Verbose "$(Get-Date -Format u) : Starting webroot service."
                    Start-Service -Name WRSVC -Force
                }
                else {
                    Write-Verbose "$(Get-Date -Format u) : Webroot service already running."                    
                }
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

#-----------------------------------------------------------[Execution]------------------------------------------------------------
