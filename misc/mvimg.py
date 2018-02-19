#!/usr/bin/python

import os
import sys
import platform
#from multiprocessing.dummy import Pool as ThreadPool
import fnmatch
from datetime import datetime


# Walk the tree and find all image files
# get total size?
#
# Sort files into folder according to their creation time
#
# Identify duplicate file names?



# If no directory passed, use current path
rootPath = '.'
pattern = '*.sh'
images = ['*.jpg', '*.JPG', '*.jpeg', '*.IMG', "*.RAW"]
total = 0
matches = []

startTime = datetime.now()
for root, dirnames, filenames in os.walk(rootPath):
    for extensions in images:
        for filename in fnmatch.filter(filenames, extensions):
            matches.append(os.path.join(root,filename))

for f in matches:
    size = os.stat(f).st_size
    total = total + size

print total / 1024 / 1024 / 1024, "GB"
print "Duration:", datetime.now() - startTime
