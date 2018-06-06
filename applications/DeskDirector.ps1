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
# SIG # Begin signature block
# MIIa6QYJKoZIhvcNAQcCoIIa2jCCGtYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDc2yrzFyc3cN1V
# ZssS3yEvCO9keO2IypehnoJJiyIT7aCCCgkwggTQMIIDuKADAgECAgEHMA0GCSqG
# SIb3DQEBCwUAMIGDMQswCQYDVQQGEwJVUzEQMA4GA1UECBMHQXJpem9uYTETMBEG
# A1UEBxMKU2NvdHRzZGFsZTEaMBgGA1UEChMRR29EYWRkeS5jb20sIEluYy4xMTAv
# BgNVBAMTKEdvIERhZGR5IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IC0gRzIw
# HhcNMTEwNTAzMDcwMDAwWhcNMzEwNTAzMDcwMDAwWjCBtDELMAkGA1UEBhMCVVMx
# EDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxGjAYBgNVBAoT
# EUdvRGFkZHkuY29tLCBJbmMuMS0wKwYDVQQLEyRodHRwOi8vY2VydHMuZ29kYWRk
# eS5jb20vcmVwb3NpdG9yeS8xMzAxBgNVBAMTKkdvIERhZGR5IFNlY3VyZSBDZXJ0
# aWZpY2F0ZSBBdXRob3JpdHkgLSBHMjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBALngyxDUr3a91JNi6zBkuIEIbMME2WIXji//PmXPj85i5jxSHNoWRUtV
# q3hrY4NikM4PaWyZyBoUi0zMRTPqiNyeo68r/oBhnXlXxM8u9D8wPF1H/JoWvMM3
# lkFRjhFLVPgovtCMvvAwOB7zsCb4Zkdjbd5xJkePOEdT0UYdtOPcAOpFrL28cdmq
# bwDb280wOnlPX0xH+B3vW8LEnWA7sbJDkdikM07qs9YnT60liqXG9NXQpq50BWRX
# iLVEVdQtKjo++Li96TIKApRkxBY6UPFKrud5M68MIAd/6N8EOcJpAmxjUvp3wRvI
# dIfIuZMYUFQ1S2lOvDvTSS4f3MHSUvsCAwEAAaOCARowggEWMA8GA1UdEwEB/wQF
# MAMBAf8wDgYDVR0PAQH/BAQDAgEGMB0GA1UdDgQWBBRAwr0njsw0gzCiM9f7bLPw
# tCyAzjAfBgNVHSMEGDAWgBQ6moUHEGcotu/2vQVBbiDBlNoP3jA0BggrBgEFBQcB
# AQQoMCYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmdvZGFkZHkuY29tLzA1BgNV
# HR8ELjAsMCqgKKAmhiRodHRwOi8vY3JsLmdvZGFkZHkuY29tL2dkcm9vdC1nMi5j
# cmwwRgYDVR0gBD8wPTA7BgRVHSAAMDMwMQYIKwYBBQUHAgEWJWh0dHBzOi8vY2Vy
# dHMuZ29kYWRkeS5jb20vcmVwb3NpdG9yeS8wDQYJKoZIhvcNAQELBQADggEBAAh+
# bJMQyDi4lqmQS/+hX08E72w+nIgGyVCPpnP3VzEbvrzkL9v4utNb4LTn5nliDgyi
# 12pjczG19ahIpDsILaJdkNe0fCVPEVYwxLZEnXssneVe5u8MYaq/5Cob7oSeuIN9
# wUPORKcTcA2RH/TIE62DYNnYcqhzJB61rCIOyheJYlhEG6uJJQEAD83EG2LbUbTT
# D1Eqm/S8c/x2zjakzdnYLOqum/UqspDRTXUYij+KQZAjfVtL/qQDWJtGssNgYIP4
# fVBBzsKhkMO77wIv0hVU7kQV2Qqup4oz7bEtdjYm3ATrn/dhHxXch2/uRpYoraEm
# fQoJpy4Eo428+LwEMAEwggUxMIIEGaADAgECAgkAiFyeSI8LjP4wDQYJKoZIhvcN
# AQELBQAwgbQxCzAJBgNVBAYTAlVTMRAwDgYDVQQIEwdBcml6b25hMRMwEQYDVQQH
# EwpTY290dHNkYWxlMRowGAYDVQQKExFHb0RhZGR5LmNvbSwgSW5jLjEtMCsGA1UE
# CxMkaHR0cDovL2NlcnRzLmdvZGFkZHkuY29tL3JlcG9zaXRvcnkvMTMwMQYDVQQD
# EypHbyBEYWRkeSBTZWN1cmUgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IC0gRzIwHhcN
# MTgwNTMxMTM1OTE4WhcNMTkwNTMxMTM1OTE4WjByMQswCQYDVQQGEwJVUzEOMAwG
# A1UECBMFVGV4YXMxEzARBgNVBAcTClJpY2hhcmRzb24xHjAcBgNVBAoTFUdYQSBO
# ZXR3b3JrIFNvbHV0aW9uczEeMBwGA1UEAxMVR1hBIE5ldHdvcmsgU29sdXRpb25z
# MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoAQOfPOJzG7DRk0XUg+t
# 1dTLa96nnAjNE07AGqPKBEOMqc68Vs2VXc5FI85OwOZhVZiemKN/heve6rPVYMor
# 7di6sJp/ksxBIvgoaCqszXO6Z4OzglA/F325w+YdEcOmwVQQHTE7XGeCTVyUqrpn
# woHEnX9Xd89TzKtaAJGWOucIR73D/hs20uwDOdarfDxCRUp0b71MTK9M71kP3OEl
# sDW7e/Jq2x2BFVa8O1HSen3Om3DacMUhGg/IrmK8y0O9gyyOTGWwqGd6/5DxwZ5Q
# 3sz04ounG70dUE2G0KDqAKFFUwf9oEbeR/NWkGRooJLkF/dxK6t/3X3o5TQHWtLx
# yQIDAQABo4IBhTCCAYEwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcD
# AzAOBgNVHQ8BAf8EBAMCB4AwNQYDVR0fBC4wLDAqoCigJoYkaHR0cDovL2NybC5n
# b2RhZGR5LmNvbS9nZGlnMnM1LTQuY3JsMF0GA1UdIARWMFQwSAYLYIZIAYb9bQEH
# FwIwOTA3BggrBgEFBQcCARYraHR0cDovL2NlcnRpZmljYXRlcy5nb2RhZGR5LmNv
# bS9yZXBvc2l0b3J5LzAIBgZngQwBBAEwdgYIKwYBBQUHAQEEajBoMCQGCCsGAQUF
# BzABhhhodHRwOi8vb2NzcC5nb2RhZGR5LmNvbS8wQAYIKwYBBQUHMAKGNGh0dHA6
# Ly9jZXJ0aWZpY2F0ZXMuZ29kYWRkeS5jb20vcmVwb3NpdG9yeS9nZGlnMi5jcnQw
# HwYDVR0jBBgwFoAUQMK9J47MNIMwojPX+2yz8LQsgM4wHQYDVR0OBBYEFFZ7BHvd
# DxR1o16OTX0wlq9Eo60sMA0GCSqGSIb3DQEBCwUAA4IBAQBQQHeXCgHf0rUZpYuH
# mzwokWoePb4eCEZCk5HRIUJJKX6Ue32YNlltcT1y3SFguE20XZNEELyCWpLUM7kB
# ThSHnF1s7e77BLR2FmWm5v7O0i/R/SpSxHxK79gO+xpph0xFvXLCzF+mJr/rc1mX
# /u2WMpFloDPpG6ETKUQYKzGOD+4D/1Dpnnv4wb0FFy0Y037u/KgqhVPYRJX/hX3U
# 2lqgf2YmkrJPLxw3OYWg9SUbHStpQuBwt4ghQRcQ4KI1559Z5FLHty4zkNHMQ7Om
# wCcfyG06Gtdiqwacp4MujukKVjRM/zcG7NtVu4BOidcqwSaGPYkzhcXJCSbHQblP
# Eu3RMYIQNjCCEDICAQEwgcIwgbQxCzAJBgNVBAYTAlVTMRAwDgYDVQQIEwdBcml6
# b25hMRMwEQYDVQQHEwpTY290dHNkYWxlMRowGAYDVQQKExFHb0RhZGR5LmNvbSwg
# SW5jLjEtMCsGA1UECxMkaHR0cDovL2NlcnRzLmdvZGFkZHkuY29tL3JlcG9zaXRv
# cnkvMTMwMQYDVQQDEypHbyBEYWRkeSBTZWN1cmUgQ2VydGlmaWNhdGUgQXV0aG9y
# aXR5IC0gRzICCQCIXJ5IjwuM/jANBglghkgBZQMEAgEFAKB8MBAGCisGAQQBgjcC
# AQwxAjAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsx
# DjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCAS3hFE2yWGOJeB94pnHN10
# IxQm+XbDhnPqYlnky/2QkDANBgkqhkiG9w0BAQEFAASCAQCWPHkbyvnSrFlG8Yz0
# tx0u5vACOQdDJZ/ow32JO3V8pEjRYUgUAY2yjwSbIVm9cEUJ6QXsBi4zTtfmtxIm
# CDrrwK+RivABtO8GLWjA+bLz3/9bFbMYzjAOk1rwuQshHvZIDM02vjXyHUcPsc/Z
# l79y1sG6t98JYSgPnkPHlbr3B27r7cjp3N+PLnv1qNnXNK6Y4uuUOxXTFFMQFT8i
# dQ9+KupXdu7mX2mUDhTXYXHZqJ5HMAUQ9lJMNhghCZ0RCn/3VdzONxl8Zx60koCv
# dpQ18CBGTlVi2EKfyRERuqoc5LXOr0hw9cGOgEo12CuTeGuilEwadItbMk2Eqhrt
# 51O4oYINxjCCDcIGCisGAQQBgjcDAwExgg2yMIINrgYJKoZIhvcNAQcCoIINnzCC
# DZsCAQMxDzANBglghkgBZQMEAgEFADBdBgsqhkiG9w0BCRABBKBOBEwwSgIBAQYK
# YIZIAYb9bgEHGDAhMAkGBSsOAwIaBQAEFMCt8m1OllRd28cDgtS4QA/vP1DAAgUx
# LjOtdhgPMjAxODA2MDYxNjA3MThaoIIKhTCCBQAwggPooAMCAQICAQcwDQYJKoZI
# hvcNAQELBQAwgY8xCzAJBgNVBAYTAlVTMRAwDgYDVQQIEwdBcml6b25hMRMwEQYD
# VQQHEwpTY290dHNkYWxlMSUwIwYDVQQKExxTdGFyZmllbGQgVGVjaG5vbG9naWVz
# LCBJbmMuMTIwMAYDVQQDEylTdGFyZmllbGQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRo
# b3JpdHkgLSBHMjAeFw0xMTA1MDMwNzAwMDBaFw0zMTA1MDMwNzAwMDBaMIHGMQsw
# CQYDVQQGEwJVUzEQMA4GA1UECBMHQXJpem9uYTETMBEGA1UEBxMKU2NvdHRzZGFs
# ZTElMCMGA1UEChMcU3RhcmZpZWxkIFRlY2hub2xvZ2llcywgSW5jLjEzMDEGA1UE
# CxMqaHR0cDovL2NlcnRzLnN0YXJmaWVsZHRlY2guY29tL3JlcG9zaXRvcnkvMTQw
# MgYDVQQDEytTdGFyZmllbGQgU2VjdXJlIENlcnRpZmljYXRlIEF1dGhvcml0eSAt
# IEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5ZBmS+z5RnGpIIO+
# 6Wy/SslIaYF1Tm0k9ssXE/iwcVmEemsrhaQ0tRbly8zpQXAspC7W+jJ94ajelBCs
# McHA2Gr/WSerdtb8C3RruKeuP8RU9LQxRN2TVoykTF6bicskg5viV3232BIfyYVt
# 9NGA8VCbh67UCxAF+ye6KG0X6Q7WTbk5VQb/CiQFfi/GHXJs1IspjFd92tnrZhrT
# T6fff1LEMMWlyQ4CxVO/dzhoBiTDZsg3fjAeRXEjNf+Q2Cqdjeewkk08fyoKk9zN
# FkZl92CEi3ZLkSdzFJLg6u6PFuqNDj52F799iYCAREPnLeBDCXXaNuit24k69V0S
# jiMEgwIDAQABo4IBLDCCASgwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMC
# AQYwHQYDVR0OBBYEFCVFgWhQJjg9Oy0svs1q2bY9s2ZjMB8GA1UdIwQYMBaAFHwM
# Mh+n2TB/xH1oo2Kooc6rB1snMDoGCCsGAQUFBwEBBC4wLDAqBggrBgEFBQcwAYYe
# aHR0cDovL29jc3Auc3RhcmZpZWxkdGVjaC5jb20vMDsGA1UdHwQ0MDIwMKAuoCyG
# Kmh0dHA6Ly9jcmwuc3RhcmZpZWxkdGVjaC5jb20vc2Zyb290LWcyLmNybDBMBgNV
# HSAERTBDMEEGBFUdIAAwOTA3BggrBgEFBQcCARYraHR0cHM6Ly9jZXJ0cy5zdGFy
# ZmllbGR0ZWNoLmNvbS9yZXBvc2l0b3J5LzANBgkqhkiG9w0BAQsFAAOCAQEAVmXK
# /vM/CqiTixjH3kNpEzQgvk5feKhrnNtqTUHbwRPs3DEAIl73AJ4M4DRlNPmxOk5I
# yBKBiFxbPghTevcaZN+4UGHMU1FAKUvC9K46X+TKrSbMTmFD5f1XpjdwzkMrsJTD
# kunhX6oQSbdp5ODQH2SkK80fb6D4hCQYznk9qZG/VBgTiZlUEQ1VxSYLeU9aHG75
# Y9sUgKQHq/qypbmI3ZH+ZTuko3m+iU3h0LD0yBcMCpYUfAm3bOHC2FXUGKCqQWlw
# JKO57+la3D7rlErwt95fDnb6+/tpA0VAUO5yDKQShoHNE9FOxDzKTg3SJvEAt7Sm
# ouFueoH9MKx6H8dZezCCBX0wggRloAMCAQICCQDvlcL0gOMbkzANBgkqhkiG9w0B
# AQsFADCBxjELMAkGA1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcT
# ClNjb3R0c2RhbGUxJTAjBgNVBAoTHFN0YXJmaWVsZCBUZWNobm9sb2dpZXMsIElu
# Yy4xMzAxBgNVBAsTKmh0dHA6Ly9jZXJ0cy5zdGFyZmllbGR0ZWNoLmNvbS9yZXBv
# c2l0b3J5LzE0MDIGA1UEAxMrU3RhcmZpZWxkIFNlY3VyZSBDZXJ0aWZpY2F0ZSBB
# dXRob3JpdHkgLSBHMjAeFw0xNzExMTQwNzAwMDBaFw0yMjExMTQwNzAwMDBaMIGH
# MQswCQYDVQQGEwJVUzEQMA4GA1UECBMHQXJpem9uYTETMBEGA1UEBxMKU2NvdHRz
# ZGFsZTEkMCIGA1UEChMbU3RhcmZpZWxkIFRlY2hub2xvZ2llcywgTExDMSswKQYD
# VQQDEyJTdGFyZmllbGQgVGltZXN0YW1wIEF1dGhvcml0eSAtIEcyMIIBIjANBgkq
# hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5u99Crt0j8hGobYmn8k4UjErxlRcOiYQ
# a2JEGDnB9dEo4hEUVi59ww+dYrFmQyK5MZk3cv8xLdptKn9qHRpOykT3juzjJRG3
# hkuAnNdR+zr8RulUgAxW2E5K4BkRHg4BcTwPFs3miWBVcCau5HKBUhje/e4RzqGL
# HfxpA/4qpxIzX2EVHCnWh/W/2M48I7Xurm2uSHqZbDcdHl1lPs8u2339tUG9R0ND
# 9FU7mAm74kSZJ4SjmSkhrjYUPQhQ8zEG3G7G8sd/qL/4jGiBqezRzZZP+IUdaxRZ
# jMD0U/5tdtyfMRqaGATzzDh8pNeWxf9ZWkd5AK934W49DkKFDlBSAQIDAQABo4IB
# qTCCAaUwDAYDVR0TAQH/BAIwADAOBgNVHQ8BAf8EBAMCBsAwFgYDVR0lAQH/BAww
# CgYIKwYBBQUHAwgwHQYDVR0OBBYEFJ3PHID+Ctai/FgYPqfTVEDu1hRhMB8GA1Ud
# IwQYMBaAFCVFgWhQJjg9Oy0svs1q2bY9s2ZjMIGEBggrBgEFBQcBAQR4MHYwKgYI
# KwYBBQUHMAGGHmh0dHA6Ly9vY3NwLnN0YXJmaWVsZHRlY2guY29tLzBIBggrBgEF
# BQcwAoY8aHR0cDovL2NybC5zdGFyZmllbGR0ZWNoLmNvbS9yZXBvc2l0b3J5L3Nm
# X2lzc3VpbmdfY2EtZzIuY3J0MFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly9jcmwu
# c3RhcmZpZWxkdGVjaC5jb20vcmVwb3NpdG9yeS9tYXN0ZXJzdGFyZmllbGQyaXNz
# dWluZy5jcmwwUAYDVR0gBEkwRzBFBgtghkgBhv1uAQcXAjA2MDQGCCsGAQUFBwIB
# FihodHRwOi8vY3JsLnN0YXJmaWVsZHRlY2guY29tL3JlcG9zaXRvcnkvMA0GCSqG
# SIb3DQEBCwUAA4IBAQBSRoHzylZjmuQVGBpIM4GVBwDw1QsQNKA1h9BOfpUAdA5Q
# x4L+RujuCbtnai/UwCX4UQEtIvj2l8Czlm8/8sWXPY6QjQ21ViESGXcc170e3Tkr
# 0T4FhcVtTLIqedcrPU0Fdsm1QMgPgo1cLjTgC2Fq09mYUARKeO5W7C0WoOFcGKcn
# VZG3ymuBIGnftFdEh0K1scJzGo/+z0/m/FopYU8U0VzVpcUZUPvcJWuUqsJ+T8Gn
# 3icL+nhkupygtNHETw0OlgwqOOlYTo5Jr+dCfqPd6fSzNoZBbqETK0eTtw/GXINY
# 22m+K0w0/n/lp+XmJ/T8G2Ae3uFjI0Wn8pZuRNx6MYICmzCCApcCAQEwgdQwgcYx
# CzAJBgNVBAYTAlVTMRAwDgYDVQQIEwdBcml6b25hMRMwEQYDVQQHEwpTY290dHNk
# YWxlMSUwIwYDVQQKExxTdGFyZmllbGQgVGVjaG5vbG9naWVzLCBJbmMuMTMwMQYD
# VQQLEypodHRwOi8vY2VydHMuc3RhcmZpZWxkdGVjaC5jb20vcmVwb3NpdG9yeS8x
# NDAyBgNVBAMTK1N0YXJmaWVsZCBTZWN1cmUgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IC0gRzICCQDvlcL0gOMbkzANBglghkgBZQMEAgEFAKCBmDAaBgkqhkiG9w0BCQMx
# DQYLKoZIhvcNAQkQAQQwHAYJKoZIhvcNAQkFMQ8XDTE4MDYwNjE2MDcxOFowKwYL
# KoZIhvcNAQkQAgwxHDAaMBgwFgQUDV40fNWzeT7P6ua4YNsPVV2+JKUwLwYJKoZI
# hvcNAQkEMSIEIAFk3hI63HCcVq487JZ+FZkPuFIuxW+WD3WlMVi/LreaMA0GCSqG
# SIb3DQEBAQUABIIBADgjb/i5bU2WxYAYFqpG7sarN8a7whIAIwcfM9Q3j5BCOmx0
# bB1nMicnaW6fnXa4o4fSwgkCf4ppZRVMFgijAoeK/BBhoFAXnp+U1TjGi0LwP/VW
# 1rpd6JcFbxMCfxHSu4s47Qf+DmRcrGXdCtPPqo49v5xFXry7O4qkKM7RnEygfOg4
# DY0XMVx9g2+j5zWxL0GDOy92DGlkU97oGQwAChUuzhDyFwMZ0+bsUeYsUZDPW0hv
# CdwD3V7gqUUI+96Qd8t84+hP2v4GXThjze6qGZWkUjH8h8dIWiKbS7GYrpCYvumo
# 1q6x0fuKQ9578teNlfVTRjm90R6FwJ/FlbTrtbo=
# SIG # End signature block
