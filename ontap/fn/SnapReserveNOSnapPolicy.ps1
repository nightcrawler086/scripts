# This function will get all the volumes in the cluster with Snapshot
# reserve space set and no snapshot policy.

function Get-SnapInfo {
	Get-NcVol * | Where-Object {$_.VolumeSpaceAttributes.PercentageSnapshotReserve -gt "0" -and $_.VolumeSnapshotAttributes.SnapshotPolicy -eq "none"} | Select-Object Vserver,Name,TotalSize,Used,@{Name="PercentageSnapshotReserve";Expression={$_.VolumeSpaceAttributes.PercentageSnapshotReserve -join ','}},@{Name="SnapshotPolicy";Expression={$_.VolumeSnapshotAttributes.SnapshotPolicy -join ','}}
}
