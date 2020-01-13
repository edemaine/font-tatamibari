#!/usr/bin/python3
import cgi, cgitb
cgitb.enable()
import tatamibari_solver

print('Access-Control-Allow-Origin: *')
print('Content-type: application/json')
print('')

# Nice to low priority
import os, psutil
psutil.Process(os.getpid()).nice(10) #psutil.BELOW_NORMAL_PRIORITY_CLASS)

# Limit CPU usage per call
import resource
resource.setrlimit(resource.RLIMIT_CPU, (60*5, 60*10)) # 5-10 minutes

# Get parameters
data = cgi.FieldStorage()
solutions = int(data.getfirst('solutions', '2'))
puzzle = data.getfirst('puzzle')
clues = data.getfirst('clues', 'hard')
assert clues in ['hard', 'ignore']
covers = data.getfirst('covers', 'exact')
assert covers in ['exact', 'subset', 'superset', 'incomparable', 'ignore']
corners = data.getfirst('corners', 'hard')
assert corners in ['hard', 'soft', 'ignore']
reflex_corners = bool(int(data.getfirst('reflex_corners', '0')))

import sys, time
for i in range(10):
  sys.stdout.flush()
  time.sleep(1)
  print('{"round": '+str(i)+'}')
