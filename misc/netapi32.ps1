<#  
.SYNOPSIS  
    Defines all the functions in Netapi32.dll so they can be used within Powershell.
.DESCRIPTION  
    Supported functions:
		Get-Shares  
			server can be $null to point to localhost
			level can be 0 1 2 502 503
			Remark: Uses NetShareEnum
		
		Get-NetStatistics  
			type can be SERVER or WORKSTATION
			Remark: Uses NetStatisticsGet
 
		Get-Sessions    
			level can be 0 1 2 10 502
			Remark: Uses NetConnectionEnum
 
		Get-OpenFiles    
			level can be 2 3
			Remark: Uses NetFileEnum
 
.EXAMPLE
	Get-NetStatistics localhost SERVER
	Get-Shares localhost 503
	Get-Sessions localhost 502
	Get-OpenFiles localhost 3
.NOTES  
	Filename	: Netapi.ps1
    Author     	: Micky Balladelli micky@balladelli.com  
.LINK  
    https://balladelli.com/netapi-et-powershell/
#> 
[CmdletBinding(DefaultParametersetName="Get-Shares")]
param ( [Parameter(Position=1)][string]$function="Get-Shares", 
		[Parameter(Position=2)][string]$server = "localhost", 
		[Parameter(Position=3)][Int32]$level=0, 
		[Parameter(Position=3,ParameterSetName='Get-NetStatistics')][string]$type="WORKSTATION",
		[Parameter(Position=3,ParameterSetName='Get-OpenFiles')][string]$path=$null,
		[Parameter(Position=4)][string]$user=$null,
		[Parameter(Position=5,ParameterSetName='Get-Sessions')][string]$client=$null)
 
 
Add-Type -TypeDefinition @" 
using System; 
using System.Runtime.InteropServices;
 
public class Netapi 
{ 
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct SHARE_INFO_0
    {
		[MarshalAs(UnmanagedType.LPWStr)] public String Name;
    }
 
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct SHARE_INFO_1
    {
		[MarshalAs(UnmanagedType.LPWStr)] public string Name;
		public uint Type;
		[MarshalAs(UnmanagedType.LPWStr)] public string Remark;
    }
 
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct SHARE_INFO_2
    {
		[MarshalAs(UnmanagedType.LPWStr)] public string Name;
		public uint Type;
		[MarshalAs(UnmanagedType.LPWStr)] public string Remark;
		public uint Permissions;
		public uint MaxUses;
		public uint CurrentUses;
		[MarshalAs(UnmanagedType.LPWStr)] public string Path;
		[MarshalAs(UnmanagedType.LPWStr)] public string Password;
   }
 
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct SHARE_INFO_502
    {
		[MarshalAs(UnmanagedType.LPWStr)] public string Name;
		public uint Type;
		[MarshalAs(UnmanagedType.LPWStr)] public string Remark;
		public uint Permissions;
		public uint MaxUses;
		public uint CurrentUses;
		[MarshalAs(UnmanagedType.LPWStr)] public string Path;
		[MarshalAs(UnmanagedType.LPWStr)] public string Password;		
		public uint Reserved;
		public IntPtr SecurityDescriptor;
    }
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct SHARE_INFO_503
    {
		[MarshalAs(UnmanagedType.LPWStr)] public string Name;
		public uint Type;
		[MarshalAs(UnmanagedType.LPWStr)] public string Remark;
		public uint Permissions;
		public uint MaxUses;
		public uint CurrentUses;
		[MarshalAs(UnmanagedType.LPWStr)] public string Path;
		[MarshalAs(UnmanagedType.LPWStr)] public string Password;		
		[MarshalAs(UnmanagedType.LPWStr)] public string ServerName;		
		public uint Reserved;
		public IntPtr SecurityDescriptor;
    }
 
	[DllImport("Netapi32.dll",CharSet=CharSet.Unicode)] 
    public static extern uint NetShareEnum(
		[In,MarshalAs(UnmanagedType.LPWStr)] string server,
		int level,
		out IntPtr bufptr, 
		int prefmaxlen,
		ref Int32 entriesread, 
		ref Int32 totalentries, 
		ref Int32 resume_handle); 
	[DllImport("Netapi32.dll",CharSet=CharSet.Unicode)] 
    public static extern int NetApiBufferFree(IntPtr buffer); 
 
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct STAT_SERVER_0
    {
	  public uint Start;
	  public uint FOpens;
	  public uint DevOpens;
	  public uint JobsQueued;
	  public uint SOpens;
	  public uint STimedOut;
	  public uint SerrorOut;
	  public uint PWerrors;
	  public uint PermErrors;
	  public uint SysRrrors;
	  public uint bytesSent_low;
	  public uint bytesSent_high;
	  public uint bytesRcvd_low;
	  public uint BytesRcvd_high;
	  public uint AvResponse;
	  public uint ReqNufNeed;
	  public uint BigBufNeed;
    }
 
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct STAT_WORKSTATION_0
    {
	  public long StatisticsStartTime;
	  public long BytesReceived;
	  public long SmbsReceived;
	  public long PagingReadBytesRequested;
	  public long NonPagingReadBytesRequested;
	  public long CacheReadBytesRequested;
	  public long NetworkReadBytesRequested;
	  public long BytesTransmitted;
	  public long SmbsTransmitted;
	  public long PagingWriteBytesRequested;
	  public long NonPagingWriteBytesRequested;
	  public long CacheWriteBytesRequested;
	  public long NetworkWriteBytesRequested;
	  public uint InitiallyFailedOperations;
	  public uint FailedCompletionOperations;
	  public uint ReadOperations;
	  public uint RandomReadOperations;
	  public uint ReadSmbs;
	  public uint LargeReadSmbs;
	  public uint SmallReadSmbs;
	  public uint WriteOperations;
	  public uint RandomWriteOperations;
	  public uint WriteSmbs;
	  public uint LargeWriteSmbs;
	  public uint SmallWriteSmbs;
	  public uint RawReadsDenied;
	  public uint RawWritesDenied;
	  public uint NetworkErrors;
	  public uint Sessions;
	  public uint FailedSessions;
	  public uint Reconnects;
	  public uint CoreConnects;
	  public uint Lanman20Connects;
	  public uint Lanman21Connects;
	  public uint LanmanNtConnects;
	  public uint ServerDisconnects;
	  public uint HungSessions;
	  public uint UseCount;
	  public uint FailedUseCount;
	  public uint CurrentCommands;
    }
 
	[DllImport("Netapi32.dll",CharSet=CharSet.Unicode)] 
    public static extern uint NetStatisticsGet(
		[In,MarshalAs(UnmanagedType.LPWStr)] string server,
		[In,MarshalAs(UnmanagedType.LPWStr)] string service,
		int level,
		int options,
		out IntPtr bufptr); 
 
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct SESSION_INFO_0
    {
		[MarshalAs(UnmanagedType.LPWStr)] public string Name;
    }
 
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct SESSION_INFO_1
    {
		[MarshalAs(UnmanagedType.LPWStr)] public string Name;
		[MarshalAs(UnmanagedType.LPWStr)] public string Username;
		public uint NumOpens;
		public uint Time;
		public uint IdleTime;
		public uint UserFlags;
    }
 
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct SESSION_INFO_2
    {
		[MarshalAs(UnmanagedType.LPWStr)] public string Name;
		[MarshalAs(UnmanagedType.LPWStr)] public string Username;
		public uint NumOpens;
		public uint Time;
		public uint IdleTime;
		public uint UserFlags;
		[MarshalAs(UnmanagedType.LPWStr)] public string ConnectionType;
    }
 
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct SESSION_INFO_10
    {
		[MarshalAs(UnmanagedType.LPWStr)] public string Name;
		[MarshalAs(UnmanagedType.LPWStr)] public string Username;
		public uint Time;
		public uint IdleTime;
    }
 
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct SESSION_INFO_502
    {
		[MarshalAs(UnmanagedType.LPWStr)] public string Name;
		[MarshalAs(UnmanagedType.LPWStr)] public string Username;
		public uint NumOpens;
		public uint Time;
		public uint IdleTime;
		public uint UserFlags;
		[MarshalAs(UnmanagedType.LPWStr)] public string ConnectionType;
		[MarshalAs(UnmanagedType.LPWStr)] public string Transport;
    }
 
	[DllImport("Netapi32.dll",CharSet=CharSet.Unicode)] 
    public static extern uint NetSessionEnum(
		[In,MarshalAs(UnmanagedType.LPWStr)] string server,
		[In,MarshalAs(UnmanagedType.LPWStr)] string client,
		[In,MarshalAs(UnmanagedType.LPWStr)] string user,
		int level,
		out IntPtr bufptr, 
		int prefmaxlen,
		ref Int32 entriesread, 
		ref Int32 totalentries, 
		ref Int32 resume_handle); 
 
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct FILE_INFO_2
    {
		public uint FileID;
    }
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct FILE_INFO_3
    {
		public uint FileID;
		public uint Permissions;
		public uint NumLocks;
		[MarshalAs(UnmanagedType.LPWStr)] public string Path;
		[MarshalAs(UnmanagedType.LPWStr)] public string User;
    }
 
	[DllImport("Netapi32.dll",CharSet=CharSet.Unicode)] 
    public static extern uint NetFileEnum(
		[In,MarshalAs(UnmanagedType.LPWStr)] string server,
		[In,MarshalAs(UnmanagedType.LPWStr)] string path,
		[In,MarshalAs(UnmanagedType.LPWStr)] string user,
		int level,
		out IntPtr bufptr, 
		int prefmaxlen,
		ref Int32 entriesread, 
		ref Int32 totalentries, 
		ref Int32 resume_handle); 
}
"@ 
 
function Get-OpenFiles
{
	[CmdletBinding()]	
	param ( [Parameter(Position=0)][string]$server = "localhost", 
			[Parameter(Position=1)][int32]$level=3, 
			[Parameter(Position=2)][string]$user = $null, 
			[Parameter(Position=3)][string]$path = $null)
	switch ($level)
	{
		2   { $struct = New-Object netapi+FILE_INFO_2 }
		3   { $struct = New-Object netapi+FILE_INFO_3 }
		default
		{
			$level = 3
			$struct = New-Object netapi+FILE_INFO_3 
		}
	}
	$buffer = 0
	$entries = 0
	$total = 0
	$handle = 0
	$ret = [Netapi]::NetFileEnum($server, $path, $user, $level,
								  [ref]$buffer, -1,
								  [ref]$entries, [ref]$total,
								  [ref]$handle) 
 
	$files = @()
	if (!$ret)
	{
		$offset = $buffer.ToInt64()
		$increment = [System.Runtime.Interopservices.Marshal]::SizeOf([System.Type]$struct.GetType())
 
		for ($i = 0; $i -lt $entries; $i++)
		{
	        $ptr = New-Object system.Intptr -ArgumentList $offset
	        $files += [system.runtime.interopservices.marshal]::PtrToStructure($ptr, [System.Type]$struct.GetType())
 
			$offset = $ptr.ToInt64()
	        $offset += $increment
		}
	}
	else
	{
		Write-Output ([ComponentModel.Win32Exception][Int32]$ret).Message
 
		if ($ret -eq 1208)
		{
			# Error Code labeled "Extended Error" requires the buffer to be freed
			[Void][Netapi]::NetApiBufferFree($buffer)
		}
	}
	$files
}
function Get-Sessions
{
	[CmdletBinding()]	
	param ( [Parameter(Position=0)][string]$server = "localhost", 
			[Parameter(Position=1)][int32]$level=0, 
			[Parameter(Position=2)][string]$client = $null, 
			[Parameter(Position=3)][string]$user = $null)
	switch ($level)
	{
		0   { $struct = New-Object netapi+SESSION_INFO_0 }
		1   { $struct = New-Object netapi+SESSION_INFO_1 }
		2   { $struct = New-Object netapi+SESSION_INFO_2 }
		10  { $struct = New-Object netapi+SESSION_INFO_10 }
		502 { $struct = New-Object netapi+SESSION_INFO_502 }
		
		default
		{
			$level = 0
			$struct = New-Object netapi+SESSION_INFO_0 
		}
	}
 
	$buffer = 0
	$entries = 0
	$total = 0
	$handle = 0
	$ret = [Netapi]::NetSessionEnum($server, $client, $user, $level,
								  [ref]$buffer, -1,
								  [ref]$entries, [ref]$total,
								  [ref]$handle) 
 
	$sessions = @()
	if (!$ret)
	{
		$offset = $buffer.ToInt64()
		$increment = [System.Runtime.Interopservices.Marshal]::SizeOf([System.Type]$struct.GetType())
 
		for ($i = 0; $i -lt $entries; $i++)
		{
	        $ptr = New-Object system.Intptr -ArgumentList $offset
	        $sessions += [system.runtime.interopservices.marshal]::PtrToStructure($ptr, [System.Type]$struct.GetType())
 
			$offset = $ptr.ToInt64()
	        $offset += $increment
		}
		
	}
	else
	{
		Write-Output ([ComponentModel.Win32Exception][Int32]$ret).Message
 
		if ($ret -eq 1208)
		{
			# Error Code labeled "Extended Error" requires the buffer to be freed
			[Void][Netapi]::NetApiBufferFree($buffer)
		}
	}
	$sessions
}
 
function Get-Shares
{
	[CmdletBinding()]
	param ( [Parameter(Position=0)][string]$server = "localhost", 
			[Parameter(Position=1)][int32]$level=0)
	switch ($level)
	{
		0   { $struct = New-Object netapi+SHARE_INFO_0 }
		1   { $struct = New-Object netapi+SHARE_INFO_1 }
		2   { $struct = New-Object netapi+SHARE_INFO_2 }
		502 { $struct = New-Object netapi+SHARE_INFO_502 }
		503 { $struct = New-Object netapi+SHARE_INFO_503 }
		
		default
		{
			$level = 0
			$struct = New-Object netapi+SHARE_INFO_0 
		}
	}
 
	$buffer = 0
	$entries = 0
	$total = 0
	$handle = 0
	$ret = [Netapi]::NetShareEnum($server, $level,
								  [ref]$buffer, -1,
								  [ref]$entries, [ref]$total,
								  [ref]$handle) 
 
	$shares = @()
	if (!$ret)
	{
		$offset = $buffer.ToInt64()
		$increment = [System.Runtime.Interopservices.Marshal]::SizeOf([System.Type]$struct.GetType())
 
		for ($i = 0; $i -lt $entries; $i++)
		{
	        $ptr = New-Object system.Intptr -ArgumentList $offset
	        $shares += [system.runtime.interopservices.marshal]::PtrToStructure($ptr, [System.Type]$struct.GetType())
 
			$offset = $ptr.ToInt64()
	        $offset += $increment
		}
		
	}
	else
	{
		Write-Output ([ComponentModel.Win32Exception][Int32]$ret).Message
 
		if ($ret -eq 1208)
		{
			# Error Code labeled "Extended Error" requires the buffer to be freed
			[Void][Netapi]::NetApiBufferFree($buffer)
		}
	}
	$shares
}
 
function Get-NetStatistics
{
	[CmdletBinding()]
	param ( [Parameter(Position=0)][string]$server = "localhost", 
			[Parameter(Position=1)][string]$type="WORKSTATION")
 
	if ($type -eq "SERVER")
	{
		$struct = New-Object netapi+STAT_SERVER_0 
		$service = "LanmanServer"
	}
	else
	{
		$struct = New-Object netapi+STAT_WORKSTATION_0 
		$service = "LanmanWorkstation"
	}
 
	$buffer = 0
	$ret = [Netapi]::NetStatisticsGet($server,
									  $service,
									  0, # only level 0 is supported for now
									  0, #must be 0
								  	  [ref]$buffer)
 
	if (!$ret)
	{
	    $ret = [system.runtime.interopservices.marshal]::PtrToStructure($buffer, [System.Type]$struct.GetType())
            $ret
	}
	else
	{
		Write-Output ([ComponentModel.Win32Exception][Int32]$ret).Message
	}
 
}
switch ($function)
{
	"Get-NetStatistics"
	{
		Get-NetStatistics $server $type
	}
	"Get-Shares"
	{
		Get-Shares $server $level
	}
	"Get-Sessions"
	{
		Get-Sessions $server $level $client $user
	}
	"Get-OpenFiles"
	{
		Get-OpenFiles $server $level $user $path $user 
	}
	default
	{
		Get-Shares $server $level
	}
}
