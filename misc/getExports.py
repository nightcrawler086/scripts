#!/usr/bin/python2.6

import os
import csv
import argparse
import re
import sys
from subprocess import Popen, PIPE


# Empty list to store tracker
tracker = []
# Define the argument parser
parser = argparse.ArgumentParser(description='Get export list by server:volume')
# Add an argument
parser.add_argument('-i', action="store", dest="tr")
# Parse them
args = parser.parse_args()

class myClass:

    def __init__(self, Source, Source_Filer, Source_Vfiler, Source_Volume,
            Unix_Server_Exports):
        self.Source = Source
        self.Source_Filer = Source_Filer
        self.Source_Vfiler = Source_Vfiler
        self.Source_Volume = Source_Volume
        self.Unix_Server_Exports = Unix_Server_Exports
        self.New_Unix_Server_Exports = []

    def add_exports(self, exports):
        self.New_Unix_Server_Exports.append(exports)


# Import CSV as Objects
with open((args.tr), 'r') as f:
    reader = csv.reader(f)
    for row in reader:
        tracker.append(myClass(row[0], row[1], row[2], row[3], row[4]))

#for x in range(1,9710):
#    print tracker[x].Source_Filer, tracker[x].Source_Vfiler, tracker[x].Source_Volume
# Set comprehension.  Unordered and unique
vfilers = {r.Source_Vfiler for r in tracker}

for i in vfilers:
    if not i:
        continue
    res = os.system('ping -c 1 -W 1 ' + i + ' > /dev/null')
    if res == 0:
        shmnt = Popen('showmount --no-headers -e i', shell=True, stdout=PIPE)
        slice = [obj for obj in tracker if obj.Source_Vfiler == i]
        for x in slice:
            if x.Source_Volume:
                for line in shmnt_out:
                    if x.Source_Volume in line:
                        fields = line.split()
                        x.add_exports(fields[1])
