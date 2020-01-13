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
        @clues[[x,y]] or '.'
      ).join ''
    ).join '\n'
  @asciiCluesLoad: (ascii) ->
    lines = ascii.split '\n'
    clues = {}
    for line, y in lines
      for char, x in line
        if char != '.'
          clues[[x,y]] = char
    new @ (Math.max ...(line.length for line in lines)), lines.length, clues

class PuzzleDisplay
  constructor: (@svg, @puzzle) ->
    @squaresGroup = @svg.group()
    .addClass 'squares'
    @gridGroup = @svg.group()
    .addClass 'grid'
    @edgesGroup = @svg.group()
    .addClass 'edges'
    @drawGrid()
    @drawSquares()
    @drawEdges()

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

  drawEdges: ->
    @edgesGroup.clear()
    for x in [0...@puzzle.nx]
      for y in [0...@puzzle.ny]
        if x > 0 and @puzzle.solution[[x-1,y]] != @puzzle.solution[[x,y]]
          @edgesGroup.line x, y, x, y+1
        if y > 0 and @puzzle.solution[[x,y-1]] != @puzzle.solution[[x,y]]
          @edgesGroup.line x, y, x+1, y

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
    history.pushState null, 'tatamibari',
      "#{document.location.pathname}?puzzle=#{encodeURIComponent puzzle.asciiClues()}"

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
xhr = null

solve = ->
  solutions = []
  solWhich = null
  for id in ['solCount', 'solWhich']
    document.getElementById id
    .innerHTML = '?'
  document.getElementById 'result'
  .innerHTML = ''
  maxSolutions = parseInt document.getElementById('solutions').value
  url = "#{server}?puzzle=#{encodeURIComponent puzzle.asciiClues()}" + (
    for id in ['solutions', 'clues', 'cover', 'corners']
      "&#{id}=#{document.getElementById(id).value}"
  ).join('') +
  "&reflex=#{if document.getElementById('reflex').checked then 1 else 0}"
  xhr?.abort()
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
    .innerHTML = solutions.length + '?'
    showSolution 0 unless solWhich?
  xhr.onload = ->
    if solutions.length == maxSolutions
      document.getElementById 'solCount'
      .innerHTML = solutions.length + '+'
    else
      document.getElementById 'solCount'
      .innerHTML = solutions.length + '!'
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
  new PuzzleEditor designSVG, puzzle = new Puzzle 10, 10
  keyboardInput()
  document.getElementById 'solve'
  .addEventListener 'click', solve
  document.getElementById 'solPrev'
  .addEventListener 'click', ->
    showSolution solWhich - 1
  document.getElementById 'solNext'
  .addEventListener 'click', ->
    showSolution solWhich + 1
  window.addEventListener 'resize', resizer = ->
    resize 'design'
    document.getElementById('result').style.height =
      document.getElementById('design').style.height
  resizer()

  window.addEventListener 'popstate', load = ->
    if data = getParameterByName 'puzzle'
      designSVG.clear()
      new PuzzleEditor designSVG, puzzle = Puzzle.asciiCluesLoad data
  load()

getParameterByName = (name) ->
  name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]")
  regex = new RegExp "[\\?&]" + name + "=([^&#]*)"
  results = regex.exec location.search
  if results == null
    null
  else
    decodeURIComponent results[1].replace(/\+/g, " ")

resize = (id) ->
  offset = document.getElementById(id).getBoundingClientRect()
  height = Math.max 100, window.innerHeight - offset.top
  document.getElementById(id).style.height = "#{height}px"

window?.onload = ->
  if document.getElementById 'design'
    designGUI()
