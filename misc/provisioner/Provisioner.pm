package Provisioner;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(check_environment check_interface check_ip check_vdm check_fs check_vdm_mount check_qtree check_nfs_export check_vdm_replication 
check_fs_replication create_interconnect get_replication_ips check_fs_dedupe get_checkpoint check_vdm_ldap check_dm_ldap 
get_cava_status check_vdm_dedupe check_export_permissions check_nsdomains check_fs_retention check_fs_size get_dm_interfaces 
check_failover check_alias create_vdm_interface query_vdm get_pool_info create_vdm_onpool attach_vdm_interface check_poolspace_byid 
check_poolspace_byname create_tgt_from_emc create_tgt_from_netapp mount_ro mount_rw query_vdm_id mkdir_qtree list_exports 
create_nfs_export logger);

#NOTE: right now we're testing the command syntax and mapping file, so return data in the subs below are commented out 

#TODO: function to ssh into the target and create the passphrase there
#TODO: function to ssh into target and validate interconnect
#TODO: check interface name against naming convention (i.e. first three letters are location, etc)
#TODO: check if iptables is running or not on each end
#TODO: find out how to get the interface name that's attached to the VDM


sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

sub check_environment {
my $self = shift;
#check if you are root
if ($<) {
print "you must run this script as root\n";
} else {
#do nothing?  
print "OK: you are running as root\n";
#TODO: before real testing, change the above statement from "print" to "die"
}

#TODO: check paths for...
#server_ldap
#server_export
#nas_cel
#nas_server
#server_ifconfig
#nas_pool
#nas_fs
#server_mount
#server_export

}

sub logger {
my ($self,$caller,$text) = @_;
print "$caller: $text\n";
}

sub check_vdm_ldap {
# Check whether LDAP is properly configured on both data mover and VDM level for respective OU information.
my ($self,$slot,$vdm) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "cat \/nas\/quota\/slot_" . $slot . "\/root_vdm_" . $vdm . "\/.etc\/ldap.conf";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#return $output;
}#end sub check_vdm_ldap


sub check_dm_ldap {
# Check whether LDAP is properly configured on data mover with  respective OU information.
my ($self,$server) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "server_ldap" . $server . " -info -all";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#return $output;
}#end sub check_dm_ldap

sub check_nfs_export {
my ($self,$vdm) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "server_export " . $vdm . " -P nfs -list -all";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);

}#end sub check_nfs_export

sub stop_iptables {
my $self=shift;
my $this_sub = (caller(0))[3];
#maybe remove sudo since we're running as root?
my $cmd = "sudo /sbin/service iptables stop"; 
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#`$cmd`;
#my $ret = $?;
#return ($ret)
}#end sub stop_iptables

sub list_systems {
my $self=shift;
my $this_sub = (caller(0))[3];
my $cmd = `nas_cel -query:Name=*`;
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}

# get local or remote IP address by system name #
sub get_dm_ip {
my ($self,$dmname) = @_;
my $this_sub = (caller(0))[3];
my $cmd  = "nas_cel -query:Name==$dmname -Format:\'\%s\' -Fields:NetPath";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}#end sub get_dm_ip

# Get local or remote system ID by system name #
sub get_dm_id {
my ($self,$dmname) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "nas_cel -query:Name==$dmname -Format:\'\%s\' -Fields:ID";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}#end sub get_dm_id

#Create passphrase to be used between target and DR systems
sub create_passphrase {
my ($self,$src,$srcip,$pass) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "nas_cel -create $src -ip $srcip -passphrase $pass";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}#end sub create_passphrase


sub get_replication_ips {
# To get replication IP addresses
my ($self,$dm) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "nas_server -query:$dm -Format:\'\%q\' -Fields:IfConfigTable -query:Name=R01 -Format:\'\%s\' -Fields:Address";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}

sub create_interconnect {
my ($self,$interconnect,$srcdm,$tgtsystem,$tgtdm,$srcip,$tgtip) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "nas_cel -interconnect -create " . $interconnect . " -source_server" . $srcdm . " -destination_system " .
$tgtsystem . " -destination_server " . $tgtdm . " -source_interfaces ip=" . $srcip . " -destination_interfaces ip=" . $tgtip;
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}

sub get_dm_interfaces {
# Get all interfaces (for CIFS, NFS, or Multiprotocol) from the DataMover
my ($self,$dm) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "nas_server -query:Name==$dm -Format:\'\%q\' -Fields:IfConfigTable -query:* -Format:\'\%s,\' -Fields:Name";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}

sub create_vdm_interface {
my ($self,$dm,$interface,$ip,$netmask,$bcast) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "server_ifconfig $dm -create -Device fsn0 -name $interface -protocol IP $ip $netmask $bcast";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}

sub query_vdm {
#check if vdm already exists
my ($self,$vdm) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "nas_server -query:Name==$vdm";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}

sub query_vdm_id {
my ($self,$vdm) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "nas_server -query:Name==$vdm -Format:\'\%s\' -Fields:ID";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}

sub get_pool_info {
# Get Pool Name/Id
my $this_sub = (caller(0))[3];
my $cmd = "nas_pool -query:IsInUse==True,Status==ok,IsPoolBased=True -Format:\'\%s,\%s\' -Fields:Name,ID";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}


sub create_vdm_onpool {
my ($self,$vdmname,$vdm,$poolname) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "nas_server -name $vdmname -type vdm -create $vdm -setstate loaded pool=$poolname";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}


sub attach_vdm_interface {
my ($self,$vdmname,$interfacename) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "nas_server -vdm $vdmname -attach $interfacename";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}

sub check_fs {
my ($self,$fsname) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "nas_fs -query:Name==$fsname";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}

sub check_poolspace_byid {
my ($self,$poolid) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "nas_pool -query:ID==$poolid -Format:\'\%d,\%d\' -Fields:AvailableMB,PotentialMB";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}

sub check_poolspace_byname {
my ($self,$poolname) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "nas_pool -query:Name==$poolname -Format:\'\%d,\%d\' -Fields:AvailableMB,PotentialMB";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}

sub create_tgt_from_emc {
my ($self,$fsname,$srcfs,$srcsystem,$pool) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "nas_fs -name $fsname -create samesize=$srcfs:cel=$srcsystem pool=$pool log_type=common -option slice=y";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}

sub create_tgt_from_netapp {
my ($self,$fsname,$size,$unit,$pool) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "nas_fs -name $fsname -type uxfs -create size=$size$unit pool=$pool -option slice=y";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}

sub mount_ro {
my ($self,$vdmname,$fsname) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "server_mount $vdmname -o ro $fsname /$fsname";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}

sub mount_rw {
my ($self,$vdmname,$fsname) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "server_mount $vdmname -o rw $fsname /$fsname";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}

sub mkdir_qtree {
my ($self,$dmnum,$vdmid,$fsname,$qtreename) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "mkdir /nasmcd/quote/slot_$dmnum/root_vdm_$vdmid/$fsname/$qtreename";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}

sub list_exports {
my ($self,$vdmname) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "nas_server -query:Name==$vdmname -Format:\'\%q\' -Fields:Exports -query:IsShare==False -Format:\'\%s,\' -Fields:Path";
#Will return: `/volume1/qtree1,/volume2/qtree2,/volume3/qtree3` or something like it
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}

sub create_nfs_export {
my ($self,$vdmname,$rwhosts,$rohosts,$roothosts,$vol,$path) = @_;
my $this_sub = (caller(0))[3];
my $cmd = "server_export $vdmname -Protocol nfs -Name -o rw=$rwhosts,ro=$rohosts,root=$roothosts /$vol/$path";
$self->logger($this_sub,$cmd) if ($self->{debug} == 1);
#my $output = `$cmd`;
#my $ret = $?;
#return ($output,$ret);
}

1;


__DATA__
