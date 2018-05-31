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
                $status | Add-Member -MemberType NoteProperty -Name 'IsOtherAVEnabled' -Value $statusKey.IsOtherAVEnabled
                $status | Add-Member -MemberType NoteProperty -Name 'IsSilent' -Value $statusKey.IsSilent
                $status | Add-Member -MemberType NoteProperty -Name 'OfflineShieldEnabled' -Value $statusKey.OfflineShieldEnabled
                $status | Add-Member -MemberType NoteProperty -Name 'PhishingShieldEnabled' -Value $statusKey.PhishingShieldEnabled
                $status | Add-Member -MemberType NoteProperty -Name 'ProtectionEnabled' -Value $statusKey.ProtectionEnabled
                $status | Add-Member -MemberType NoteProperty -Name 'RemediationEnabled' -Value $statusKey.RemediationEnabled
                $status | Add-Member -MemberType NoteProperty -Name 'RootkitShieldEnabled' -Value $statusKey.RootkitShieldEnabled
                $status | Add-Member -MemberType NoteProperty -Name 'ScheduledScansEnabled' -Value $statusKey.ScheduledScansEnabled
                $status | Add-Member -MemberType NoteProperty -Name 'USBShieldEnabled' -Value $statusKey.USBShieldEnabled
                $status | Add-Member -MemberType NoteProperty -Name 'WebThreatShieldEnabled' -Value $statusKey.WebThreatShieldEnabled
                $status | Add-Member -MemberType NoteProperty -Name 'OtherAVProduct' -Value $statusKey.OtherAVProduct
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


#-----------------------------------------------------------[Signature]------------------------------------------------------------
# SIG # Begin signature block
# MIIdwwYJKoZIhvcNAQcCoIIdtDCCHbACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUvDQcVllXNmucrxobd7Hifx/S
# kWygghhXMIIDxTCCAq2gAwIBAgIBADANBgkqhkiG9w0BAQsFADCBgzELMAkGA1UE
# BhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxGjAY
# BgNVBAoTEUdvRGFkZHkuY29tLCBJbmMuMTEwLwYDVQQDEyhHbyBEYWRkeSBSb290
# IENlcnRpZmljYXRlIEF1dGhvcml0eSAtIEcyMB4XDTA5MDkwMTAwMDAwMFoXDTM3
# MTIzMTIzNTk1OVowgYMxCzAJBgNVBAYTAlVTMRAwDgYDVQQIEwdBcml6b25hMRMw
# EQYDVQQHEwpTY290dHNkYWxlMRowGAYDVQQKExFHb0RhZGR5LmNvbSwgSW5jLjEx
# MC8GA1UEAxMoR28gRGFkZHkgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgLSBH
# MjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAL9xYgjx+lk09xvJGKP3
# gElY6SKDE6bFIEMBO4Tx5oVJnyfq9oQbTqC023CYxzIBsQU+B07u9PpPL1kwIuer
# GVZr4oAH/PMWdYA5UXvl+TW2dE6pjYIT5LY/qQOD+qK+ihVqf94Lw7YZFAXK6sOo
# BJQ7RnwyDfMAZiLIjWltNowRGLfTshxgtDj6AozO091GB94KPutdfMh8+7ArU6SS
# YmlRJQVhGkSBjCypQ5Yj36w6gZoOKcUcqeldHraenjAKOc7xiID7S13MMuyFYkMl
# NAJWJwGRtDtwKj9useiciAF9n9T521NtYJ2/LOdYq7hfRvzOxBsDPAnrSTFcaUaz
# 4EcCAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYwHQYD
# VR0OBBYEFDqahQcQZyi27/a9BUFuIMGU2g/eMA0GCSqGSIb3DQEBCwUAA4IBAQCZ
# 21151fmXWWcDYfF+OwYxdS2hII5PZYe096acvNjpL9DbWu7PdIxztDhC2gV7+AJ1
# uP2lsdeu9tfeE8tTEH6KRtGX+rcuKxGrkLAngPnon1rpN5+r5N9ss4UXnT3ZJE95
# kTXWXwTrgIOrmgIttRD02JDHBHNA7XIloKmf7J6raBKZV8aPEjoJpL1E/QYVN8Gb
# 5DKj7Tjo2GTzLH4U/ALqn83/B2gX2yKQOC16jdFU8WnjXzPKej17CuPKf1855eJ1
# usV2GDPOLPAvTK33sefOT6jEm0pUBsV/fdUID+Ic/n4XuKxe9tQWskMJDE32p2u0
# mYRlynqI4uJEvlz36hz1MIIE0DCCA7igAwIBAgIBBzANBgkqhkiG9w0BAQsFADCB
# gzELMAkGA1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0
# c2RhbGUxGjAYBgNVBAoTEUdvRGFkZHkuY29tLCBJbmMuMTEwLwYDVQQDEyhHbyBE
# YWRkeSBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAtIEcyMB4XDTExMDUwMzA3
# MDAwMFoXDTMxMDUwMzA3MDAwMFowgbQxCzAJBgNVBAYTAlVTMRAwDgYDVQQIEwdB
# cml6b25hMRMwEQYDVQQHEwpTY290dHNkYWxlMRowGAYDVQQKExFHb0RhZGR5LmNv
# bSwgSW5jLjEtMCsGA1UECxMkaHR0cDovL2NlcnRzLmdvZGFkZHkuY29tL3JlcG9z
# aXRvcnkvMTMwMQYDVQQDEypHbyBEYWRkeSBTZWN1cmUgQ2VydGlmaWNhdGUgQXV0
# aG9yaXR5IC0gRzIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC54MsQ
# 1K92vdSTYuswZLiBCGzDBNliF44v/z5lz4/OYuY8UhzaFkVLVat4a2ODYpDOD2ls
# mcgaFItMzEUz6ojcnqOvK/6AYZ15V8TPLvQ/MDxdR/yaFrzDN5ZBUY4RS1T4KL7Q
# jL7wMDge87Am+GZHY23ecSZHjzhHU9FGHbTj3ADqRay9vHHZqm8A29vNMDp5T19M
# R/gd71vCxJ1gO7GyQ5HYpDNO6rPWJ0+tJYqlxvTV0KaudAVkV4i1RFXULSo6Pvi4
# vekyCgKUZMQWOlDxSq7neTOvDCAHf+jfBDnCaQJsY1L6d8EbyHSHyLmTGFBUNUtp
# Trw700kuH9zB0lL7AgMBAAGjggEaMIIBFjAPBgNVHRMBAf8EBTADAQH/MA4GA1Ud
# DwEB/wQEAwIBBjAdBgNVHQ4EFgQUQMK9J47MNIMwojPX+2yz8LQsgM4wHwYDVR0j
# BBgwFoAUOpqFBxBnKLbv9r0FQW4gwZTaD94wNAYIKwYBBQUHAQEEKDAmMCQGCCsG
# AQUFBzABhhhodHRwOi8vb2NzcC5nb2RhZGR5LmNvbS8wNQYDVR0fBC4wLDAqoCig
# JoYkaHR0cDovL2NybC5nb2RhZGR5LmNvbS9nZHJvb3QtZzIuY3JsMEYGA1UdIAQ/
# MD0wOwYEVR0gADAzMDEGCCsGAQUFBwIBFiVodHRwczovL2NlcnRzLmdvZGFkZHku
# Y29tL3JlcG9zaXRvcnkvMA0GCSqGSIb3DQEBCwUAA4IBAQAIfmyTEMg4uJapkEv/
# oV9PBO9sPpyIBslQj6Zz91cxG7685C/b+LrTW+C05+Z5Yg4MotdqY3MxtfWoSKQ7
# CC2iXZDXtHwlTxFWMMS2RJ17LJ3lXubvDGGqv+QqG+6EnriDfcFDzkSnE3ANkR/0
# yBOtg2DZ2HKocyQetawiDsoXiWJYRBuriSUBAA/NxBti21G00w9RKpv0vHP8ds42
# pM3Z2Czqrpv1KrKQ0U11GIo/ikGQI31bS/6kA1ibRrLDYGCD+H1QQc7CoZDDu+8C
# L9IVVO5EFdkKrqeKM+2xLXY2JtwE65/3YR8V3Idv7kaWKK2hJn0KCacuBKONvPi8
# BDABMIIFADCCA+igAwIBAgIBBzANBgkqhkiG9w0BAQsFADCBjzELMAkGA1UEBhMC
# VVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxJTAjBgNV
# BAoTHFN0YXJmaWVsZCBUZWNobm9sb2dpZXMsIEluYy4xMjAwBgNVBAMTKVN0YXJm
# aWVsZCBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAtIEcyMB4XDTExMDUwMzA3
# MDAwMFoXDTMxMDUwMzA3MDAwMFowgcYxCzAJBgNVBAYTAlVTMRAwDgYDVQQIEwdB
# cml6b25hMRMwEQYDVQQHEwpTY290dHNkYWxlMSUwIwYDVQQKExxTdGFyZmllbGQg
# VGVjaG5vbG9naWVzLCBJbmMuMTMwMQYDVQQLEypodHRwOi8vY2VydHMuc3RhcmZp
# ZWxkdGVjaC5jb20vcmVwb3NpdG9yeS8xNDAyBgNVBAMTK1N0YXJmaWVsZCBTZWN1
# cmUgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IC0gRzIwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQDlkGZL7PlGcakgg77pbL9KyUhpgXVObST2yxcT+LBxWYR6
# ayuFpDS1FuXLzOlBcCykLtb6Mn3hqN6UEKwxwcDYav9ZJ6t21vwLdGu4p64/xFT0
# tDFE3ZNWjKRMXpuJyySDm+JXfbfYEh/JhW300YDxUJuHrtQLEAX7J7oobRfpDtZN
# uTlVBv8KJAV+L8YdcmzUiymMV33a2etmGtNPp99/UsQwxaXJDgLFU793OGgGJMNm
# yDd+MB5FcSM1/5DYKp2N57CSTTx/KgqT3M0WRmX3YISLdkuRJ3MUkuDq7o8W6o0O
# PnYXv32JgIBEQ+ct4EMJddo26K3biTr1XRKOIwSDAgMBAAGjggEsMIIBKDAPBgNV
# HRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIBBjAdBgNVHQ4EFgQUJUWBaFAmOD07
# LSy+zWrZtj2zZmMwHwYDVR0jBBgwFoAUfAwyH6fZMH/EfWijYqihzqsHWycwOgYI
# KwYBBQUHAQEELjAsMCoGCCsGAQUFBzABhh5odHRwOi8vb2NzcC5zdGFyZmllbGR0
# ZWNoLmNvbS8wOwYDVR0fBDQwMjAwoC6gLIYqaHR0cDovL2NybC5zdGFyZmllbGR0
# ZWNoLmNvbS9zZnJvb3QtZzIuY3JsMEwGA1UdIARFMEMwQQYEVR0gADA5MDcGCCsG
# AQUFBwIBFitodHRwczovL2NlcnRzLnN0YXJmaWVsZHRlY2guY29tL3JlcG9zaXRv
# cnkvMA0GCSqGSIb3DQEBCwUAA4IBAQBWZcr+8z8KqJOLGMfeQ2kTNCC+Tl94qGuc
# 22pNQdvBE+zcMQAiXvcAngzgNGU0+bE6TkjIEoGIXFs+CFN69xpk37hQYcxTUUAp
# S8L0rjpf5MqtJsxOYUPl/VemN3DOQyuwlMOS6eFfqhBJt2nk4NAfZKQrzR9voPiE
# JBjOeT2pkb9UGBOJmVQRDVXFJgt5T1ocbvlj2xSApAer+rKluYjdkf5lO6Sjeb6J
# TeHQsPTIFwwKlhR8Cbds4cLYVdQYoKpBaXAko7nv6VrcPuuUSvC33l8Odvr7+2kD
# RUBQ7nIMpBKGgc0T0U7EPMpODdIm8QC3tKai4W56gf0wrHofx1l7MIIFMTCCBBmg
# AwIBAgIJAIhcnkiPC4z+MA0GCSqGSIb3DQEBCwUAMIG0MQswCQYDVQQGEwJVUzEQ
# MA4GA1UECBMHQXJpem9uYTETMBEGA1UEBxMKU2NvdHRzZGFsZTEaMBgGA1UEChMR
# R29EYWRkeS5jb20sIEluYy4xLTArBgNVBAsTJGh0dHA6Ly9jZXJ0cy5nb2RhZGR5
# LmNvbS9yZXBvc2l0b3J5LzEzMDEGA1UEAxMqR28gRGFkZHkgU2VjdXJlIENlcnRp
# ZmljYXRlIEF1dGhvcml0eSAtIEcyMB4XDTE4MDUzMTEzNTkxOFoXDTE5MDUzMTEz
# NTkxOFowcjELMAkGA1UEBhMCVVMxDjAMBgNVBAgTBVRleGFzMRMwEQYDVQQHEwpS
# aWNoYXJkc29uMR4wHAYDVQQKExVHWEEgTmV0d29yayBTb2x1dGlvbnMxHjAcBgNV
# BAMTFUdYQSBOZXR3b3JrIFNvbHV0aW9uczCCASIwDQYJKoZIhvcNAQEBBQADggEP
# ADCCAQoCggEBAKAEDnzzicxuw0ZNF1IPrdXUy2vep5wIzRNOwBqjygRDjKnOvFbN
# lV3ORSPOTsDmYVWYnpijf4Xr3uqz1WDKK+3YurCaf5LMQSL4KGgqrM1zumeDs4JQ
# Pxd9ucPmHRHDpsFUEB0xO1xngk1clKq6Z8KBxJ1/V3fPU8yrWgCRljrnCEe9w/4b
# NtLsAznWq3w8QkVKdG+9TEyvTO9ZD9zhJbA1u3vyatsdgRVWvDtR0np9zptw2nDF
# IRoPyK5ivMtDvYMsjkxlsKhnev+Q8cGeUN7M9OKLpxu9HVBNhtCg6gChRVMH/aBG
# 3kfzVpBkaKCS5Bf3cSurf9196OU0B1rS8ckCAwEAAaOCAYUwggGBMAwGA1UdEwEB
# /wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwDgYDVR0PAQH/BAQDAgeAMDUGA1Ud
# HwQuMCwwKqAooCaGJGh0dHA6Ly9jcmwuZ29kYWRkeS5jb20vZ2RpZzJzNS00LmNy
# bDBdBgNVHSAEVjBUMEgGC2CGSAGG/W0BBxcCMDkwNwYIKwYBBQUHAgEWK2h0dHA6
# Ly9jZXJ0aWZpY2F0ZXMuZ29kYWRkeS5jb20vcmVwb3NpdG9yeS8wCAYGZ4EMAQQB
# MHYGCCsGAQUFBwEBBGowaDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZ29kYWRk
# eS5jb20vMEAGCCsGAQUFBzAChjRodHRwOi8vY2VydGlmaWNhdGVzLmdvZGFkZHku
# Y29tL3JlcG9zaXRvcnkvZ2RpZzIuY3J0MB8GA1UdIwQYMBaAFEDCvSeOzDSDMKIz
# 1/tss/C0LIDOMB0GA1UdDgQWBBRWewR73Q8UdaNejk19MJavRKOtLDANBgkqhkiG
# 9w0BAQsFAAOCAQEAUEB3lwoB39K1GaWLh5s8KJFqHj2+HghGQpOR0SFCSSl+lHt9
# mDZZbXE9ct0hYLhNtF2TRBC8glqS1DO5AU4Uh5xdbO3u+wS0dhZlpub+ztIv0f0q
# UsR8Su/YDvsaaYdMRb1ywsxfpia/63NZl/7tljKRZaAz6RuhEylEGCsxjg/uA/9Q
# 6Z57+MG9BRctGNN+7vyoKoVT2ESV/4V91NpaoH9mJpKyTy8cNzmFoPUlGx0raULg
# cLeIIUEXEOCiNeefWeRSx7cuM5DRzEOzpsAnH8htOhrXYqsGnKeDLo7pClY0TP83
# BuzbVbuATonXKsEmhj2JM4XFyQkmx0G5TxLt0TCCBX0wggRloAMCAQICCQDvlcL0
# gOMbkzANBgkqhkiG9w0BAQsFADCBxjELMAkGA1UEBhMCVVMxEDAOBgNVBAgTB0Fy
# aXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxJTAjBgNVBAoTHFN0YXJmaWVsZCBU
# ZWNobm9sb2dpZXMsIEluYy4xMzAxBgNVBAsTKmh0dHA6Ly9jZXJ0cy5zdGFyZmll
# bGR0ZWNoLmNvbS9yZXBvc2l0b3J5LzE0MDIGA1UEAxMrU3RhcmZpZWxkIFNlY3Vy
# ZSBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgLSBHMjAeFw0xNzExMTQwNzAwMDBaFw0y
# MjExMTQwNzAwMDBaMIGHMQswCQYDVQQGEwJVUzEQMA4GA1UECBMHQXJpem9uYTET
# MBEGA1UEBxMKU2NvdHRzZGFsZTEkMCIGA1UEChMbU3RhcmZpZWxkIFRlY2hub2xv
# Z2llcywgTExDMSswKQYDVQQDEyJTdGFyZmllbGQgVGltZXN0YW1wIEF1dGhvcml0
# eSAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5u99Crt0j8hG
# obYmn8k4UjErxlRcOiYQa2JEGDnB9dEo4hEUVi59ww+dYrFmQyK5MZk3cv8xLdpt
# Kn9qHRpOykT3juzjJRG3hkuAnNdR+zr8RulUgAxW2E5K4BkRHg4BcTwPFs3miWBV
# cCau5HKBUhje/e4RzqGLHfxpA/4qpxIzX2EVHCnWh/W/2M48I7Xurm2uSHqZbDcd
# Hl1lPs8u2339tUG9R0ND9FU7mAm74kSZJ4SjmSkhrjYUPQhQ8zEG3G7G8sd/qL/4
# jGiBqezRzZZP+IUdaxRZjMD0U/5tdtyfMRqaGATzzDh8pNeWxf9ZWkd5AK934W49
# DkKFDlBSAQIDAQABo4IBqTCCAaUwDAYDVR0TAQH/BAIwADAOBgNVHQ8BAf8EBAMC
# BsAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwHQYDVR0OBBYEFJ3PHID+Ctai/FgY
# PqfTVEDu1hRhMB8GA1UdIwQYMBaAFCVFgWhQJjg9Oy0svs1q2bY9s2ZjMIGEBggr
# BgEFBQcBAQR4MHYwKgYIKwYBBQUHMAGGHmh0dHA6Ly9vY3NwLnN0YXJmaWVsZHRl
# Y2guY29tLzBIBggrBgEFBQcwAoY8aHR0cDovL2NybC5zdGFyZmllbGR0ZWNoLmNv
# bS9yZXBvc2l0b3J5L3NmX2lzc3VpbmdfY2EtZzIuY3J0MFQGA1UdHwRNMEswSaBH
# oEWGQ2h0dHA6Ly9jcmwuc3RhcmZpZWxkdGVjaC5jb20vcmVwb3NpdG9yeS9tYXN0
# ZXJzdGFyZmllbGQyaXNzdWluZy5jcmwwUAYDVR0gBEkwRzBFBgtghkgBhv1uAQcX
# AjA2MDQGCCsGAQUFBwIBFihodHRwOi8vY3JsLnN0YXJmaWVsZHRlY2guY29tL3Jl
# cG9zaXRvcnkvMA0GCSqGSIb3DQEBCwUAA4IBAQBSRoHzylZjmuQVGBpIM4GVBwDw
# 1QsQNKA1h9BOfpUAdA5Qx4L+RujuCbtnai/UwCX4UQEtIvj2l8Czlm8/8sWXPY6Q
# jQ21ViESGXcc170e3Tkr0T4FhcVtTLIqedcrPU0Fdsm1QMgPgo1cLjTgC2Fq09mY
# UARKeO5W7C0WoOFcGKcnVZG3ymuBIGnftFdEh0K1scJzGo/+z0/m/FopYU8U0VzV
# pcUZUPvcJWuUqsJ+T8Gn3icL+nhkupygtNHETw0OlgwqOOlYTo5Jr+dCfqPd6fSz
# NoZBbqETK0eTtw/GXINY22m+K0w0/n/lp+XmJ/T8G2Ae3uFjI0Wn8pZuRNx6MYIE
# 1jCCBNICAQEwgcIwgbQxCzAJBgNVBAYTAlVTMRAwDgYDVQQIEwdBcml6b25hMRMw
# EQYDVQQHEwpTY290dHNkYWxlMRowGAYDVQQKExFHb0RhZGR5LmNvbSwgSW5jLjEt
# MCsGA1UECxMkaHR0cDovL2NlcnRzLmdvZGFkZHkuY29tL3JlcG9zaXRvcnkvMTMw
# MQYDVQQDEypHbyBEYWRkeSBTZWN1cmUgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IC0g
# RzICCQCIXJ5IjwuM/jAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAA
# oQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4w
# DAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUVOeHMiFy8d0JoVUZgReZ4fvl
# t/AwDQYJKoZIhvcNAQEBBQAEggEAMfi1Lo+KS8xuQFDLK+EtBT8uWY8K7KQCoNWq
# 2E8obVg8jQTsxKJUcVNa7z87wRcf7ktSeUh+Q/bnJ+8XTAZVLoWmBHJ8BGK+h4sK
# +B9ijWtgmNwYu1EYD9wG/p2gQkDDJUvCBzLeRO5pXqRG7sgeNUfRffRdUCQ6sXIM
# GmkI/ESvnawE5N0tsdR8uxUOKNSOhGSJNGB0c7rqh6IR3Tf0frcxayEZ89V3DakN
# mo1x3UOoTLV8LfsKIz7sMO7oHLg66SII0rTwpKfLgOXkoE1ErFSenLSt+dVgBqaX
# IJhN48gcQhg0ckUzcoRY3U18XseHn4xnYTsBRtcMIjXIH6bIgKGCAm4wggJqBgkq
# hkiG9w0BCQYxggJbMIICVwIBATCB1DCBxjELMAkGA1UEBhMCVVMxEDAOBgNVBAgT
# B0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxJTAjBgNVBAoTHFN0YXJmaWVs
# ZCBUZWNobm9sb2dpZXMsIEluYy4xMzAxBgNVBAsTKmh0dHA6Ly9jZXJ0cy5zdGFy
# ZmllbGR0ZWNoLmNvbS9yZXBvc2l0b3J5LzE0MDIGA1UEAxMrU3RhcmZpZWxkIFNl
# Y3VyZSBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgLSBHMgIJAO+VwvSA4xuTMAkGBSsO
# AwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEP
# Fw0xODA1MzExOTMxNTlaMCMGCSqGSIb3DQEJBDEWBBTOmxdC4T9m9AfP6ZGDrC3u
# 6q26CjANBgkqhkiG9w0BAQEFAASCAQAk0xs7UQlbnznrKqAeCAy0mOg+kFK3YJDs
# /JQQK2CoccLiwOIfGa8DtDMpd8TAz+sdLv0QGKCjEEBK2IMUlB8MgXK0kOJxmSY6
# aDrgdv5N6n/lZfmwzLpfhYchlz4yFFv6+gXnTqr3iGQbTTInlxllZMBozj1U2TSh
# GkNVmm2pVOACgmjo+AWeS7VzhOR8CoF1Cx7AuwUy4piAioNz6ZVl9cWq9JQmBU5R
# 368MsYdM4XnWeicHGAR4JXcx8JXqnuARU/C/JE3eLKGp/jDF/p8in2rERsXH25Ln
# NP25MqJNTheMRLE97k3cFEXxphcSzw8PsB/0/wjysE/WW50oypul
# SIG # End signature block
