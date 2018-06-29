<#
.Synopsis
   This is a function to make then inital connection to the VNX
.DESCRIPTION
    This function makes a connection to the VNX API and returns a
    web session.  The web session can be used for subsequent queries
    or configurations.
.EXAMPLE
   PS > .\Connect-Vnx -Name <SYSTEM_NAME>
#>
function Connect-Vnx
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
         ValueFromPipelineByPropertyName=$true,
         Position=0)]
         [ValidateNotNullOrEmpty()]
         [string]$VNX
    )

    BEGIN {
        # This disables certificate checking, so the self-signed certs dont' stop us
        # Let's only try this after if fails to accept the certificate
        [system.net.servicepointmanager]::Servercertificatevalidationcallback = {$true}

        $CREDS = Get-Credential -Message "Enter Credentials to LOGIN into ${VNX}"
        # Below two lines are how we retrieve the plain text version
        # of username and password
        $USER = $CREDS.GetNetworkCredential().UserName
        $PASS = $CREDS.GetNetworkCredential().Password
        $LOGINURI = "https://${VNX}/Login"
        # Credentials provided in the body
        # They will be sent via an HTTPS connection so
        # encrypted in flight
        $BODY = "user=${USER}&password=${PASS}&Login=Login"
        # Content-Type header
        $HEADERS = @{"Content-Type" = "x-www-form-urlencoded"}
        # URL to hit for queries
        $APIURI = "https://${VNX}/servlets/CelerraManagementServices"

        # Standard "top" of XML Sheet
        $XMLTOP = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        # Standard format of XML Shee
        # Can specify the API version herel, but letting the system default to
        # its version so this will work on Celerra (hopefully) and VNX
        $XMLFORMAT = '<RequestPacket xmlns="http://www.emc.com/schemas/celerra/xml_api" >'
        # Standard beginning of a query
        $QRYBEGIN = '<Request><Query>'
        # This is the line that tells the VNX we're querying for VDMs
        # We can add 'Aspects' as modifiers to get different datapoints
        # Adding 'Alias' modifiers will get use specific VDMs that meet
        # whatever our requirements are (ID, Name, etc)
        $QRY = "<CelerraSystemQueryParams/>"
        $QRYEND= '</Query></Request>'
        # Standard Footer for XML Sheet
        $XMLFOOTER = '</RequestPacket>'
        # Adding all the pieces together
        $BODY = $XMLTOP + $XMLFORMAT + $QRYBEGIN + $QRY + $QRYEND + $XMLFOOTER
    }
    PROCESS {
        $ALIVE = Test-Connection -ComputerName ${VNX} -Count 2 -Quiet
        If ($ALIVE) {
            try {
                $LOGIN = Invoke-WebRequest -Uri $LOGINURI -Method 'POST' -Body $BODY -SessionVariable WS
            }
            catch {
                
            }
            If ($LOGIN.StatusCode -eq 200) {
                
            }

            }
            # This actually logs into the system
        }
    }
    END {
        $global:CurrentVnxSession = $WS
    }
}
Connect-Vnx
