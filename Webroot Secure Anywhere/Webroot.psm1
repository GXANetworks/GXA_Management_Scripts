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
      Gets current status for Webroot SecureAnywhere
    .DESCRIPTION
      Checks if Webroot SecureAnywhere is installed and gets status from the registry

    .INPUTS None
    .OUTPUTS Array
    .NOTES
      Version:        1.0
      Author:         Rusty Franks
      Creation Date:  2018-03-08
      Purpose/Change: Initial script development
    .EXAMPLE
    #>

    [CmdletBinding()]  
    param (
    )

    begin {
        Write-Verbose "$(Get-Date -Format u) : Begin $($MyInvocation.MyCommand)"

        $status = New-Object -TypeName psobject

        Write-Verbose "$(Get-Date -Format u) : Checking if Webroot is installed"

        $regPath = "HKLM:\SOFTWARE\WOW6432Node\WRData"
        $installStatus = Test-Path $regPath
        $status | Add-Member -MemberType NoteProperty -Name 'Installed' -Value $installStatus
    }

    process {
        try {
            if ( $installStatus -eq $true ) {
                
                $statusKey = Get-ItemProperty Registry::HKLM\SOFTWARE\WOW6432Node\WRData\Status
                $status | Add-Member -MemberType NoteProperty -Name 'FirewallEnabled' -Value $statusKey.FirewallEnabled
                $status | Add-Member -MemberType NoteProperty -Name 'IsExpired' -Value $statusKey.IsExpired
                $status | Add-Member -MemberType NoteProperty -Name 'IsFirewallEnabled' -Value $statusKey.IsFirewallEnabled
                $status | Add-Member -MemberType NoteProperty -Name 'isOtherAVEnabled' -Value $statusKey.isOtherAVEnabled
                $status | Add-Member -MemberType NoteProperty -Name 'IsSilent' -Value $statusKey.IsSilent
                $status | Add-Member -MemberType NoteProperty -Name 'OfflineShieldEnabled' -Value $statusKey.OfflineShieldEnabled
                $status | Add-Member -MemberType NoteProperty -Name 'PhishingShieldEnabled' -Value $statusKey.PhishingShieldEnabled
                $status | Add-Member -MemberType NoteProperty -Name 'ProtectionEnabled' -Value $statusKey.ProtectionEnabled
                $status | Add-Member -MemberType NoteProperty -Name 'RemediationEnabled' -Value $statusKey.RemediationEnabled
                $status | Add-Member -MemberType NoteProperty -Name 'RootkitShieldEnabled' -Value $statusKey.RootkitShieldEnabled
                $status | Add-Member -MemberType NoteProperty -Name 'ScheduledScansEnabled' -Value $statusKey.ScheduledScansEnabled
                $status | Add-Member -MemberType NoteProperty -Name 'USBShieldEnabled' -Value $statusKey.USBShieldEnabled
                $status | Add-Member -MemberType NoteProperty -Name 'WebThreatShieldEnabled' -Value $statusKey.WebThreatShieldEnabled
                $status | Add-Member -MemberType NoteProperty -Name 'SKU' -Value $statusKey.SKU
                $status | Add-Member -MemberType NoteProperty -Name 'Version' -Value $statusKey.Version

                
            }
            else {
                Write-Verbose "$(Get-Date -Format u) : Webroot is not installed"                
            }
        }

        catch {
            $errorMessage = $_.Exception.Message
            Write-Error -Message "$(Get-Date -Format u) : Error: [$errorMessage]"
        }

    }

    end {
        Write-Verbose -Message "$(Get-Date -Format u) : Ending $($MyInvocation.InvocationName)..."
        return $status    
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