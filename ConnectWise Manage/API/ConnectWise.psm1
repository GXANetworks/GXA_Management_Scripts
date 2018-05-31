#requires -version 3
<#
.SYNOPSIS
  Collection of functions to manage ConnectWise Manage
.DESCRIPTION
  Developed for GXA 
  .PARAMETER Verbose
  Provides additional detail to console during execution
.INPUTS None
.OUTPUTS None
.NOTES
  Version:        1.0
  Author:         Rusty Franks
  Creation Date:  2018-05-21
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
Function ConvertFrom-Json20([object] $item) { 
    add-type -assembly system.web.extensions
    $ps_js = new-object system.web.script.serialization.javascriptSerializer

    #The comma operator is the array construction operator in PowerShell
    return , $ps_js.DeserializeObject($item)
}

Function Get-ConnectWiseCompanyCustomField {
    <#
    .SYNOPSIS
      Get Company Custom Fields from ConnectWise Manage
    .DESCRIPTION
      Get Company Custom Fields from ConnectWise Manage

    .INPUTS None
    .OUTPUTS Array
    .NOTES
      Version:        1.0
      Author:         Rusty Franks
      Creation Date:  20180521
      Purpose/Change: Initial script development
    .EXAMPLE
    #>

    [CmdletBinding()]  
    param (
        [Parameter(Mandatory = $true)][String]$url = "",
        [Parameter(Mandatory = $true)][String]$authCompany = "",
        [Parameter(Mandatory = $true)][String]$authPublic = "",
        [Parameter(Mandatory = $true)][String]$authPrivate = "",
        [Parameter(Mandatory = $true)][String]$companyName = "",
        [Parameter(Mandatory = $true)][String]$fieldName = ""
    )

    begin {
        Write-Verbose "$(Get-Date -Format u) : Begin $($MyInvocation.MyCommand)"
        Write-Verbose "$(Get-Date -Format u) : Building Request"
        
        $authBytes = [System.Text.Encoding]::ASCII.GetBytes("$authCompany+$($authPublic):$AuthPrivate")
        $authEncoded = [Convert]::ToBase64String($authBytes)

        $requestUrlSuffix = "company/companies"
        $requestUrl = $url + $requestUrlSuffix
        
        $requestParams = @{
            "name" = [uri]::EscapeDataString("$companyName")
        }
        
        if ( $requestParams ) {
            $requestUrl = "$($requestUrl)?conditions="
    
            foreach ( $parameter in $requestParams.Keys ) {
                $requestUrl = "$requestUrl$($parameter)=`"$($requestParams.Item($parameter))`""
            }

        }        
        
        $request = [System.Net.WebRequest]::Create("$requestUrl")
        $request.Method = "GET"
        $request.ContentType = "application/json"
        $request.Accept = "application/vnd.connectwise.com+json; version=3.0.0"
        $request.Headers.Add("Authorization", "Basic $authEncoded")

    }

    process {
        try {

            Write-Verbose "$(Get-Date -Format u) : Sending Request to $requestUrl"
        
            $response = $request.GetResponse()
            $responseStream = $response.GetResponseStream()
            $readStream = New-Object System.IO.StreamReader $responseStream
            $data = $readStream.ReadToEnd()
            $result = ConvertFrom-Json20($data)

            Write-Verbose "$(Get-Date -Format u) : Processing Response"   
        
            
            $fieldValue = ($result.customFields | ? { $_.caption -eq $fieldName }).value
            Write-Verbose "$(Get-Date -Format u) : Returned $fieldValue for $fieldName"   

        }

        catch {
            $errorMessage = $_.Exception.Message
            Write-Error -Message "$(Get-Date -Format u) : Error: [$errorMessage]"
        }

    }

    end {
        Write-Verbose -Message "$(Get-Date -Format u) : Ending $($MyInvocation.InvocationName)..."
        return $fieldValue    
    }
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------


#-----------------------------------------------------------[Signature]------------------------------------------------------------
# SIG # Begin signature block
# MIIdwwYJKoZIhvcNAQcCoIIdtDCCHbACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUSCM4dgLEvN5Hgu1d1rEaFKiO
# 9o2gghhXMIIDxTCCAq2gAwIBAgIBADANBgkqhkiG9w0BAQsFADCBgzELMAkGA1UE
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
# DAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUWfZltWW6eiWFQur240v8YLqN
# tXIwDQYJKoZIhvcNAQEBBQAEggEAChoILqbeEwe1CmVw8lKnxkQLTbFEZaYCFr7u
# E7RS05jmGwS3HWHxcSxjL4eaUdrazT7sX98PG4x1bwNe+oare6eS5Aimgd3ZMalh
# 9+R7pPaWAavYeXAk+xiSzXA8ucC5LzkfHgOHtREngiKeLIqhNepLEw/k30KbFMVM
# ZwRr4Sr4gyWh+2xC2JaiBe8QBCNsExOH2mrmsZnNgmOrjiLasdPx1jDJfXC8X5Qy
# fLC2IBFhhdisVNXjYUmBSNXEhwjYr0WsA4R4qzH7a/PDdroSeoH9/+nmREF/TBBW
# MN8oGGa6giYG3NsrTqQIUYEC5Q0XsWbCa+KlozP0+5KyGCBwXqGCAm4wggJqBgkq
# hkiG9w0BCQYxggJbMIICVwIBATCB1DCBxjELMAkGA1UEBhMCVVMxEDAOBgNVBAgT
# B0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxJTAjBgNVBAoTHFN0YXJmaWVs
# ZCBUZWNobm9sb2dpZXMsIEluYy4xMzAxBgNVBAsTKmh0dHA6Ly9jZXJ0cy5zdGFy
# ZmllbGR0ZWNoLmNvbS9yZXBvc2l0b3J5LzE0MDIGA1UEAxMrU3RhcmZpZWxkIFNl
# Y3VyZSBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgLSBHMgIJAO+VwvSA4xuTMAkGBSsO
# AwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEP
# Fw0xODA1MzExOTMzMzBaMCMGCSqGSIb3DQEJBDEWBBRkRV/Y2WJVemvhdK8vmK7q
# v9sa7TANBgkqhkiG9w0BAQEFAASCAQB6mf9tEskFoN56QmYkEz+BBlgIultPEuXQ
# qqAtz96ZEXOTS/M/jFmSvbG7GhbXAYklbaAJQ1C/EGzVuhbDWyhEQNeo7UcLVItY
# /QaPHZa2tCkRAwRcfUqpWvmLeuBOuNxEvMkVO/z6p6J30jFZIduptoPSuPh7IEm/
# Mlkg1lTjU9soFh5rbDj7FwKUnawonRE/b8mJn8nrma+QoSFYFK/tF1GaswB2d2Fw
# EzQVHLsja7gqBxyKcWDSMFY+2QPDIciATUbdxS8nzQrDFcIzo+X6oZMHLroPQ5ll
# wZsYb13XkhmOJFjeBKQQL5DSlzKBwggkI3/Kr42698bcp33EgppR
# SIG # End signature block
