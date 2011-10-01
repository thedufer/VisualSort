class VisualArray
  constructor: (@canvas) ->
    @ctx = canvas.getContext('2d')
    @height = 200
    @pxWidth = 800
    @maxLength = @pxWidth / 2
    @minLength = 3
    @stepLength = 50
    @maxRandom = Math.pow(2,10)
    @animationQueue = []
    @working = false
    @stop = false
    @quickHighlight = true
    @quickCompare = true
    @colors = {
      normal: "rgb(0,0,0)"
      swap: "rgb(255, 0, 0)"
      highlight: "rgb(0,255,0)"
      persistHighlight: "rgb(0,127,0)"
      compare: "rgb(127,0,200)"
      insert: "rgb(0,0,255)"
      slide: "rgb(127,127,255)"
    }

  setLength: (length) =>
    if @working
      return
    @length = Math.max @minLength, Math.min @maxLength, length
    @values = (Math.floor(Math.random() * @maxRandom) for x in [1..@length]).sort((a,b)->a-b)
    lastVal = null
    @maxIndex = 1
    @indices = _.map(@values, ((a) -> ++@maxIndex if a != lastVal; lastVal = a; @maxIndex), this)
    @barWidth = 1
    while @pxWidth / @barWidth / 2 > @length
      @barWidth++

  scale: (value) =>
    @height / @maxIndex * value

  ###
  # Draw the line at the specified index.
  # @param {number} index the index to draw
  # @param {boolean} markForRedraw false if it doesn't need a redraw next time.
  ###
  drawIndex: (index, markForRedraw = true) =>
    @markedForRedraw.push index if markForRedraw
    @ctx.fillRect(2 * index * @barWidth, @height - @scale(@animationIndices[index]), @barWidth, @scale(@animationIndices[index]))

  ###
  # Redraw a part of the canvas.
  # @param {array[number]} range array of the indices to redraw. It must
  #   represent a range.
  ###
  redrawParts: (range) ->
    @ctx.clearRect(2 * _.first(range) * @barWidth, 0, 2 * range.length * @barWidth, @height)
    @ctx.fillStyle = @colors.normal
    for index in range
      @drawIndex(index, false)

  ###
  # Redraw the persistent highlight.
  ###
  redrawPersistentHighlight: ->
    @ctx.fillStyle = @colors.persistHighlight
    for index in @currentHighlight
      @drawIndex(index, false)

  ###
  # Redraw the parts of the canvas which were recently colorized.
  ###
  redrawIfNeeded: ->
    if @markedForRedraw.length
      for range in @markedForRedraw
        if !$.isArray range
          range = [range]
        @redrawParts range
    @redrawPersistentHighlight()
    @markedForRedraw = []

  ###
  # Redraw all of the canvas.
  ###
  redraw: =>
    @redrawParts [0...@length]
    @redrawPersistentHighlight()

  shuffle: =>
    # Fisher-Yates shuffle
    for i in [@length-1..1]
      j = Math.floor(Math.random() * (i+1))
      [@values[i], @values[j]] = [@values[j], @values[i]]
      [@indices[i], @indices[j]] = [@indices[j], @indices[i]]

  sort: =>
    @values.sort (a, b) => a - b
    @indices.sort (a, b) => a - b

  reverse: =>
    @values.reverse()
    @indices.reverse()

  animationQueuePush: (dict) =>
    dict.swaps = @swaps
    dict.inserts = @inserts
    dict.shifts = @shifts
    dict.compares = @compares
    dict.locals = _.extend {}, @locals
    @animationQueue.push dict

  ###
  # Check that the specified indices are in the range of the @values indices.
  # @param {string} methodName The name of the method, for a useful error.
  # @param {array[integer]} indices The list of indices to check.
  # @throws {Error} if an indice was out of range.
  ###
  checkIndexes: (methodName, indices) ->
    for indice, i in indices
      throw new Error("#{methodName}, argument #{i+1} : #{indice} is not a valid index") if not (0 <= indice < @values.length)

  swap: (i, j) =>
    @checkIndexes("swap", [i, j])
    @swaps++
    if i == j
      return
    @animationQueuePush(type: "swap", i: i, j: j)
    [@values[i], @values[j]] = [@values[j], @values[i]]
    [@indices[i], @indices[j]] = [@indices[j], @indices[i]]

  insert: (i, j) =>
    @checkIndexes("insert", [i, j])
    @inserts++
    @shifts += Math.abs(j - i)
    if i == j
      return
    @animationQueuePush(type: "insert", i: i, j: j)
    [tmp] = @values.splice i, 1
    @values.splice j, 0, tmp
    [tmp] = @indices.splice i, 1
    @indices.splice j, 0, tmp

  eq: (i, j) =>
    @checkIndexes("eq", [i, j])
    @compares++
    @animationQueuePush(type: "compare", i: i, j: j)
    @values[i] == @values[j]

  neq: (i, j) =>
    @checkIndexes("neq", [i, j])
    @compares++
    @animationQueuePush(type: "compare", i: i, j: j)
    @values[i] != @values[j]

  lt: (i, j) =>
    @checkIndexes("lt", [i, j])
    @compares++
    @animationQueuePush(type: "compare", i: i, j: j)
    @values[i] < @values[j]

  gt: (i, j) =>
    @checkIndexes("gt", [i, j])
    @compares++
    @animationQueuePush(type: "compare", i: i, j: j)
    @values[i] > @values[j]

  lte: (i, j) =>
    @checkIndexes("lte", [i, j])
    @compares++
    @animationQueuePush(type: "compare", i: i, j: j)
    @values[i] <= @values[j]

  gte: (i, j) =>
    @checkIndexes("gte", [i, j])
    @compares++
    @animationQueuePush(type: "compare", i: i, j: j)
    @values[i] >= @values[j]

  highlight: (indices) =>
    if !$.isArray indices
      indices = [indices]
    @checkIndexes("highlight", indices)
    @animationQueuePush(type: "highlight", indices: indices)

  persistHighlight: (indices) =>
    if !$.isArray indices
      indices = [indices]
    @checkIndexes("persistHighlight", indices)
    @animationQueuePush(type: "persistHighlight", indices: indices)

  saveInitialState: =>
    @animationValues = @values.slice()
    @animationIndices = @indices.slice()
    @locals = {}
    @swaps = 0
    @inserts = 0
    @shifts = 0
    @compares = 0
    @currentHighlight = []
    ###
    # List of indices or ranges which has been modified/colorized during the
    # current step. They will be redrawn on the next step.
    ###
    @markedForRedraw = []

  starting: =>
    @working = true

  get: (index) =>
    @values[index]

  play: =>
    if @stepLength > 0
      @playStep()
    else
      @working = false
      @animationQueue = []
      @animationValues = @values.slice()
      @animationIndices = @indices.slice()
      @redraw()

  ###
  # Placeholders to fill in with data/stats.
  # They don't change, calculate them once.
  ###
  domStats:
    swaps: $("#js-swaps")
    inserts: $("#js-inserts")
    shifts: $("#js-shifts")
    compares: $("#js-compares")
    result: $("#js-result")

  playStep: =>
    step = @animationQueue.shift()
    if step?
      @domStats.swaps.html(step.swaps)
      @domStats.inserts.html(step.inserts)
      @domStats.shifts.html(if step.inserts then Math.floor(step.shifts / step.inserts) else 0)
      @domStats.compares.html(step.compares)
      localsString = ""
      for k, v of step.locals
        localsString += "#{k}: #{v}<br />"
      @domStats.result.html(localsString)
    if !step? || @stop
      $("#js-stop").hide()
      $("#js-run").show()
      @stop = false
      @working = false
      @animationQueue = []
      @values = @animationValues.slice()
      @indices = @animationIndices.slice()
      @currentHighlight = []
      @markedForRedraw = []
      @redraw()
      return
    else if step.type == "swap"
      @redrawIfNeeded()
      @ctx.fillStyle = @colors.swap
      @drawIndex(step.i)
      @drawIndex(step.j)
      setTimeout =>
        [@animationValues[step.i], @animationValues[step.j]] = [@animationValues[step.j], @animationValues[step.i]]
        [@animationIndices[step.i], @animationIndices[step.j]] = [@animationIndices[step.j], @animationIndices[step.i]]
        @redrawIfNeeded()
        @ctx.fillStyle = @colors.swap
        @drawIndex(step.i)
        @drawIndex(step.j)
        setTimeout @play, @stepLength
      , @stepLength
    else if step.type == "highlight"
      @redrawIfNeeded()
      @ctx.fillStyle = @colors.highlight
      for index in step.indices
        @drawIndex(index)
      setTimeout @play, if @quickHighlight then @stepLength / 10 else @stepLength
    else if step.type == "persistHighlight"
      # mark previous highlighted items for redraw (to remove the highlight)
      @markedForRedraw = _.uniq @markedForRedraw.concat @currentHighlight
      @currentHighlight = step.indices
      setTimeout @play, 0
    else if step.type == "compare"
      @redrawIfNeeded()
      @ctx.fillStyle = @colors.compare
      @drawIndex(step.i)
      @drawIndex(step.j)
      setTimeout @play, if @quickCompare then @stepLength / 10 else @stepLength
    else if step.type == "insert"
      if step.i < step.j
        slideRange = [step.i..step.j]
      else
        slideRange = [step.j..step.i]
      @redrawIfNeeded()
      @ctx.fillStyle = @colors.slide
      for x in slideRange
        @drawIndex(x, false)
      @markedForRedraw.push slideRange
      @ctx.fillStyle = @colors.insert
      @drawIndex(step.i)
      setTimeout =>
        [tmp] = @animationValues.splice step.i, 1
        @animationValues.splice step.j, 0, tmp
        [tmp] = @animationIndices.splice step.i, 1
        @animationIndices.splice step.j, 0, tmp
        @redrawIfNeeded()
        @ctx.fillStyle = @colors.slide
        for x in slideRange
          @drawIndex(x, false)
        @markedForRedraw.push slideRange
        @ctx.fillStyle = @colors.insert
        @drawIndex(step.j)
        setTimeout @play, @stepLength
      , @stepLength
    else
      setTimeout @play, @stepLength

# export the VisualArray class.
@VisualArray = VisualArray
