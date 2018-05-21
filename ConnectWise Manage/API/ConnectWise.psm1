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

