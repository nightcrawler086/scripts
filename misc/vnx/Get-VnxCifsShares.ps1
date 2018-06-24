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
function Get-VnxCifsShares
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

        $APIURI = "https://${VNX}/servlets/CelerraManagementServices"

        # Standard "top" of XML Sheet
        $XMLTOP = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        # Standard format of XML Sheet
        $XMLFORMAT = '<RequestPacket xmlns="http://www.emc.com/schemas/celerra/xml_api">'
        # Standard Footer for XML Sheet
        $XMLFOOTER = '</RequestPacket>'
        # Query for CIFS Shares for entire frame
        $SHAREQRY = "<Request><Query><CifsShareQueryParams/></Query></Request>"
        # Adding all the pieces together
        $SHRREQSHT = $XMLTOP + $XMLFORMAT + $SHAREQRY + $XMLFOOTER

    }
    PROCESS {
        $login = Invoke-WebRequest -Uri $uri -Method 'POST' -Body $body -SessionVariable session
        If ($login.StatusCode -eq 200) {
            Write-Host -ForegroundColor Green "Login Succeeded."
            $response = Invoke-WebRequest -Uri $APIURL -WebSession $session -Headers @{"Content-Type" = "x-www-form-urlencoded"} -Body $SHRREQSHT -Method Post
            $shares = [xml]$response.Content
            $output = $shares.ResponsePacket.Response.CifsShare
        }
    }
    END {
        $output
    }
}
Get-VnxCifsShares


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

