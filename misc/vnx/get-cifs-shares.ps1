# make sure xmlAPI is running ours was so I cannot offer much on that part
# xmlAPI guide refers to the config in /nas/sys/nas_mcd.cfg

# get-nas-cifs-share.ps1 *test* (find shares with word test in them)
param(
	[string] $searchstring = $(throw "Please specify a searchstring!.")
  )
  
# ==============================================================================================
# I want to implement LDAP and use AD for auth here for now I hard code password
$LoginURL = "http:/161.127.26.246//Login?user=nasadmin&password=nasadmin:&Login=Login"
$APIURL = "https://161.127.26.246/servlets/CelerraManagementServices"

$StandardXMLTop = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
$XMLRequestStandardFormat = '<RequestPacket xmlns="http://www.emc.com/schemas/celerra/xml_api">'
$XMLRequestStandardFormatFooter = '</RequestPacket>'

$cifsURL = $StandardXMLTop + $XMLRequestStandardFormat + '<Request><Query><CifsShareQueryParams/></Query></Request>' + $XMLRequestStandardFormatFooter
 
# i am on win 8 64 bit had to use version 6 of object
$objHTTP =  New-Object -comobject "Msxml2.ServerXMLHTTP.6.0"

# vbscript that I used for reference ignored errors on cert but I fixed our cert issues
# here is unconverted vb code
# Const SXH_SERVER_CERT_IGNORE_ALL_SERVER_ERRORS = 13056
# lObjHTTP.setOption(2) = SXH_SERVER_CERT_IGNORE_ALL_SERVER_ERRORS

$objHTTP.Open("POST",$LoginURL)
$objHTTP.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
$objHTTP.send()
# uncomment '$objHTTP.ResponseText' for debugging
# while trying to get this to work I SSH'd to CS and ran this command
# tail -f /nas/log/cel_api.log
# strangely, that will show an error but the response text does not under certain error levels
# $objHTTP.ResponseText

$objHTTP.Open("POST",$APIURL,$false)
$objHTTP.setRequestHeader("Content-Type", "text/xml")
$objHTTP.send($cifsURL)
$response = $objHTTP.responseText

# this part was arrived at after some amount of do-do being thrown at cube wall
# there may be better ways to skin this but I could not get any xml parsing stuff
# to work as expected without pulling the namespace stuff out
# I suspect an XML expert might be able to work around this
$xml = $response.Replace("<ResponsePacket xmlns=`"http://www.emc.com/schemas/celerra/xml_api`">", "")
$xml = $xml.Replace("</ResponsePacket>", "")

$xml = [xml]$xml
$shares = $xml.SelectNodes("/Response/CifsShare") 
$shares | foreach{
					# I don't like the #text thing either but accept it
					$server = $_.SelectNodes("CifsServers/li")."#text"
					# so here you can search on whatever
					# uncomment/modify my code in the loop to return what you want to see
					if($_.name -like $searchstring)
						{	
 							$_
# 							$path = $_.path
# 							$sharename = $_.name
# 							$comment = $_.comment
# 							"\\" + $server + "\" + $sharename
#  							"$server`t$path`t$sharename`t$comment"
						}
				}
				
