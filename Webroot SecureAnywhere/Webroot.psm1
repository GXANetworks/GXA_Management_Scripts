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
# MIIXqwYJKoZIhvcNAQcCoIIXnDCCF5gCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUvDQcVllXNmucrxobd7Hifx/S
# kWygghKiMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3
# DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQDEytT
# eW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEKU5Ow
# mNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0
# jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQDhfu
# ltthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
# d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrFxeoz
# C9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQAB
# o4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRw
# Oi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90
# cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAx
# oC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNy
# bDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAdBgNV
# HQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa
# 1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ijhCcH
# bxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
# BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmRDoDR
# EfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IW
# yhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5Mysu
# e7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUw
# ggTQMIIDuKADAgECAgEHMA0GCSqGSIb3DQEBCwUAMIGDMQswCQYDVQQGEwJVUzEQ
# MA4GA1UECBMHQXJpem9uYTETMBEGA1UEBxMKU2NvdHRzZGFsZTEaMBgGA1UEChMR
# R29EYWRkeS5jb20sIEluYy4xMTAvBgNVBAMTKEdvIERhZGR5IFJvb3QgQ2VydGlm
# aWNhdGUgQXV0aG9yaXR5IC0gRzIwHhcNMTEwNTAzMDcwMDAwWhcNMzEwNTAzMDcw
# MDAwWjCBtDELMAkGA1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcT
# ClNjb3R0c2RhbGUxGjAYBgNVBAoTEUdvRGFkZHkuY29tLCBJbmMuMS0wKwYDVQQL
# EyRodHRwOi8vY2VydHMuZ29kYWRkeS5jb20vcmVwb3NpdG9yeS8xMzAxBgNVBAMT
# KkdvIERhZGR5IFNlY3VyZSBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgLSBHMjCCASIw
# DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALngyxDUr3a91JNi6zBkuIEIbMME
# 2WIXji//PmXPj85i5jxSHNoWRUtVq3hrY4NikM4PaWyZyBoUi0zMRTPqiNyeo68r
# /oBhnXlXxM8u9D8wPF1H/JoWvMM3lkFRjhFLVPgovtCMvvAwOB7zsCb4Zkdjbd5x
# JkePOEdT0UYdtOPcAOpFrL28cdmqbwDb280wOnlPX0xH+B3vW8LEnWA7sbJDkdik
# M07qs9YnT60liqXG9NXQpq50BWRXiLVEVdQtKjo++Li96TIKApRkxBY6UPFKrud5
# M68MIAd/6N8EOcJpAmxjUvp3wRvIdIfIuZMYUFQ1S2lOvDvTSS4f3MHSUvsCAwEA
# AaOCARowggEWMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMB0GA1Ud
# DgQWBBRAwr0njsw0gzCiM9f7bLPwtCyAzjAfBgNVHSMEGDAWgBQ6moUHEGcotu/2
# vQVBbiDBlNoP3jA0BggrBgEFBQcBAQQoMCYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9v
# Y3NwLmdvZGFkZHkuY29tLzA1BgNVHR8ELjAsMCqgKKAmhiRodHRwOi8vY3JsLmdv
# ZGFkZHkuY29tL2dkcm9vdC1nMi5jcmwwRgYDVR0gBD8wPTA7BgRVHSAAMDMwMQYI
# KwYBBQUHAgEWJWh0dHBzOi8vY2VydHMuZ29kYWRkeS5jb20vcmVwb3NpdG9yeS8w
# DQYJKoZIhvcNAQELBQADggEBAAh+bJMQyDi4lqmQS/+hX08E72w+nIgGyVCPpnP3
# VzEbvrzkL9v4utNb4LTn5nliDgyi12pjczG19ahIpDsILaJdkNe0fCVPEVYwxLZE
# nXssneVe5u8MYaq/5Cob7oSeuIN9wUPORKcTcA2RH/TIE62DYNnYcqhzJB61rCIO
# yheJYlhEG6uJJQEAD83EG2LbUbTTD1Eqm/S8c/x2zjakzdnYLOqum/UqspDRTXUY
# ij+KQZAjfVtL/qQDWJtGssNgYIP4fVBBzsKhkMO77wIv0hVU7kQV2Qqup4oz7bEt
# djYm3ATrn/dhHxXch2/uRpYoraEmfQoJpy4Eo428+LwEMAEwggUxMIIEGaADAgEC
# AgkAiFyeSI8LjP4wDQYJKoZIhvcNAQELBQAwgbQxCzAJBgNVBAYTAlVTMRAwDgYD
# VQQIEwdBcml6b25hMRMwEQYDVQQHEwpTY290dHNkYWxlMRowGAYDVQQKExFHb0Rh
# ZGR5LmNvbSwgSW5jLjEtMCsGA1UECxMkaHR0cDovL2NlcnRzLmdvZGFkZHkuY29t
# L3JlcG9zaXRvcnkvMTMwMQYDVQQDEypHbyBEYWRkeSBTZWN1cmUgQ2VydGlmaWNh
# dGUgQXV0aG9yaXR5IC0gRzIwHhcNMTgwNTMxMTM1OTE4WhcNMTkwNTMxMTM1OTE4
# WjByMQswCQYDVQQGEwJVUzEOMAwGA1UECBMFVGV4YXMxEzARBgNVBAcTClJpY2hh
# cmRzb24xHjAcBgNVBAoTFUdYQSBOZXR3b3JrIFNvbHV0aW9uczEeMBwGA1UEAxMV
# R1hBIE5ldHdvcmsgU29sdXRpb25zMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
# CgKCAQEAoAQOfPOJzG7DRk0XUg+t1dTLa96nnAjNE07AGqPKBEOMqc68Vs2VXc5F
# I85OwOZhVZiemKN/heve6rPVYMor7di6sJp/ksxBIvgoaCqszXO6Z4OzglA/F325
# w+YdEcOmwVQQHTE7XGeCTVyUqrpnwoHEnX9Xd89TzKtaAJGWOucIR73D/hs20uwD
# OdarfDxCRUp0b71MTK9M71kP3OElsDW7e/Jq2x2BFVa8O1HSen3Om3DacMUhGg/I
# rmK8y0O9gyyOTGWwqGd6/5DxwZ5Q3sz04ounG70dUE2G0KDqAKFFUwf9oEbeR/NW
# kGRooJLkF/dxK6t/3X3o5TQHWtLxyQIDAQABo4IBhTCCAYEwDAYDVR0TAQH/BAIw
# ADATBgNVHSUEDDAKBggrBgEFBQcDAzAOBgNVHQ8BAf8EBAMCB4AwNQYDVR0fBC4w
# LDAqoCigJoYkaHR0cDovL2NybC5nb2RhZGR5LmNvbS9nZGlnMnM1LTQuY3JsMF0G
# A1UdIARWMFQwSAYLYIZIAYb9bQEHFwIwOTA3BggrBgEFBQcCARYraHR0cDovL2Nl
# cnRpZmljYXRlcy5nb2RhZGR5LmNvbS9yZXBvc2l0b3J5LzAIBgZngQwBBAEwdgYI
# KwYBBQUHAQEEajBoMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5nb2RhZGR5LmNv
# bS8wQAYIKwYBBQUHMAKGNGh0dHA6Ly9jZXJ0aWZpY2F0ZXMuZ29kYWRkeS5jb20v
# cmVwb3NpdG9yeS9nZGlnMi5jcnQwHwYDVR0jBBgwFoAUQMK9J47MNIMwojPX+2yz
# 8LQsgM4wHQYDVR0OBBYEFFZ7BHvdDxR1o16OTX0wlq9Eo60sMA0GCSqGSIb3DQEB
# CwUAA4IBAQBQQHeXCgHf0rUZpYuHmzwokWoePb4eCEZCk5HRIUJJKX6Ue32YNllt
# cT1y3SFguE20XZNEELyCWpLUM7kBThSHnF1s7e77BLR2FmWm5v7O0i/R/SpSxHxK
# 79gO+xpph0xFvXLCzF+mJr/rc1mX/u2WMpFloDPpG6ETKUQYKzGOD+4D/1Dpnnv4
# wb0FFy0Y037u/KgqhVPYRJX/hX3U2lqgf2YmkrJPLxw3OYWg9SUbHStpQuBwt4gh
# QRcQ4KI1559Z5FLHty4zkNHMQ7OmwCcfyG06Gtdiqwacp4MujukKVjRM/zcG7NtV
# u4BOidcqwSaGPYkzhcXJCSbHQblPEu3RMYIEczCCBG8CAQEwgcIwgbQxCzAJBgNV
# BAYTAlVTMRAwDgYDVQQIEwdBcml6b25hMRMwEQYDVQQHEwpTY290dHNkYWxlMRow
# GAYDVQQKExFHb0RhZGR5LmNvbSwgSW5jLjEtMCsGA1UECxMkaHR0cDovL2NlcnRz
# LmdvZGFkZHkuY29tL3JlcG9zaXRvcnkvMTMwMQYDVQQDEypHbyBEYWRkeSBTZWN1
# cmUgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IC0gRzICCQCIXJ5IjwuM/jAJBgUrDgMC
# GgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG
# 9w0BCQQxFgQUVOeHMiFy8d0JoVUZgReZ4fvlt/AwDQYJKoZIhvcNAQEBBQAEggEA
# Mfi1Lo+KS8xuQFDLK+EtBT8uWY8K7KQCoNWq2E8obVg8jQTsxKJUcVNa7z87wRcf
# 7ktSeUh+Q/bnJ+8XTAZVLoWmBHJ8BGK+h4sK+B9ijWtgmNwYu1EYD9wG/p2gQkDD
# JUvCBzLeRO5pXqRG7sgeNUfRffRdUCQ6sXIMGmkI/ESvnawE5N0tsdR8uxUOKNSO
# hGSJNGB0c7rqh6IR3Tf0frcxayEZ89V3DakNmo1x3UOoTLV8LfsKIz7sMO7oHLg6
# 6SII0rTwpKfLgOXkoE1ErFSenLSt+dVgBqaXIJhN48gcQhg0ckUzcoRY3U18XseH
# n4xnYTsBRtcMIjXIH6bIgKGCAgswggIHBgkqhkiG9w0BCQYxggH4MIIB9AIBATBy
# MF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEw
# MC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBDQSAtIEcy
# AhAOz/Q4yP6/NW4E2GqYGxpQMAkGBSsOAwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJ
# KoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0xODA2MDQxOTI5MzNaMCMGCSqGSIb3
# DQEJBDEWBBTOmxdC4T9m9AfP6ZGDrC3u6q26CjANBgkqhkiG9w0BAQEFAASCAQCF
# M8qYGL0/3coP+6wq/D6AKlcY4UyxPyRZHlEeKOMniEuON16kkwpou0705INsnb+B
# 35mKrq76sQU7QZ7IMg+lO3RJh3XwC6LVgO+lOWATb9OHs/T37/8VaYDTt3298mCo
# /bNVOGs9wss4yHpAoqif2Dvz7ODmlLnKuJKlt0tfDOl3CC3h9BCbGFgwt59Jlwrf
# r4tTa2YFw5lVlCPq9duObHEgy/3PsA9L5O5LVBwQaKKjRFUQMa6XnQm2C6GuzH4N
# fzgNMlHkMYVVATa9i+xjJ9zxnhDhPKedPSclOC3D71PMmAjRU+Vwzvpf5qehx/f+
# 1gAvEZaP5w2gch7nfNP3
# SIG # End signature block
