#!/usr/bin/python

import os
from multiprocessing.dummy import Pool as ThreadPool
pool = ThreadPool(4)
iprange = []

def ping(ip):
    res = os.system('ping -c 1 -W 1 ' + ip + ' > /dev/null 2>&1')
    if res == 0:
        status = "Alive"
    else:
        status = "Dead"
    return (ip, status)

def ping_range(start, end):
    ip = ('192.168.1.%d') % (i)
    iprange.append(ip)
    print(ip)

results = pool.map(ping, iprange)
print(results)

pool.close()
pool.join()
