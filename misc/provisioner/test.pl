#!/usr/bin/perl
use Provisioner;
use Getopt::Long;
use Text::CSV::Hashify;

my $obj = Text::CSV::Hashify->new( {
        file        => 'test.csv',
        format      => 'aoh'
    } );

my $array_ref = $obj->all;
foreach my $element (@$array_ref) {

#ROSETTA STONE FOR MAPPER FILE FIELDS
#For familiarity, the vars below match names from Brian Halls original PS script
#commented fields were not found in the test mapping file
my $Reference = $element->{REFERENCE};
#my $ProdLocation = $element->{'PROD Location'};
my $SourceSystem = $element->{'Source Prod Filer'};
my $SourceVfiler = $element->{'Source Prod Vfiler'};
my $SourceVolume = $element->{'Source Prod Volume'};
#my $SourceAggregate = $element->{'Aggregate Name'};
#my $SourceUsedCapacityGB = $element->{'Volume Total Capacity (GB)'};
#my $SourceCapacityGB = $element->{'Volume Total Capacity (GB)'};
#my $SourceUsedCapacityPercent = $element->{'Volume Used %'};
#my $AccessType = $element->{'Access Type'};
my $SecurityStyle = $element->{'Volume Security'};
#my $SourceDrLocation = $element->{'COB Location'};
my $SourceDrSystem = $element->{'Source COB Filer'};
my $SourceDrVfiler = $element->{'Source COB Vfiler'};
my $SourceDrVolume = $element->{'Source COB Volume'};
#my $TechRefresh = $element->{'Tech Refresh'};
my $TargetSystem = $element->{'Target Prod Frame'};
#my $TargetDm = $element->{'Prod Physical DataMover'};
my $TargetVdm = $element->{'Target VDM'};
#my $TargetVdmRootDir = $element->{'Root VDM Directory'};
#my $TargetQipEntry = $element->{'Prod QIP Entry'};
my $TargetIp = $element->{'IP Address'};
my $TargetInterface = $element->{'PROD Interface Name'};
#my $TargetCifsServer = $element->{'Cifs server Name'};
#my $TargetNfsServer = $element->{'nfs server Name'};
my $ThreeDNSCname = $element->{'3 DNS cname entry'};
my $TargetVolume = $element->{'Prod File System'};
my $TargetQtree = $element->{'Qtree & share name'};
#my $TargetStoragePool = $element->{'Prod Pool'};
my $LdapSetup = $element->{'Ldap setup'};
my $TargetDrSystem = $element->{'Target COB VNX Frame'};
#my $TargetDrVdm = $element->{'Target COB VDM'};
my $TargetDrIp = $element->{'Target COB IP'};

#invoke the provisioner module
my $prov = Provisioner->new(src => $SourceVfiler, dest => $TargetSystem, cob => $TargetDrSystem, debug => 1);

#Header for this row of the mapper file, just for checking output or debugging
print '#' x (length($Reference) + 2) . "\n";
print ' ' . $Reference . ' ' . "\n";
print '#' x (length($Reference) + 2) . "\n";

$prov->check_environment;
$prov->check_vdm_ldap("1","3"); #bogus numbers for testing syntax
$prov->check_dm_ldap($TargetSystem);
$prov->check_nfs_export($TargetVdm);
$prov->stop_iptables;
$prov->list_systems;
$prov->get_dm_ip($TargetSystem);
$prov->get_dm_id($TargetSystem);
$prov->create_passphrase($TargetSystem,$TargetDrSystem,"nasadmin");
$prov->get_replication_ips($TargetSystem);
#$prov->create_interconnect( );
$prov->get_dm_interfaces($TargetSystem);
$prov->create_vdm_interface($TargetVdm,$TargetInterface,$TargetIp,"255.255.255.0","0.0.0.0");
$prov->query_vdm($TargetVdm);
$prov->query_vdm_id($TargetVdm);
$prov->get_pool_info;
$prov->create_vdm_onpool($TargetVdm,$TargetVdm,"TargetStoragePool"); #repeated targetvdm just for testing, needs proper field in mapping file?
$prov->attach_vdm_interface($TargetVdm,$TargetInterface);
$prov->check_fs($TargetVolume);
$prov->check_poolspace_byid("3"); #bogus input for testing
$prov->check_poolspace_byname("deadpool" ); #bogus input for testing
$prov->create_tgt_from_emc( );
$prov->create_tgt_from_netapp($TargetVolume,$SourceVolume,$SourceSystem,"testpool");
$prov->mount_ro($TargetVdm,$TargetVolume);
$prov->mount_rw($TargetVdm,$TargetVolume);
$prov->mkdir_qtree("0","1",$TargetVdm,$TargetVolume,$TargetQtree); #bogus inputs for testing, numbers are usually derived from nas_cel queries
$prov->list_exports($TargetVdm);
$prov->create_nfs_export($TargetVdm,'127.0.0.1','10.0.0.0/8','127.0.0.1',$TargetVolume,"volpath");





print '#' x (length($Reference) + 2) . "\n\n\n";

}


__DATA__
steps(validate each step):
1-ingest file
2-stop iptables
3-create passphrase
4-create interconnect
5-create ip interface for vdm (one ip per vdm)
5a-interface name is in the mapping file (2 digits at end)
6-create vdm (name is in the mapping file)
7-use attach command to bind vdm to ip addr
8-create the filesystem
8a-path is built using 
9-check source volume size (get from mapping file?)
10-check to make sure there's available space on target
11-create volume on target (logging type is in the mapping file)
12-permissions?  replication?
13-mount volume on the vdm
14-get vdm id, physical datamover id (use them in the mkdir command)
15-cifs server creation?
16-nfs server creation?
17-join domain? prompt user for creds
18-create share (nfs or cifs) one share per volume
19-native replication(check if it's there 1st)
20-




