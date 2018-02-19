#!/usr/bin/env python

import os
import csv
import sys
import naslib

# Empty variable to store our mapping file as a dictionary
mapfile = []

# Importing CSV file as dicitonary
with open('mapfile.csv'. r) as f:
    reader = csv.reader(f)
    for row in reader:
        mapfile.append({'src_sys': row[0], 'src_vfiler': row[1], 'src_vol': row[2],
            })
