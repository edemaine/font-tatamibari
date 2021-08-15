# These widths must match the widths in tatamibari.styl
minorWidth = 0.05
majorWidth = 0.15

global?.XMLHttpRequest ?= require('xmlhttprequest').XMLHttpRequest

designLink = 'http://tatamibari.csail.mit.edu:8080/design.html'
server = 'http://tatamibari.csail.mit.edu:8080/server/'

symbolMap =
  '-': 'h'
  '|': 'v'
  '+': 'p'

class Puzzle
  constructor: (@nx, @ny, @clues = {}, @color = {}, @edges = {}, @rectangles) ->
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
  ###
  @fromCC: (nx, ny, cc) ->
    clues = {}
    color = {}
    for xy, [clue, col] of cc
      clues[xy] = clue
      col[xy] = col
    new @ nx, ny, clues, color
  ###
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
            color[[x,y]] = parseInt colorString[count++]
          else
            color[[x,y]] = 1 # default for old format
    new @ (Math.max ...(line.length for line in lines)), lines.length, clues, color
  symbolId: (xy) ->
    if symbolMap[@clues[xy]]?
      symbolMap[@clues[xy]] + (@color[xy] ? 0)
    else
      undefined
  checkClue: (xy) ->
    [x, y] = xy.split(',').map (i) -> parseInt i
    ## Grow rectangle horizontally.
    xMin = x
    xMin-- until xMin == 0 or @edges[[xMin, y+0.5]]
    xMax = x+1
    xMax++ until xMax == @nx or @edges[[xMax, y+0.5]]
    width = xMax - xMin
    ## Grow rectangle vertically, checking for all or nothing edges.
    yMin = y
    until yMin == 0
      count = (1 for x in [xMin...xMax] when @edges[[x+0.5,yMin]]).length
      break if count == width
      return null unless count == 0
      yMin--
      for x in [xMin..xMax] when x not in [0, @nx]
        return null unless (x in [xMin, xMax]) == Boolean @edges[[x,yMin+0.5]]
    yMax = y+1
    until yMax == @ny
      count = (1 for x in [xMin...xMax] when @edges[[x+0.5,yMax]]).length
      break if count == width
      return null unless count == 0
      for x in [xMin..xMax] when x not in [0, @nx]
        return null unless (x in [xMin, xMax]) == Boolean @edges[[x,yMax+0.5]]
      yMax++
    height = yMax - yMin
    ## Rectangle found. Check aspect ratio vs. clue.
    clue = @clues[xy]
    return null unless (
      (width == height) == (clue == '+') and
      (width < height) == (clue == '|') and
      (width > height) == (clue == '-')
    )
    ## Correct! Return rectangle for this clue.
    x: xMin
    y: yMin
    w: width
    h: height
    c: @color[xy]
  checkSolved: ->
    rects = []
    for xy of @clues
      rect = @checkClue xy
      return null unless rect?
      rects.push rect
    rects

class PuzzleDisplay
  constructor: (@svg, @puzzle) ->
    @background = @svg.rect @puzzle.nx, @puzzle.ny
    .addClass 'background'
    @rectanglesGroup = @svg.group()
    .addClass 'rectangles'
    @gridGroup = @svg.group()
    .addClass 'grid'
    @edgesGroup = @svg.group()
    .addClass 'edges'
    @rectEdgesGroup = @svg.group()
    .addClass 'rectEdges'
    @squaresGroup = @svg.group()
    .addClass 'squares'
    @errorsGroup = @svg.group()
    .addClass 'errors'
    @drawRectangles()
    @drawGrid()
    @drawSquares()
    @drawEdges()
    @drawErrors()

  drawGrid: ->
    @gridGroup.clear()
    @background.size @puzzle.nx, @puzzle.ny
    for x in [1...@puzzle.nx]
      @gridGroup.line x, 0, x, @puzzle.ny
    for y in [1...@puzzle.ny]
      @gridGroup.line 0, y, @puzzle.nx, y
    @gridGroup.rect @puzzle.nx, @puzzle.ny
    .addClass 'border'
    @svg.viewbox
      x: 0 - majorWidth/2
      y: 0 - majorWidth/2
      width: @puzzle.nx + majorWidth
      height: @puzzle.ny + majorWidth

  drawEmptySquares: false
  drawSquares: ->
    @squaresGroup.clear()
    @squares = {}
    if @drawEmptySquares
      for x in [0...@puzzle.nx]
        for y in [0...@puzzle.ny]
          group = @squaresGroup.group().translate x, y
          @squares[[x,y]] =
            group: group
            rect: group.rect 1 - majorWidth, 1 - majorWidth
                  .move 0.5*majorWidth, 0.5*majorWidth
            use: group.use @puzzle.symbolId [x,y]
                 .size 1, 1
    else
      for xy of @puzzle.clues
        [x, y] = xy.split(',').map (i) -> parseInt i
        group = @squaresGroup.group().translate x, y
        @squares[xy] =
          group: group
          use: group.use @puzzle.symbolId xy
               .size 1, 1

  drawEdges: ->
    @lines = {}
    @edgesGroup.clear()
    for xy of @puzzle.edges
      [x, y] = xy.split(',').map (f) -> parseFloat f
      @lines[xy] = @edgesGroup
      .line Math.floor(x), Math.floor(y), Math.ceil(x), Math.ceil(y)
      .addClass 'on'

  drawRectangles: ->
    @rectanglesGroup.clear()
    for rect in @puzzle.rectangles ? []
      @rectanglesGroup.rect rect.w, rect.h
      .move rect.x, rect.y
      .addClass "r#{rect.c}"
      @rectEdgesGroup.rect rect.w, rect.h
      .move rect.x, rect.y

  drawErrors: ->
    @errorsGroup.clear()
    return unless (key for key of @puzzle.edges).length
    for x in [1...@puzzle.nx]
      for y in [1...@puzzle.ny]
        if @puzzle.edges[[x-0.5,y]] and @puzzle.edges[[x,y-0.5]] and
           @puzzle.edges[[x+0.5,y]] and @puzzle.edges[[x,y+0.5]]
          @errorsGroup.circle 0.4
          .center x, y

class PuzzleSolution extends PuzzleDisplay
  drawEmptySquares: true
  showSolved: ->
    for x in [0...@puzzle.nx]
      for y in [0...@puzzle.ny]
        @squares[[x,y]].group.attr 'class', "s#{@puzzle.color[[x,y]]}"

add = (u,v) -> [u[0] + v[0], u[1] + v[1]]
sub = (u,v) -> [u[0] - v[0], u[1] - v[1]]
perp = (v) -> [-v[1], v[0]]

edge2dir = (edge) ->
  [
    edge[0] - Math.floor edge[0]
    edge[1] - Math.floor edge[1]
  ]

class PuzzlePlayer extends PuzzleDisplay
  constructor: (...args) ->
    super ...args
    @highlightEnable()
  highlightEnable: ->
    @lines = {}
    rt2o2 = Math.sqrt(2)/2
    @highlight = @svg.rect rt2o2, rt2o2
    .center 0, 0
    .addClass 'target'
    .opacity 0
    event2coord = (e) =>
      pt = @svg.point e.clientX, e.clientY
      rotated =
        x: rt2o2 * (pt.x + pt.y)
        y: rt2o2 * (-pt.x + pt.y)
      rotated.x /= rt2o2
      rotated.y /= rt2o2
      rotated.x -= 0.5
      rotated.y -= 0.5
      rotated.x = Math.round rotated.x
      rotated.y = Math.round rotated.y
      rotated.x += 0.5
      rotated.y += 0.5
      rotated.x *= rt2o2
      rotated.y *= rt2o2
      coord = [
        0.5 * Math.round 2 * rt2o2 * (rotated.x - rotated.y)
        0.5 * Math.round 2 * rt2o2 * (rotated.x + rotated.y)
      ]
      if 0 < coord[0] < @puzzle.nx and 0 < coord[1] < @puzzle.ny
        coord
      else
        null
    @svg.mousemove (e) =>
      edge = event2coord e
      if edge?
        @highlight
        .transform
          rotate: 45
          translate: edge
        .opacity 0.333
      else
        @highlight.opacity 0
    @svg.on 'mouseleave', (e) =>
      @highlight.opacity 0
    @svg.click (e) =>
      edge = event2coord e
      return unless edge?
      @click edge
  click: (edge, links = true) ->
    if @lines[edge]?
      @lines[edge].remove()
      delete @lines[edge]
    dir = edge2dir edge
    @puzzle.edges[edge] =
      switch @puzzle.edges[edge]
        when undefined
          true
        when true
          false
        when false
          undefined
    if @puzzle.edges[edge] == false and
       not document.getElementById('connectors').checked
      @puzzle.edges[edge] = undefined
    if @puzzle.edges[edge]?
      if @puzzle.edges[edge] == false
        dir = perp dir
      p = sub edge, dir
      q = add edge, dir
      @lines[edge] = @edgesGroup.line p..., q...
      .addClass if @puzzle.edges[edge] then 'on' else 'con'
    @drawErrors()
    if solved = @puzzle.checkSolved()
      @svg.addClass 'solved'
    else
      @svg.removeClass 'solved'

    if @linked? and links
      for link in @linked when link != @
        link.click edge, false

class PuzzlePlayerEdge extends PuzzleDisplay
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
currentColor = 1

class PuzzleEditor extends PuzzlePlayerEdge
  drawEmptySquares: true
  drawSquares: ->
    super()
    @squaresGroup.addClass 'toggle'
    for x in [0...@puzzle.nx]
      for y in [0...@puzzle.ny]
        do (x, y) =>
          @squares[[x,y]].group.click => @select x, y
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
    @puzzle.color[xy] = currentColor
    @squares[xy].use.attr 'href', '#' + @puzzle.symbolId xy
    @pushState()
  toggleColor: (xy = @selected) ->
    currentColor = @puzzle.color[xy] = 1 - (@puzzle.color[xy] ? 0)
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

## API to set the puzzle to be solved via `solve`
setPuzzle = (puz) -> puzzle = puz

solve = (options = {}) -> new Promise (done) ->
  solutions = []
  solWhich = null
  if document?
    for id in ['solCount', 'solWhich']
      document.getElementById id
      .innerHTML = '?'
    document.getElementById 'result'
    .innerHTML = ''
    for id in ['solutions', 'clues', 'covers', 'corners']
      options[id] ?= document.getElementById(id).value
    options.reflex ?= document.getElementById('reflex').checked
  else
    options.solutions ?= 1
    options.clues ?= 'hard'
    options.covers ?= 'exact'
    options.corners ?= 'hard'
    options.reflex = true
  url = "#{server}?puzzle=#{encodeURIComponent puzzle.toAscii().clues}" + (
    for id in ['solutions', 'clues', 'covers', 'corners']
      "&#{id}=#{options[id]}"
  ).join('') +
  "&reflex=#{if options.reflex then 1 else 0}"
  xhr?.abort()
  xhr = new XMLHttpRequest
  xhr.open 'GET', url
  xhr.onprogress = ->
    solutions =
      for line in xhr.responseText.split '\n'
        try
          json = JSON.parse line
        catch
          continue
        if json.warn?
          document?.getElementById 'result'
          .innerHTML += "<p><b>WARNING: #{json.warn}</b></p>"
          continue
        if json.error?
          document?.getElementById 'result'
          .innerHTML += "<p><b>ERROR: #{json.error}</b></p>" +
                        "<pre>#{json.traceback}</pre>"
          continue
        json
    document?.getElementById 'solCount'
    .innerHTML = solutions.length + '?'
    showSolution 0 unless solWhich?
  xhr.onload = ->
    xhr.onprogress()
    if solutions.length == options.solutions
      document?.getElementById 'solCount'
      .innerHTML = solutions.length + '+'
    else
      document?.getElementById 'solCount'
      .innerHTML = solutions.length + '!'
    done solutions.length
  xhr.send()

# Fake server for testing.
###
solve = ->
  solutions = [
    for y in [0...puzzle.ny]
      for x in [0...puzzle.nx]
        '5' + if x == y == 2 then '+' else ''
  ]
  showSolution 0
###

resultSVG = null

showSolution = (which) ->
  return unless 0 <= which < solutions.length
  solWhich = which
  document?.getElementById 'solWhich'
  .innerHTML = which+1
  document?.getElementById 'result'
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
      clues[[x,y]] = match[2] if match[2]
  edges = {}
  for x in [0...puzzle.nx]
    for y in [0...puzzle.ny]
      if x > 0 and numbers[[x-1,y]] != numbers[[x,y]]
        edges[[x,y+0.5]] = true
      if y > 0 and numbers[[x,y-1]] != numbers[[x,y]]
        edges[[x+0.5,y]] = true
  colorMap = {}
  for xy, value of puzzle.clues when value?
    colorMap[numbers[xy]] = puzzle.color[xy]
  color = {}
  for x in [0...puzzle.nx]
    for y in [0...puzzle.ny]
      color[[x,y]] = colorMap[numbers[[x,y]]]
  solPuzzle = new Puzzle puzzle.nx, puzzle.ny, clues, color, edges
  if SVG?
    resultSVG = SVG().addTo '#result'
    new PuzzleSolution resultSVG, solPuzzle
    .showSolved()
  solPuzzle

svgPrefixId = (svg, prefix = 'N') ->
  svg.replace /\b(id\s*=\s*")([^"]*")/gi, "$1#{prefix}$2"
  .replace /\b(xlink:href\s*=\s*"#)([^"]*")/gi, "$1#{prefix}$2"

svgExplicit = (svg) ->
  explicit = SVG().addTo '#gui'
  try
    explicit.svg svgPrefixId svg.svg(), ''
    ## Expand CSS for <rect>, <line>, <circle>
    explicit.find 'rect, line, circle'
    .each ->
      style = window.getComputedStyle @node
      @css 'fill', style.fill
      @css 'stroke', style.stroke
      @css 'stroke-width', style.strokeWidth
      @css 'stroke-linecap', style.strokeLinecap
      @remove() if style.visibility == 'hidden'
    ## Expand <use> into duplicate copies with translation
    explicit.find 'use'
    .each ->
      replacement = document.getElementById @attr('xlink:href').replace /^#/, ''
      unless replacement?  # reference to non-existing object
        return @remove()
      replacement = SVG replacement
      viewbox = replacement.attr('viewBox') ? ''
      viewbox = viewbox.split /\s+/
      viewbox = (parseFloat n for n in viewbox)
      replacement = svgPrefixId replacement.svg()
      replacement = replacement.replace /<symbol\b/, '<g'
      replacement = explicit.group().svg replacement
      ## First transform according to `transform`, then translate by `x`, `y`
      #replacement.transform @transform()
      replacement.translate \
        (@attr('x') or 0) - (viewbox[0] or 0),
        (@attr('y') or 0) - (viewbox[1] or 0)
      #replacement.translate (@attr('x') or 0), (@attr('y') or 0)
      replacement.attr 'viewBox', null
      replacement.attr 'id', null
      #console.log 'replaced', @attr('xlink:href'), 'with', replacement.svg()
      @replace replacement
    ## Delete now-useless <defs>
    explicit.find 'defs'
    .each ->
      @clear()
    explicit.svg()
    ## Remove surrounding <svg>...</svg> from explicit SVG container
    .replace /^<svg[^<>]*>/, ''
    .replace /<\/svg>$/, ''
  finally
    explicit.remove()

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

  for [type, svg] in [['puz', -> designSVG], ['sol', -> resultSVG]]
    do (type, svg) ->
      document.getElementById "#{type}Download"
      .addEventListener 'click', ->
        explicit = svgExplicit svg()
        document.getElementById('download').href = URL.createObjectURL \
          new Blob [explicit], type: "image/svg+xml"
        document.getElementById('download').download = "tatamibari-#{type}.svg"
        document.getElementById('download').click()

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

fontGUI = ->
  app = new FontWebappHTML
    root: '#output'
    sizeSlider: '#size'
    charWidth: 225
    charPadding: 5
    charKern: 0
    lineKern: 22.5
    spaceWidth: 112.5
    shouldRender: (changed) ->
      changed.text
    renderChar: (char, state, parent) ->
      char = char.toUpperCase()
      letter = window.font[char]
      return unless letter?
      {nx, ny, clues, color, rectangles} = letter
      svg = SVG().addTo parent
      box = new PuzzlePlayer svg, new Puzzle nx, ny, clues, color, {}, rectangles
    linkIdenticalChars: (glyphs) ->
      glyph.linked = glyphs for glyph in glyphs

  document.getElementById('reset').addEventListener 'click', ->
    app.render()

  document.getElementById('designLink').href = designLink
  document.getElementById('designLinks').innerHTML = (
    for char of window.font
      """<a href="javascript:designOpen('#{char}')">#{char}</a>"""
  ).join ',\n'

window?.designOpen = (char) ->
  {nx, ny, clues, color} = window.font[char]
  puzzle = new Puzzle nx, ny, clues, color
  ascii = puzzle.toAscii()
  window.open designLink +
    "?puzzle=#{encodeURIComponent ascii.clues}" +
    "&color=#{encodeURIComponent ascii.color}"

window?.onload = ->
  if document.getElementById 'design'
    designGUI()
  else if document.getElementById 'output'
    fontGUI()

module?.exports = {Puzzle, setPuzzle, solve, showSolution}
