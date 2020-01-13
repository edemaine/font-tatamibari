# These widths must match the widths in design.pug
minorWidth = 0.05
majorWidth = 0.15

class Puzzle
  constructor: (@nx, @ny, @clues = {}, @solution = {}) ->

class Display
  constructor: (@svg, @puzzle) ->
    @gridGroup = @svg.group()
    .addClass 'grid'
    @drawGrid()

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

designGUI = ->
  designSVG = SVG().addTo '#design'
  resultSVG = SVG().addTo '#result'
  tata = new Display designSVG, new Puzzle 5, 5

window?.onload = ->
  if document.getElementById 'design'
    designGUI()
