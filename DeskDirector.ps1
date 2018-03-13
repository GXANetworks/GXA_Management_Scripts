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

<#
Function <FunctionName> {
  Param ()
  Begin {
    Write-Host '<description of what is going on>...'
  }
  Process {
    Try {
      <code goes here>
    }
    Catch {
      Write-Host -BackgroundColor Red "Error: $($_.Exception)"
      Break
    }
  }
  End {
    If ($?) {
      Write-Host 'Completed Successfully.'
      Write-Host ' '
    }
  }
}
#>


Function Get-DDInstallStatus {
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

#-----------------------------------------------------------[Execution]------------------------------------------------------------
Get-DDInstallStatus -ProductName "GXA Customer Portal"