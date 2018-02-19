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
       Filename      : Netapi.ps1
    Author           : Micky Balladelli micky@balladelli.com
.LINK 
    https://balladelli.com/netapi-et-powershell/
#>
[CmdletBinding()]
param ( [Parameter(Position=1)][string]$Source,
              [Parameter(Position=2)][string]$Target
)

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

		[DllImport("Netapi32.dll",CharSet=CharSet.Unicode)]
	public static extern uint NetShareDel(
			[In,MarshalAs(UnmanagedType.LPWStr)] string server,
			[In,MarshalAs(UnmanagedType.LPWStr)] string NetName,
			ref Int32 reserved);
}
"@

function Get-Shares
{
       [CmdletBinding()]
       param (
	   	[Parameter(Position=0)][string]$server = "localhost",
        [Parameter(Position=1)][int32]$level=502
	   )
       switch ($level)
       {
              0   { $struct = New-Object netapi+SHARE_INFO_0 }
              1   { $struct = New-Object netapi+SHARE_INFO_1 }
              2   { $struct = New-Object netapi+SHARE_INFO_2 }
              502 { $struct = New-Object netapi+SHARE_INFO_502 }
              503 { $struct = New-Object netapi+SHARE_INFO_503 }

              default
              {
                     $level = 502
                     $struct = New-Object netapi+SHARE_INFO_502
              }
       }
       $buffer = 0
       $entries = 0
       $total = 0
       $handle = 0
       $ret = [Netapi]::NetShareEnum($server, $level, [ref]$buffer, -1, [ref]$entries, [ref]$total, [ref]$handle)

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
function Remove-Shares
{
       [CmdletBinding()]
       param (
	   	[Parameter(Position=0)][string]$server = "localhost",
        [Parameter(Position=1)][string[]]$shares
	   )

	if (!$shares) {
		Write-Output "No shares specified."
		Exit
   }

   $shares = $shares.Split(',')

	   ForEach ($s in $shares) {
		   $res = [Netapi]::NetShareDel($server, $s, 0)

	   }

}
