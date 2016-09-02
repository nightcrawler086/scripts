#!/usr/bin/python
import os
import pandas as pd
import json
import argparse
from chardet.universaldetector import UniversalDetector

__author__ = 'nightcrawler'

# Define our arguments
parser = argparse.ArgumentParser(description='Create VNX provisioning script from input file')
parser.add_argument('-i','--input-file',help='Input file name',required=True)
parser.add_argument('-o','--out-format',help='Output file format',required=False)
parser.add_argument('-s','--source-system',help='Source system',required=False)
args = parser.parse_args()

# Get file extension to detect input file type
input_file, input_file_ext = os.path.splitext(args.input_file)

# Print arguments to make sure they work
print ("Input file: %s" % args.input_file)
print ("Output format: %s" % args.out_format)
print ("Source system: %s" % args.source_system)
print ("File Extension: %s" % input_file_ext)

# Import modules that we need based on input file 
if input_file_ext == '.xlsx':
    print("Detected Excel input file")
    xlsx = pd.ExcelFile(args.input_file)
    sheet = pd.read_excel(xlsx, sheetname='Remote_Sites_Mapping')
    # This really isn't necessary, just cleaner for output
    rename_columns = sheet.rename(columns={'PROD Location': 'SourceLocation', 
        'Source Prod Box': 'SourceSystem', 'Source COB Location': 'SourceDrLocation', 
        'Source COB Box': 'SourceDrSystem', 'Source Filesystem': 'SourceFilesystem',
        'Source Qtree/Directory': 'SourceQtree', 'Source PROD Capacity (GB)': 'SourceCapacityGB',
        'Source PROD Physical Data Mover': 'SourceDm', 'Source PROD Virtual Data Mover': 'SourceVdm',
        'Source CIFS SERVER': 'SourceCifsServer', 'Replications': 'Replicated',
        'COB Capacity (GB)': 'SourceDrCapacityGB', 'COB Virtual Data Mover': 'SourceDrVdm',
        'Security Style': 'SecurityStyle', 'Protocol (NFS/CIFS/BOTH)': 'SourceProtocol',
        'Type of Data(APP/USER/BOTH)': 'SourceDataType', 'Target Prod VNX Frame': 'TargetSystem',
        'Target Prod Physical DataMover': 'TargetDm', 'Target Virtual DataMover': 'TargetVdm',
        'Prod QIP Entry': 'TargetQip', 'Prod IP': 'TargetIp',
        'Target Cifs server Name': 'TargetCifsServer', 'Target NFS server Name': 'TargetNfsServer',
        '3 DNS cname entry': '3dnsCname', 'Type of Data (APP/USER/BOTH)': 'TargetDataType',
        'Target Prod Pool': 'TargetStoragePool', 'Ldap setup': 'Ldap',
        'Target Cob VNX Frame': 'TargetDrSystem', 'Target COB Physical Data Mover': 'TargetDrDm',
        'Cob QIP Entry': 'TargetDrQip', 'Cob IP': 'TargetDrIp', 
        'Target Cob File System': 'TargetDrFilesystem', 'Target COB Capacity (GB)': 'TargetDrCapacityGB',
        'Target Cob Pool': 'TargetDrStoragePool', '3DNS setup': '3dnsSetup', 
        '3DNS Setup Request (2 weeks Lead Time)LB# and DNS#': '3dnsSetupRequest',
        'VPN request(it should be done by SA based on new prod IP and COB IP)YES/NO': 'VPN',
        'New Tape Policy Name Required': 'NewTapePolicy', 'Comments': 'Comments'})
elif input_file_ext == '.csv':
    print("Detected CSV input file")
    csv_file = pd.read_csv(args.input_file)
    # All these work:
    #print(csv_file.SourceSystem)
    #uniq = set(csv_file.SourceSystem)
    #print(uniq)
else:
    print "Could not detect input file type..exiting"
    quit()

#newdf = sheetrn[(sheetrn['SourceSystem']=='nasflr01cs0') & (sheetrn['TargetSystem']=='flrctinasv5150x')]
#print(newdf.TargetSystem)
# This works for sorting rows by multiple values
# Just need to populate the values programatically 
#uniq = sheetrn[(sheetrn['SourceSystem']=='nastam02cs0')]
#multi_uniq = sheetrn[(sheetrn['SourceSystem']=='nastam02cs0') & (sheetrn['TargetSystem']=='tamctinasv5151x')]
#print (len(uniq.index))
#print (len(multi_uniq.index))

# This doesn't actually work like I thought..only unique for one column
#uniq = pd.unique(sheetrn[['SourceSystem', 'TargetSystem']].values.ravel())
#print(uniq)

#print(tgtsys)


# This works for replacing 'N/A' values with None
# This is iterating through all cells
for cell in sheetrn.columns.values:
    sheetrn[cell] = sheetrn[cell].replace('N/A', 'None')
# This works for replace null values with None
sheetrn = sheetrn.where((pd.notnull(sheetrn)), None)


tgtsys = list(set(sheetrn.TargetSystem))

output = []

for sys in tgtsys:
    subset = sheetrn[(sheetrn['TargetSystem']==sys)]
    uniq_subset = subset.drop_duplicates(subset=['TargetVdm'])
    for index, row in uniq_subset.iterrows():
        if (row.TargetVdm != None and \
            row.TargetDm != None and \
            row.TargetStoragePool != None):
             cmdstr = "nas_server -name %s -type vdm %s -setstate loaded pool=%s" % (row.TargetVdm, row.TargetDm, row.TargetStoragePool)
             output.append({'SourceSystem': row.SourceSystem, 
                        'TargetSystem': row.TargetSystem, 
                        'CommandType': 'prdVdmCreate', 
                        'CommandString': cmdstr})
        if (row.TargetDm != None and \
            row.TargetIp != None):
             cmdstr = "server_ifconfig %s -create -Device fsn0 -name <INT_NAME> -protocol IP %s <MASK> <BROADCAST>" % (row.TargetDm, row.TargetIp)
             output.append({'SourceSystem': row.SourceSystem, 
                        'TargetSystem': row.TargetSystem, 
                        'CommandType': 'prdIntCreate', 
                        'CommandString': cmdstr})
        print(output)
    #uniqsrc = list(set(row.SourceSystem))
    #print(uniqsrc, sys)
#print(sheetrn)
# test some json output
# This works
#sheetrn.to_json('test.json')


