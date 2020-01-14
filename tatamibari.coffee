# These widths must match the widths in design.pug
minorWidth = 0.05
majorWidth = 0.15

server = 'http://demaine.csail.mit.edu/tatamibari/'

symbolMap =
  '-': 'h'
  '|': 'v'
  '+': 'p'

class Puzzle
  constructor: (@nx, @ny, @clues = {}, @color = {}, @edges = {}) ->
  toAscii: ->
    color = []
    clues:
      (for y in [0...@ny]
        (for x in [0...@nx]
          if @clues[[x,y]]?
            color.push @color[[x,y]] ? 0
          @clues[[x,y]] ? '.'
        ).join ''
      ).join '\n'
    color: color.join ''
  @fromAscii: (clueString, colorString) ->
    lines = clueString.split '\n'
    clues = {}
    color = {}
    count = 0
    for line, y in lines
      for char, x in line
        if char != '.'
          clues[[x,y]] = char
          if colorString?
            color[[x,y]] = colorString[count++]
          else
            color[[x,y]] = 1 # default for old format
    new @ (Math.max ...(line.length for line in lines)), lines.length, clues, color
  symbolId: (xy) ->
    if symbolMap[@clues[xy]]?
      symbolMap[@clues[xy]] + (@color[xy] ? 0)
    else
      undefined

class PuzzleDisplay
  constructor: (@svg, @puzzle) ->
    @squaresGroup = @svg.group()
    .addClass 'squares'
    @gridGroup = @svg.group()
    .addClass 'grid'
    @edgesGroup = @svg.group()
    .addClass 'edges'
    @errorsGroup = @svg.group()
    .addClass 'errors'
    @drawGrid()
    @drawSquares()
    @drawEdges()
    @drawErrors()

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
          use: group.use @puzzle.symbolId [x,y]
               .size 1, 1

  drawEdges: ->
    @edgesGroup.clear()
    for key of @puzzle.edges
      [x, y] = key.split ','
      x = parseFloat x
      y = parseFloat y
      @edgesGroup.line Math.floor(x), Math.floor(y), Math.ceil(x), Math.ceil(y)
      .addClass 'on'

  drawErrors: ->
    @errorsGroup.clear()
    for x in [1...@puzzle.nx]
      for y in [1...@puzzle.ny]
        if @puzzle.edges[[x-0.5,y]] and @puzzle.edges[[x,y-0.5]] and
           @puzzle.edges[[x+0.5,y]] and @puzzle.edges[[x,y+0.5]]
          @errorsGroup.circle 0.4
          .center x, y

class PuzzlePlayer extends PuzzleDisplay
  drawEdges: ->
    @edgesGroup.clear()
    for xi in [0...@puzzle.nx]
      for yi in [0...@puzzle.ny]
        for [x, y] in [[xi+0.5, yi], [xi, yi+0.5]] when x > 0 and y > 0
          l = @edgesGroup.line Math.floor(x), Math.floor(y), Math.ceil(x), Math.ceil(y)
          l.addClass 'on' if @puzzle.edges[[x,y]]
          t = @edgesGroup.line Math.floor(x), Math.floor(y), Math.ceil(x), Math.ceil(y)
          .addClass 'toggle'
          do (l, x, y) =>
            t.click =>
              @puzzle.edges[[x,y]] = not @puzzle.edges[[x,y]]
              if @puzzle.edges[[x,y]]
                l.addClass 'on'
              else
                l.removeClass 'on'
              @drawErrors()

selected = null

class PuzzleEditor extends PuzzlePlayer
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
  set: (xy, value) ->
    @puzzle.clues[xy] = value
    @squares[xy].use.attr 'href', '#' + @puzzle.symbolId xy
    @pushState()
  toggleColor: (xy = @selected) ->
    @puzzle.color[xy] = 1 - (@puzzle.color[xy] ? 0)
    @squares[xy].use.attr 'href', '#' + @puzzle.symbolId xy
    @pushState() if @puzzle.clues[xy]?
  pushState: ->
    ascii = puzzle.toAscii()
    history.pushState null, 'tatamibari',
      "#{document.location.pathname}" +
      "?puzzle=#{encodeURIComponent ascii.clues}" +
      "&color=#{encodeURIComponent ascii.color}"

keyMap =
  '-': '-'
  '_': '-'
  '=': '+'
  '+': '+'
  '\\': '|'
  '|': '|'
  ' ': null
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
        when 'c', 'C'
          selected.toggleColor()
        else
          stop = false
    if stop
      e.preventDefault()
      e.stopPropagation()

  for button in ['p', 'h', 'v', 'erase']
    value = null
    for symbol, char of symbolMap when char == button
      value = symbol
    do (value) ->
      document.getElementById "button-#{button}"
      ?.addEventListener 'click', (e) ->
        return unless selected?
        e.preventDefault()
        e.stopPropagation()
        selected.set selected.selected, value
  document.getElementById "button-color"
  ?.addEventListener 'click', (e) ->
    return unless selected?
    e.preventDefault()
    e.stopPropagation()
    selected.toggleColor()

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
  url = "#{server}?puzzle=#{encodeURIComponent puzzle.toAscii().clues}" + (
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
  edges = {}
  for x in [0...puzzle.nx]
    for y in [0...puzzle.ny]
      if x > 0 and numbers[[x-1,y]] != numbers[[x,y]]
        edges[[x,y+0.5]] = true
      if y > 0 and numbers[[x,y-1]] != numbers[[x,y]]
        edges[[x+0.5,y]] = true
  solPuzzle = new Puzzle puzzle.nx, puzzle.ny, clues, puzzle.color, edges
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
    if clues = getParameterByName 'puzzle'
      designSVG.clear()
      new PuzzleEditor designSVG, puzzle = Puzzle.fromAscii clues,
        getParameterByName 'color'
  load()

  document.getElementById 'reset'
  .addEventListener 'click', ->
    width = parseInt document.getElementById('width').value
    height = parseInt document.getElementById('height').value
    return if isNaN(width) or isNaN(height)
    designSVG.clear()
    new PuzzleEditor designSVG, puzzle = new Puzzle width, height
    .pushState()

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
  height = Math.max 250, window.innerHeight - offset.top
  document.getElementById(id).style.height = "#{height}px"

window?.onload = ->
  if document.getElementById 'design'
    designGUI()
