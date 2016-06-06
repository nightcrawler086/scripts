#from openpyxl import load_workbook

#workbook = raw_input("Path to Workbook: ")
#source_system = raw_input("Source System Name (Source Prod Box): ")
# should not need this, want to find the rows based on source_system
#cell_range = raw_input("Cell range (ex: A1:D10): ")

tgt_vdm = "citi_vdm"
tgt_dm = "server_2"
tgt_pool = "p1_NAS_R14+2_600GB_SAS_10K"
tgt_fs_name = "FS01"
tgt_ss = "uxfs"
tgt_fs_size = "300"
tgt_proto = "cifs"
dst_fs_name = "DR_FS01"







# Getting the print commands out the way

# Create VDMs
print "nas_server -name %s -type vdm -create %s -setstate loaded pool=%s" % (tgt_vdm, tgt_dm, tgt_pool)

# Create Filesystems
print "nas_fs -name %s -type %s -create size=%s pool=%s -option slice=y" % (tgt_fs_name, tgt_ss, tgt_fs_size, tgt_pool)

# Mount Filesystems
print "server_mount %s %s /%s" % (tgt_vdm, tgt_fs_name, tgt_fs_name)

# Create Qtree
print "mkdir /nasmcd/quota/slot_X/root_vdm_X/%s/%s" % (tgt_fs_name, tgt_fs_name)

# Export CIFS share
print "server_export %s -protocol %s -name %s -o netbios=%s /%s/%s" % (tgt_vdm, tgt_proto, tgt_fs_name, tgt_vdm, tgt_fs_name, tgt_fs_name)

# Replicate Filesystems
print "nas_replicate -create %s_REP -source -fs %s -destination -fs %s -interconnect ?? -max_time_out_of_sync 10 -background" % (tgt_fs_name, tgt_fs_name, dst_fs_name)

# Deduplication
print "fs_dedupe -modify %s -state on" % (tgt_fs_name)

# Checkpoint creation

print """nas_ckpt_schedule -create %s_DAILY_SCHED -filesystem %s -description "1730hrs daily ckpt schedule for %s" -recurrence daily -every 1 -starton <date> -runtimes 17:30 -keep 7""" % (tgt_fs_name, tgt_fs_name, tgt_fs_name)
