# These widths must match the widths in design.pug
minorWidth = 0.05
majorWidth = 0.15

symbolMap =
  '-': 'h'
  '|': 'v'
  '+': 'p'

class Puzzle
  constructor: (@nx, @ny, @clues = {}, @solution = {}) ->

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
  '+': '+'
  '|': '|'
  '\\': '|'
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

designGUI = ->
  designSVG = SVG().addTo '#design'
  resultSVG = SVG().addTo '#result'
  tata = new PuzzleEditor designSVG, new Puzzle 5, 5
  keyboardInput()

window?.onload = ->
  if document.getElementById 'design'
    designGUI()
