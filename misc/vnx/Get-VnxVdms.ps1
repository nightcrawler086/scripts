<#
.Synopsis
   This function is designed to query the VNX through the XML API
   and return all the Virtual Data Movers on the system
.DESCRIPTION
   This command creates the appropriate XML sheet to post to the
   XML API URL to return and XML formatted sheet of the Virtual
   Data Movers on the system and some of their properties.
.EXAMPLE
   PS > .\Get-VnxVdms.ps1 -VNX <VNX_SYSTEM_NAME>
#>
function Get-VnxVdms
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
        [system.net.servicepointmanager]::Servercertificatevalidationcallback = {$true}

        $CREDS = Get-Credential -Message "Enter Credentials to LOGIN into ${VNX}"
        $USER = $CREDS.GetNetworkCredential().UserName
        $PASS = $CREDS.GetNetworkCredential().Password
        $LOGINURI = "https://${VNX}/Login"
        $BODY = "user=${USER}&password=${PASS}&Login=Login"
        $HEADERS = @{"Content-Type" = "x-www-form-urlencoded"}

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
        $QRY = "<VdmQueryParams/>"
        $QRYEND= '</Query></Request>'
        # Standard Footer for XML Sheet
        $XMLFOOTER = '</RequestPacket>'
        # Adding all the pieces together
        $BODY = $XMLTOP + $XMLFORMAT + $QRYBEGIN + $QRY + $QRYEND + $XMLFOOTER
        # This is an empty request that we can use to perform a graceful
        # disconnect of the session we create
        $EMPTYREQ = $XMLTOP + $XMLFORMAT + $QRYBEGIN + $QRYEND + $XMLFOOTER
        # To disconnect the session it requries a specific header:
        $DISCHDR = @{"CelerraConnector-Ctl"="DISCONNECT"}
    }
    PROCESS {
        # This actually logs into the system
        $LOGIN = Invoke-WebRequest -Uri $LOGINURI -Method 'POST' -Body $BODY -SessionVariable WS
        If ($LOGIN.StatusCode -eq 200) {
            # If our LOGIN request succeeded, tell the USER
            # I will probably separate the LOGIN into a different cmdlet
            Write-Host -ForegroundColor Green "Login Succeeded."
            # If our LOGIN is successful, POST the XML sheet we created to query for VDMs
            $RESPONSE = Invoke-WebRequest -Uri $APIURI -WebSession $WS -Headers $HEADERS -Body $BODY -Method Post
            # define the content of the RESPONSE as XML
            $FS = [xml]$RESPONSE.Content
            $OUTPUT = $FS.ResponsePacket.Response
        }
    }
    END {
        If (!$OUTPUT) {
            # If we didn't get any output, print the reponse from teh login attempt
            $RESPONSE.Content
        }
        Else {
            # If we got output, print the 'VDM' member
            $OUTPUT.Vdm
        }
        # Regardless of what happened above, attempt to disconnect.
        $QUIT = Invoke-WebRequest -Uri $APIURI -Method Post -Headers $DISCHDR -WebSession $WS -Body $EMPTYREQ
        If ($($QUIT.StatusCode) -eq "200") {
            # Status code 200 means the disconnect succeeded
            Write-Host -ForegroundColor Green "Session Disconnected."
        }
        Else {
            # If we got a different status code, print the raw content of the resonse
            # from our attempt
            # Maybe change this to the response code and error message?
            $QUIT.RawContent
        }
    }
}
Get-VnxVdms
