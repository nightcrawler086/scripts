<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-VnxFileSystems
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
         ValueFromPipelineByPropertyName=$true,
         Position=0)]
         [ValidateNotNullOrEmpty()]
         $VNX
    )

    BEGIN {
        # This disables certificate checking, so the self-signed certs dont' stop us
        [system.net.servicepointmanager]::Servercertificatevalidationcallback = {$true}

        $creds = Get-Credential -Message "Enter Credentials to login into ${VNX}"
        $user = $creds.GetNetworkCredential().UserName
        $pass = $creds.GetNetworkCredential().Password
        $LOGINURI = "https://${VNX}/Login"
        $BODY = "user=${user}&password=${pass}&Login=Login"
        $headers = @{"Content-Type" = "x-www-form-urlencoded"}

        $APIURI = "https://${VNX}/servlets/CelerraManagementServices"

        # Standard "top" of XML Sheet
        $XMLTOP = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        # Standard format of XML Sheet
        $XMLFORMAT = '<RequestPacket xmlns="http://www.emc.com/schemas/celerra/xml_api" >'
        # Standard Footer for XML Sheet
        $XMLFOOTER = '</RequestPacket>'
        # Query for CIFS Shares for entire frame
        $QRYBEGIN = '<Request><Query>'
        $QRY = "<FileSystemQueryParams> <AspectSelection fileSystems=""true"" fileSystemCapacityInfos=""true"" /> </FileSystemQueryParams>"
        $QRYEND= '</Query></Request>'
        # Adding all the pieces together
        $FSREQSHT = $XMLTOP + $XMLFORMAT + $QRYBEGIN + $QRY + $QRYEND + $XMLFOOTER
        #$FSREQSHT = [xml]$FSREQSHT

    }
    PROCESS {
        $login = Invoke-WebRequest -Uri $LOGINURI -Method 'POST' -Body $body -SessionVariable session
        If ($login.StatusCode -eq 200) {
            Write-Host -ForegroundColor Green "Login Succeeded."
            $response = Invoke-WebRequest -Uri $APIURI -WebSession $session -Headers $headers -Body $FSREQSHT -Method Post
            $fs = [xml]$response.Content
            $output = $fs.ResponsePacket.Response
        }
    }
    END {
        If (!$output) {
            $response.Content
        }
        Else {
            $output
        }
        $DISCBODY = $XMLTOP + $XMLFORMAT + $QRYBEGIN + $QRYEND + $XMLFOOTER
        $quit = Invoke-WebRequest -Uri $APIURI -Method Post -Headers @{"CelerraConnector-Ctl"="DISCONNECT"} -WebSession $session -Body $DISCBODY
        $quit
        <#
        $close = [System.Net.HttpWebRequest]::Create($APIURI)
        $close.ContentType = "text/xml"
        $close.Headers.Add("CelerraConnector-Ctl", "DISCONNECT")
        $close.CookieContainer = $session.Cookies
        $close
        $logout = $close.GetResponse()
        Write-Host "Logout Response:"
        $logout
        #>
        #If ($($logout.Status) -eq "OK") {
        #    Write-Host -ForegroundColor Green "Session terminated successfully"
        #}
        #Else { 
        #    $logout 
        #}
    }
}
Get-VnxFileSystems


# couple lines of code to use for interacting with the VNX API



# This logs into the system via the api:





# Just for fun, this is the same thing as above, but with curl:
# curl --insecure -X POST https://wrnctinasv1002x/Login -d "user=nasadmin&password=nasadmin&Login=Login" -D temp1.file

# Subsequet requests to the API require the use of the cookie/ticket that's provied
# as a result of the login process above.  the cookie can be retrieved this way:

#$ps.cookies.GetCookies($uri).value

# Next thing the figure out is how to use the cookie in subsequent requrest to 
# get data from the system
#$LoginURL = "http:/161.127.26.246//Login?user=nasadmin&password=nasadmin:&Login=Login"




# THis posts the form to complete the login, expecting a 200 OK response
# Could possibly use the .net methods for this, could be faster

