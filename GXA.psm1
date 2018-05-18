#requires -version 3
<#
.SYNOPSIS
  Collection of functions to for GXA
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
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

param (
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Import Modules & Snap-ins

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Any Global Declarations go here

#-----------------------------------------------------------[Functions]------------------------------------------------------------
Function Set-GxaPaths {
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

        $gxaPaths = @(
            "$env:systemdrive\GXA",
            "$env:systemdrive\GXA\Utilities",
            "$env:systemdrive\GXA\Temp",
            "$env:systemdrive\GXA\Scripts",
            "$env:systemdrive\GXA\Software",
            "$env:systemdrive\GXA\Software\CryptoPrevent",
            "$env:systemdrive\GXA\Software\Webroot",
            "$env:systemdrive\GXA\Software\OpenDNS",
            "$env:systemdrive\GXA\Logs"
        )

    }

    process {
        try {
            Foreach ( $path in $gxaPaths ) {
                New-Item -ItemType Directory -Force -Path "$path" | Out-Null
            }
        }

        catch {
            $errorMessage = $_.Exception.Message
            Write-Error -Message "$(Get-Date -Format u) : Error: [$errorMessage]"
        }

    }

    end {
        Write-Verbose -Message "$(Get-Date -Format u) : Ending $($MyInvocation.InvocationName)..."
        return 0    
    }
}

Function Get-GxaModules {
    <#
    .SYNOPSIS
      Download latest modules from GitHub
    .DESCRIPTION
      Download latest modules from GitHub

    .INPUTS None
    .OUTPUTS Array
    .NOTES
      Version:        1.0
      Author:         Rusty Franks
      Creation Date:  20180518
      Purpose/Change: Initial script development
    .EXAMPLE
    #>

    [CmdletBinding()]  
    param (
    )

    begin {
        Write-Verbose "$(Get-Date -Format u) : Begin $($MyInvocation.MyCommand)"


    }

    process {
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $response = Invoke-WebRequest "https://github.com/GXANetworks/GXA_Managed_Tools/releases/latest"
            $url = "https://github.com/$(($response.links | where href -match 'zip').href)"
            $url


        }

        catch {
            $errorMessage = $_.Exception.Message
            Write-Error -Message "$(Get-Date -Format u) : Error: [$errorMessage]"
        }

    }

    end {
        Write-Verbose -Message "$(Get-Date -Format u) : Ending $($MyInvocation.InvocationName)..."
        return 0    
    }
}
#-----------------------------------------------------------[Execution]------------------------------------------------------------