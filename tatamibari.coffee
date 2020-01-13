# These widths must match the widths in design.pug
minorWidth = 0.05
majorWidth = 0.15

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

selected = null

class PuzzleEditor extends PuzzleDisplay
  drawSquares: ->
    @squaresGroup.clear()
    @squares = {}
    for x in [0...@puzzle.nx]
      for y in [0...@puzzle.ny]
        do (x, y) =>
          @squares[[x,y]] = square = @squaresGroup.rect 1, 1
          .move x, y
          .click click = => @select x, y
          #@puzzleNumbers[[i,j]].click click
  select: (x, y) ->
    # Selects cell (x,y) in this GUI.  Selection needs to be page-global
    # (because editing is controlled by keyboard and global buttons),
    # so we need to deselect everything in all GUIs.
    for element in document.getElementsByClassName 'selected'
      element.classList.remove 'selected'
    @squares[[x,y]].addClass 'selected'
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

designGUI = ->
  designSVG = SVG().addTo '#design'
  resultSVG = SVG().addTo '#result'
  tata = new PuzzleEditor designSVG, new Puzzle 5, 5

window?.onload = ->
  if document.getElementById 'design'
    designGUI()
