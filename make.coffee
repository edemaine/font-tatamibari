stringify = require 'json-stringify-pretty-compact'
#stringify = JSON.stringify
fs = require 'fs'

{Puzzle, setPuzzle, solve, showSolution} = require './tatamibari.coffee'

# https://docs.google.com/spreadsheets/d/1B3w9dBaymmQC0u7Tlg8XTMUjgPsckrpohD7sailWpbE/edit#gid=0
urls = '''
A	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=....%2B....%7C%0A......%2B...%0A.%2B........%0A..%2B.-.....%0A%2B..%2B......%0A.....-.%2B..%0A.%2B%7C.......%0A.-.%2B......%0A..%2B....-..%0A%7C.........&color=11111011111110111
B	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=.....%2B...-%0A...%7C..%2B...%0A..%2B.-..%2B.%7C%0A..-.......%0A........%2B%7C%0A%2B..%2B.-....%0A..%2B....%2B.%2B%0A......-...%0A...%2B...%2B..%0A-.%2B...%2B...&color=11111011110111111011111
C	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=......-...%0A.%2B........%0A..%2B..%2B...%2B%0A....%2B...%2B.%0A...%2B......%0A.....-....%0A%7C.........%0A...-......%0A....%2B...%2B.%0A%2B....%7C.%2B..&color=1111100001111111
D	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=%7C...-..-..%0A..%2B.....%2B.%0A...%2B..%2B.%2B.%0A....%2B.....%0A..%2B.....%2B.%0A.%2B........%0A.......%7C.%2B%0A...%2B......%0A%7C.....%2B..%2B%0A..........&color=111101110111111110
E	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=%7C-......%2B.%0A.%2B.....%2B..%0A..........%0A......-...%0A.%7C...%2B.%2B..%0A..%2B.....%2B.%0A....%2B.....%0A..%2B%2B...-..%0A.%2B....-...%0A..........&color=11111011111111011
F	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=.....%2B..%2B.%0A.%2B.....%2B..%0A..%7C.......%0A.%2B..%2B.-...%0A.%7C...%7C.%2B..%0A..%2B.....%2B.%0A....%2B.....%0A%7C.%2B%2B.....%2B%0A.%2B........%0A..........&color=1111111011111111101
G	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=.........-%0A....%2B..%2B..%0A%7C..%2B..-.%2B.%0A..%7C...%2B.-.%0A.%2B.....%2B..%0A........%2B.%0A%2B......%7C..%0A.....%2B..%2B.%0A......%2B..%2B%0A.-...-....&color=111111110011110111111
H	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=..........%0A..%2B..%2B..%2B.%0A.......%2B..%0A..%2B.......%0A.%2B...-..%2B.%0A%2B..%2B..-%2B..%0A.........%7C%0A..........%0A%2B.%2B...%2B.%2B.%0A..%2B.......&color=101111111111111011
I	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=.....%2B%7C...%0A...%2B......%0A.%2B..%2B..%2B..%0A.....%7C....%0A...%2B.-..%7C.%0A....%2B.....%0A%7C.....%2B...%0A..%2B.....%2B.%0A.%2B-..%2B.%2B..%0A...-......&color=11111111101011111111
J	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=......%2B..%7C%0A....%2B..%2B..%0A.%2B...%2B%7C...%0A.......%2B..%0A...%2B......%0A.......%2B..%0A.%2B.......%2B%0A..%2B....%2B..%0A%7C.....%2B...%0A...-......&color=11010011011111111
K	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=....-.%2B...%0A.%2B..%2B...%2B.%0A....%2B%7C.%2B..%0A....%2B....%7C%0A%2B....-..%2B.%0A..%2B....%7C..%0A...-.%2B..%2B%2B%0A%7C.....%7C..-%0A..%2B.%7C.....%0A.....-..%2B.&color=00101001011101110111111001
L	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=...%2B......%0A..........%0A..%2B.....%2B.%0A...%7C......%0A.%2B........%0A..........%0A%7C...%2B.-.%2B.%0A.%2B...%2B....%0A..%2B.......%0A...%2B...-..&color=11011111111111
M	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=......%2B...%0A%2B..%2B.....-%0A....%2B.....%0A.%2B.%7C..%2B.%7C.%0A%7C....%2B....%0A..%2B.%2B...%2B.%0A.%2B.%2B....%7C.%0A......%2B..%7C%0A%2B..%2B...%2B..%0A.-...%7C..%2B.&color=0101011111111110101100111
N	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=...-......%0A.%2B....%2B...%0A..%2B.%2B....%2B%0A.....%2B.%2B..%0A.%7C......%2B.%0A..%2B.......%0A.....%2B..%2B.%0A.%2B.....%2B..%0A..%2B%7C..%2B...%0A%7C...-.....&color=01010101111111110010
O	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=.......-..%0A%2B...%2B.....%0A.%2B....%2B...%0A..%2B....%2B..%0A%7C....%2B..%2B.%0A.%2B........%0A..%7C.......%0A...%2B.-...%7C%0A.......%2B..%0A%7C...%2B....%2B&color=1111111101111111111
P	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=.%2B..-%2B...%7C%0A..%2B....%2B..%0A...%2B......%0A%2B....-..%2B.%0A....%2B..%2B..%0A.-.%2B..%2B..%7C%0A.....%7C....%0A.%2B........%0A%7C.%2B.%2B...%2B.%0A..........&color=1111111101111111011110
Qpublished	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=........-.%0A.........%7C%0A..-..%2B..%2B.%0A.%2B........%0A..........%0A%2B.%2B...%7C%2B.%2B%0A.%2B......-.%0A..%2B..%2B....%0A-..%2B....%2B.%0A.....-%2B...&color=10001110010111111101
Q	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=........-.%0A.........%7C%0A..-..%2B..%2B.%0A.%2B........%0A..........%0A%2B.%2B...%7C%2B.%2B%0A.%2B......-.%0A..%2B..%2B....%0A-..%2B....%2B.%0A%2B....-%2B...&color=100011100101111111001
R1	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=-.........%0A..%2B.%2B.%2B...%0A.%2B......%2B.%0A...%2B-..%2B..%0A..%2B.....%2B.%0A....%2B.-...%0A.....%2B...%2B%0A.%2B....%2B...%0A..........%0A......-..%7C&color=1111111011011011101
R	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=-.........%0A..%2B.%2B.%2B...%0A.%2B......%2B.%0A...%2B-..-..%0A..%2B.....%7C.%0A....%2B.-...%0A.....%2B....%0A.%2B....%2B.%2B.%0A..........%0A......-..-&color=1111111011011011101
S	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=%2B...-..-..%0A...%2B.....%2B%0A.%2B........%0A...-%7C%2B...-%0A.%2B........%0A...%2B....%2B.%0A..%2B....%2B..%0A%7C..%2B..%2B.%2B.%0A.%2B.......%2B%0A....-.....&color=1111111100111010011111
T	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=....-....-%0A%2B.....%2B...%0A...%2B.-..%2B.%0A....%2B.%7C...%0A.%2B.....-..%0A.....%2B....%0A...%7C%7C..%2B..%0A..%2B...%2B...%0A.......%2B..%0A.........%7C&color=1111111110011100100
U	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=..........%0A.%2B.....%2B..%0A.....%2B....%0A..%2B.....%2B.%0A..........%0A...-......%0A.%2B...-.%7C.%7C%0A...%2B......%0A.%2B...%2B..%2B.%0A..........&color=11011011111111
V	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=.%7C..%2B.....%0A..%2B...%2B..%2B%0A..%2B..%2B....%0A%2B...%2B..%2B..%0A.%2B.%2B..%2B...%0A.....%2B....%0A..-.%2B.....%0A%7C.......%2B.%0A.%2B...%2B....%0A.........-&color=100011010110001011111
V3	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=.%7C..%2B.....%0A..%2B...%2B..%2B%0A..%2B..%2B....%0A-...%2B..%2B..%0A...%2B..%2B...%0A-....%2B....%0A..%2B.%2B...%2B.%0A.%2B........%0A.%2B.%2B.%2B%7C..%7C%0A..-....-..&color=1000110101000010000111000
V2	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=.%7C..%2B.....%0A..%2B...%2B..%2B%0A..%2B..%2B....%0A-...%2B..%2B..%0A...%2B..%2B...%0A-....%2B....%0A..%2B.%2B...%2B.%0A.%2B........%0A.%2B.%2B.%2B...%7C%0A..-....%7C..&color=100011010100001000011011
V2simpler	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=.%7C........%0A..-......%2B%0A..%2B.......%0A-...-..%2B..%0A...%2B..%2B...%0A..........%0A..%2B.%7C...%2B.%0A..........%0A...%2B.%2B...%7C%0A.%7C-....%7C..&color=101110100100110011
Wpublished	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=.......%2B.%7C%0A.%2B.%2B..%2B...%0A.....%2B....%0A....%2B.....%0A..%7C...%7C.%2B.%0A%7C......%7C..%0A...%2B.%7C-...%0A.%2B........%0A....%2B..%2B..%0A-.....%7C..%7C&color=011000000110111111111
W	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=.......%2B.%7C%0A.%2B.%2B..%2B...%0A.....%2B....%0A....%2B.....%0A...%2B..%7C.%2B.%0A%7C.-....%7C..%0A..%7C..%7C-..%2B%0A.%2B........%0A....%2B..%2B..%0A-.....%7C..%7C&color=01100000011001111111111
X	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=..........%0A.......%2B..%0A....%2B.....%0A..%7C......-%0A.%2B....%2B...%0A...-....%2B.%0A...%2B...%2B..%0A.%2B........%0A.........%7C%0A-.%2B.....%2B.&color=101101100111111
X2	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=...%7C.%2B%2B..%7C%0A.%2B........%0A.....-....%0A%2B...%2B..%2B%2B.%0A..%2B..%2B....%0A%7C..%2B.....-%0A....%2B.%2B%2B..%0A.......%7C%2B.%0A....%2B.....%0A..%2B.-....%2B&color=101110111101010111110101
Y	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=..........%0A.%2B.....%2B..%0A....%2B.....%0A........%2B.%0A%2B....%2B%2B...%0A...%2B.....%2B%0A.-..%2B..%7C..%0A..........%0A..%2B%2B.%7C....%0A......-.%2B.&color=11011111111101110
Z	http://erikdemaine.org/fonts/tatamibari/design.html?puzzle=%2B...%2B..%7C..%0A..%2B.....%2B.%0A-....%7C....%0A...%2B....%2B.%0A.%2B...-...%7C%0A.......%2B..%0A.%2B.%2B....%2B.%0A.....-....%0A.%2B.....%2B..%0A....-.%2B..%7C&color=1111101010100110011111
'''

make = ->
  font = {}
  for line in urls.split '\n'
    continue unless line
    [letter, url] = line.split /\s+/
    continue unless letter.length == 1
    console.log letter
    match = /puzzle=(.*)&color=(.*)/.exec url
    clues = decodeURIComponent match[1]
    color = decodeURIComponent match[2]
    puzzle = Puzzle.fromAscii clues, color
    setPuzzle puzzle
    ### More compact clue/color representation deemed not worth space savings:
    cc = {}
    for xy, c of puzzle.clues
      cc[xy] = [c, puzzle.color[xy]]
    ###
    numSolutions = await solve solutions: 2
    unless numSolutions == 1
      console.log "#{numSolutions} SOLUTIONS!!"
    solution = showSolution 0
    rectangles = solution.checkSolved()
    unless rectangles?
      console.log "INVALID SOLUTION!!"
      continue
    font[letter] =
      nx: puzzle.nx
      ny: puzzle.ny
      #cc: cc
      clues: puzzle.clues
      color: puzzle.color
      rectangles: rectangles
  fs.writeFileSync 'font.js', "window.font = #{stringify font};"

make()
