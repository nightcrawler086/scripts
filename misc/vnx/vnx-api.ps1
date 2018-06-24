# couple lines of code to use for interacting with the VNX API

# This disables certificate checking, so the self-signed certs dont' stop us
[system.net.servicepointmanager]::Servercertificatevalidationcallback = {$true}

# This logs into the system via the api:

$uri = "https://161.127.26.246/Login"
$body = "user=nasadmin&password=nasadmin&Login=Login"



# Just for fun, this is the same thing as above, but with curl:
# curl --insecure -X POST https://wrnctinasv1002x/Login -d "user=nasadmin&password=nasadmin&Login=Login" -D temp1.file

# Subsequet requests to the API require the use of the cookie/ticket that's provied
# as a result of the login process above.  the cookie can be retrieved this way:

#$ps.cookies.GetCookies($uri).value

# Next thing the figure out is how to use the cookie in subsequent requrest to 
# get data from the system
#$LoginURL = "http:/161.127.26.246//Login?user=nasadmin&password=nasadmin:&Login=Login"
$APIURL = "https://161.127.26.246/servlets/CelerraManagementServices"

$StandardXMLTop = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
$XMLRequestStandardFormat = '<RequestPacket xmlns="http://www.emc.com/schemas/celerra/xml_api">'
$XMLRequestStandardFormatFooter = '</RequestPacket>'
$cifsURL = $StandardXMLTop + $XMLRequestStandardFormat + '<Request><Query><CifsShareQueryParams/></Query></Request>' + $XMLRequestStandardFormatFooter

# THis posts the form to complete the login, expecting a 200 OK response
# Could possibly use the .net methods for this, could be faster
$req = Invoke-WebRequest -Uri $uri -Method 'POST' -Body $body -SessionVariable ps

$res = Invoke-WebRequest -Uri $APIURL -WebSession $ps -Headers @{"Content-Type" = "x-www-form-urlencoded"} -Body $cifsURL -Method Post

$content = $res.content

$xml = $content.Replace("<ResponsePacket xmlns=`"http://www.emc.com/schemas/celerra/xml_api`">", "")
$xml = $xml.Replace("</ResponsePacket>", "")

$xml = [xml]$xml

$xml | select -ExpandProperty response | select -ExpandProperty cifsshare

