# These widths must match the widths in design.pug
minorWidth = 0.05
majorWidth = 0.15

server = 'http://demaine.csail.mit.edu/tatamibari/'

symbolMap =
  '-': 'h'
  '|': 'v'
  '+': 'p'

class Puzzle
  constructor: (@nx, @ny, @clues = {}, @solution = {}) ->
  asciiClues: ->
    (for y in [0...@ny]
      (for x in [0...@nx]
        @clues[[x,y]] or ' '
      ).join ''
    ).join '\n'

class PuzzleDisplay
  constructor: (@svg, @puzzle) ->
    @squaresGroup = @svg.group()
    .addClass 'squares'
    @gridGroup = @svg.group()
    .addClass 'grid'
    @drawGrid()
    @drawSquares()

  drawGrid: ->
    @gridGroup.clear()
    for x in [1...@puzzle.nx]
      @gridGroup.line x, 0, x, @puzzle.ny
    for y in [1...@puzzle.ny]
      @gridGroup.line 0, y, @puzzle.nx, y
    for i in [0, 1] # put border on top
      @gridGroup.line i*@puzzle.nx, 0, i*@puzzle.nx, @puzzle.ny
      .addClass 'border'
      @gridGroup.line 0, i*@puzzle.ny, @puzzle.nx, i*@puzzle.ny
      .addClass 'border'
    @svg.viewbox
      x: 0 - majorWidth/2
      y: 0 - majorWidth/2
      width: @puzzle.nx + majorWidth
      height: @puzzle.ny + majorWidth

  drawSquares: ->
    @squaresGroup.clear()
    @squares = {}
    for x in [0...@puzzle.nx]
      for y in [0...@puzzle.ny]
        group = @squaresGroup.group().translate x, y
        @squares[[x,y]] =
          group: group
          use: group.use symbolMap[@puzzle.clues[[x,y]]]
               .size 1, 1

selected = null

class PuzzleEditor extends PuzzleDisplay
  drawSquares: ->
    super()
    for x in [0...@puzzle.nx]
      for y in [0...@puzzle.ny]
        square = @squares[[x,y]]
        square.rect = square.group.rect 1, 1
        .back()
        do (x, y) =>
          square.group.click click = => @select x, y
  select: (x, y) ->
    # Selects cell (x,y) in this GUI.  Selection needs to be page-global
    # (because editing is controlled by keyboard and global buttons),
    # so we need to deselect everything in all GUIs.
    for element in document.getElementsByClassName 'selected'
      element.classList.remove 'selected'
    @squares[[x,y]].group.addClass 'selected'
    @selected = [x, y]
    selected = @
  selectMove: (dx, dy) ->
    return unless @selected? and selected == @
    [x, y] = @selected
    loop
      x = (x + dx) %% @puzzle.nx
      y = (y + dy) %% @puzzle.ny
      break #if @puzzle?.cell[x][y] == 0
    @select x, y
  set: ([x, y], value) ->
    @puzzle.clues[[x,y]] = value
    @squares[[x,y]].use.attr 'href', '#' + symbolMap[value]

keyMap =
  '-': '-'
  '_': '-'
  '=': '+'
  '+': '+'
  '\\': '|'
  '|': '|'
  Delete: null
  Backspace: null

keyboardInput = ->
  window.addEventListener 'keyup', (e) ->
    return unless selected?
    stop = true
    if e.key of keyMap
      selected.set selected.selected, keyMap[e.key]
    else
      switch e.key
        when 'h', 'ArrowLeft'
          selected.selectMove -1, 0
        when 'l', 'ArrowRight'
          selected.selectMove +1, 0
        when 'j', 'ArrowDown'
          selected.selectMove 0, +1
        when 'k', 'ArrowUp'
          selected.selectMove 0, -1
        else
          stop = false
    if stop
      e.preventDefault()
      e.stopPropagation()
  #for num in [0..9]
  #  do (num) ->
  #    document.getElementById("number#{num}")?.addEventListener 'click', (e) ->
  #      return unless selected?
  #      e.preventDefault()
  #      e.stopPropagation()
  #      selected.set selected.selected, num

puzzle = null
solutions = null
solWhich = null

solve = ->
  solutions = null
  for id in ['solCount', 'solWhich']
    document.getElementById id
    .innerHTML = '?'
  document.getElementById 'result'
  .innerHTML = ''
  url = "#{server}?puzzle=#{encodeURIComponent puzzle.asciiClues()}"
  xhr = new XMLHttpRequest
  xhr.open 'GET', url
  xhr.onprogress = ->
    solutions =
      for line in xhr.response.split '\n'
        try
          json = JSON.parse line
        catch
          continue
        if json.warn?
          document.getElementById 'result'
          .innerHTML += "<p><b>WARNING: #{json.warn}</b></p>"
          continue
        if json.error?
          document.getElementById 'result'
          .innerHTML += "<p><b>ERROR: #{json.error}</b></p>" +
                        "<pre>#{json.traceback}</pre>"
          continue
        json
    document.getElementById 'solCount'
    .innerHTML = solutions.length
    showSolution 0 unless solWhich?
  xhr.send()

showSolution = (which) ->
  return unless 0 <= which < solutions.length
  solWhich = which
  document.getElementById 'solWhich'
  .innerHTML = which+1
  document.getElementById 'result'
  .innerHTML = ''
  clues = {}
  numbers = {}
  for row, y in solutions[solWhich]
    for char, x in row
      match = /^([0-9]*)([\-+| ]?)$/.exec char
      unless match?
        throw new Error "invalid key '#{char}'"
      number = parseInt match[1]
      number = undefined if isNaN number
      numbers[[x,y]] = number
      clues[[x,y]] = match[2]
  solPuzzle = new Puzzle puzzle.nx, puzzle.ny, clues, numbers
  resultSVG = SVG().addTo '#result'
  new PuzzleDisplay resultSVG, solPuzzle

designGUI = ->
  designSVG = SVG().addTo '#design'
  new PuzzleEditor designSVG, puzzle = new Puzzle 5, 5
  keyboardInput()
  document.getElementById 'solve'
  .addEventListener 'click', solve
  document.getElementById 'solPrev'
  .addEventListener 'click', ->
    showSolution solWhich - 1
  document.getElementById 'solNext'
  .addEventListener 'click', ->
    showSolution solWhich + 1

window?.onload = ->
  if document.getElementById 'design'
    designGUI()
