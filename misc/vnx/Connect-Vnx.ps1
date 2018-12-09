<#
.SYNOPSIS
   This is a function to make then inital connection to the VNX
.DESCRIPTION
    This function makes a connection to the VNX API and returns a
    web session.  The web session can be used for subsequent queries
    or configurations.  The web session will be set into a global
    variable for subsequent query/set/modify cmdlets to use
.EXAMPLE
   PS > .\Connect-Vnx -Name <SYSTEM_NAME> -Credential $creds
#>
function Connect-Vnx
{
    [CmdletBinding()]
    Param
    (
        # Specify the VNX to connect to.  Name or IP will work.
        [Parameter(Mandatory=$true,
         ValueFromPipelineByPropertyName=$true,
         Position=0)]
         [ValidateNotNullOrEmpty()]
         [string]$Name,
        # Specify the credential object
        # If none specified, we can promptre
        [Parameter(Mandatory=$false,
         ValueFromPipelineByPropertyName=$false,
         Position=1)]
         [ValidateNotNullOrEmpty()]
         [System.Management.Automation.PSCredential]$Credential
    )
    BEGIN {
        # This disables certificate checking, so the self-signed certs dont' stop us
        Write-Host -Foreground Yellow "Accepting control station certificate without validating..."
        [system.net.servicepointmanager]::Servercertificatevalidationcallback = {$true}
        If (!$Credential) {
            $Credential = Get-Credential -Title "${Name}" -Message "Enter credentials for ${Name}"
        }
        # Below two lines are how we retrieve the plain text version
        # of username and password
        $user = $Credential.GetNetworkCredential().UserName
        $pass = $Credential.GetNetworkCredential().Password
        $loginuri = "https://${Name}/Login"
        # Credentials provided in the body
        # They will be sent via an HTTPS connection so
        # encrypted in flight
        $body = "user=${USER}&password=${PASS}&Login=Login"
        # Content-Type header
        $headers = @{"Content-Type" = "x-www-form-urlencoded"}
        # URL to hit for queries
        $apiuri = "https://${Name}/servlets/CelerraManagementServices"
        # Standard "top" of XML Sheet
        $xmltop = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        # Standard format of XML Shee
        # Can specify the API version here, but letting the system default to
        # its version so this will work on Celerra (hopefully) and VNX
        $xmlformat = '<RequestPacket xmlns="http://www.emc.com/schemas/celerra/xml_api" >'
        # Standard beginning of a query
        $qrybegin = '<Request><Query>'
        # Line specifying the parameters we're querying
        $qry = "<CelerraSystemQueryParams/>"
        $qryend= '</Query></Request>'
        # Standard Footer for XML Sheet
        $xmlfooter = '</RequestPacket>'
        # Adding all the pieces together
        $request = $xmltop + $xmlformat + $qrybegin + $qry + $qryend + $xmlfooter
    }
    PROCESS {
        try {
            $login = Invoke-WebRequest -Uri $loginuri -Method Post -Body $body -SessionVariable ws
        }
        catch {
            Write-Host -ForegroundColor Red "Something went wrong...check your credentials"
        }
        If ($login.StatusCode -eq 200) {
            Set-Variable -Name CurrentVnxFrame -Value $ws -Scope Global
            $response = Invoke-RestMethod -Uri $apiuri -WebSession $CurrentVnxFrame -Headers $headers -Body $request -Method Post

        }
    }
    END {
        
    }
}
Connect-Vnx
