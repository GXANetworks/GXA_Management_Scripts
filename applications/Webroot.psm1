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

                $args = "/silent /group=$GroupId /key=$KeyCode /lockautouninstall=$uninstallPassword"
           
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
# MIIa6QYJKoZIhvcNAQcCoIIa2jCCGtYCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDmMvc5RG7o5RTu
# KpfbtVc5v37Qk7DYNlp++7WlnRzqeaCCCgkwggTQMIIDuKADAgECAgEHMA0GCSqG
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
# DjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCC3RKcFSOJknpQlwr2ZTzzZ
# 71p3hExXTTqaMwI6FYbWczANBgkqhkiG9w0BAQEFAASCAQAmHHDOvMH3vL0qTNpI
# eLPtsyuS2IbAuzZ7JAohkUZUrWxcKouGbvNzdv4L1AtgFBDtknL55iBuY01U8mhg
# FcHVmr/PI5l+lKJZP6957DOfpJiT0tffU07r+RQGZnZgoZ5QypibjAahgNVbFnMr
# 7EUO0gCKDKwTggpWO81OQkAviJsLfo3L1p13s8M/2RMjnEPHqFhAmD1BtX+f1KHu
# qG/1swOiNMm9qy2eeg6vvRTa+fZ0caAkj/CRAdwkiXeTGXW08faDeLSNhAUstY4x
# bX8Ll/BvjgyCpWQmOo55ATg+wTR9iNsPdAAnQqrdRM1VXrPpYMrDkhhHovMRocOE
# PRBCoYINxjCCDcIGCisGAQQBgjcDAwExgg2yMIINrgYJKoZIhvcNAQcCoIINnzCC
# DZsCAQMxDzANBglghkgBZQMEAgEFADBdBgsqhkiG9w0BCRABBKBOBEwwSgIBAQYK
# YIZIAYb9bgEHGDAhMAkGBSsOAwIaBQAEFMCD8xbNiQvxRmByiPgDQZ6xeOBKAgUx
# LjOq9hgPMjAxODA2MDYxNjA1MTZaoIIKhTCCBQAwggPooAMCAQICAQcwDQYJKoZI
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
# DQYLKoZIhvcNAQkQAQQwHAYJKoZIhvcNAQkFMQ8XDTE4MDYwNjE2MDUxNlowKwYL
# KoZIhvcNAQkQAgwxHDAaMBgwFgQUDV40fNWzeT7P6ua4YNsPVV2+JKUwLwYJKoZI
# hvcNAQkEMSIEIAS/4aYglKlvIdfLP8N9h+7/yimWmG9OGVt9ZU3kcuFBMA0GCSqG
# SIb3DQEBAQUABIIBALDl1g7KdveZf66Ea0jaQdMaROq408AMnBYeltLv2Lgdo6EJ
# RzbnWmWlZXhWd/hlLKEnlOMh3fzEKbOYNVsy0rV7rGfRsoorUP2jUH2hGUfIcJO1
# zR1b//pnqgqsOsbNR7aFIwFyUqRUBv3hOd6giXe5Kz6pVl+CWv0OTUKbQEEjy2zJ
# kchWwHnxDWzXHFKvKGugMLd4K/rQPAcQntaj4dpEhmGneDKdgXBLSPGzrJawPP7Y
# 69mK8gzn3GYmu/Bdk4qfWTN4Sio/xU09TQt6nW6pZF/znPlO8UNbj0ag8cDnsMpZ
# BcjdttgPnO2MqVrp9OQOMOehr0QHZqJg/Cr1NdA=
# SIG # End signature block
