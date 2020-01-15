#!/usr/bin/python3

import itertools, json, sys, traceback
sys.stderr = sys.stdout

print('Access-Control-Allow-Origin: *')
print('Content-type: application/json')
print('')

try:
  import cgi
  import tatamibari_solver
  tatamibari_solver.warn = lambda *msg: print(json.dumps({
    'warn': ' '.join(map(str, msg))
  }))
  
  # Nice to low priority
  import os, psutil
  psutil.Process(os.getpid()).nice(10) #psutil.BELOW_NORMAL_PRIORITY_CLASS)
  
  # Limit CPU usage per call
  import resource
  resource.setrlimit(resource.RLIMIT_CPU, (60*5, 60*10)) # 5-10 minutes
  
  # Get parameters
  data = cgi.FieldStorage()
  solutions = int(data.getfirst('solutions', '2'))
  puzzleText = data.getfirst('puzzle')
  assert isinstance(puzzleText, str)
  settings = {}
  settings['clue_constraints'] = data.getfirst('clues', 'hard')
  assert settings['clue_constraints'] in ['hard', 'ignore']
  settings['cover_constraints'] = data.getfirst('covers', 'exact')
  assert settings['cover_constraints'] in ['exact', 'subset', 'superset', 'incomparable']#, 'ignore']
  settings['corner_constraints'] = data.getfirst('corners', 'hard')
  assert settings['corner_constraints'] in ['hard', 'soft', 'ignore']
  settings['reflex_three_corners'] = bool(int(data.getfirst('reflex', '0')))
  
  puzzle = tatamibari_solver.parse(puzzleText.split('\n'))
  soln_gen = tatamibari_solver.solve(puzzle, **settings)
  for i, soln in enumerate(itertools.islice(soln_gen, solutions)):
    text = tatamibari_solver.format_soln(puzzle, soln)
    print(json.dumps([line.split('\t') for line in text.split('\n')]))
    sys.stdout.flush()

except:
  print(json.dumps({
    'error': traceback.format_exc(0).split('\n')[-2],
    'traceback': traceback.format_exc(),
  }))
