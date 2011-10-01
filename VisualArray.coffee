###
# Represent an element in the to-be-sorted array.
# It has two attributes :
# - value : the value of the element. It's a float.
# - norm  : an integer representing the distance from the lowest value in the array.
###
class Element
  constructor: (value, norm) ->
    if value?
      value = parseFloat value
      throw new Error("#{value} is not a float") if isNaN value
      @value = value

    if norm?
      norm = parseFloat norm
      throw new Error("#{norm} is not a float") if isNaN norm
      @norm = norm

  toString: ->
    "{value:#{@value}, norm:#{@norm}}"

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
    ###
    # Use a convenient norm to draw the bars. When the array is sorted, each
    # bar is at 0 or 1 from the next/previous bar.
    # Without, the natural norm is used.
    ###
    @normalizeBars = true
    ###
    # When the bars aren't normalized, show the level 0 even if is far from the
    # current values.
    # If false, center the canvas on min - max.
    ###
    @alwaysShowLevelZero = false
    @colors = {
      normal: "rgb(0,0,0)"
      swap: "rgb(255, 0, 0)"
      highlight: "rgb(0,255,0)"
      persistHighlight: "rgb(0,127,0)"
      compare: "rgb(127,0,200)"
      insert: "rgb(0,0,255)"
      slide: "rgb(127,127,255)"
    }

  ###
  # Generate and set an array of random values of the specified length.
  # If the length is out the min/max, it will be automatically changed.
  # @param {integer} length The length of the array.
  ###
  generateValues: (length) =>
    if @working
      return
    length = Math.max @minLength, Math.min @maxLength, length
    @setValues (Math.floor(Math.random() * @maxRandom) for x in [1..length])

  ###
  # Set the values to sort, and calculate the norm of the elements.
  # @param {array[number]} values The new list of values.
  # @throws {Error} If an item in the array is not a number.
  # @throws {Error} If the array is too short or too long.
  ###
  setValues: (values) ->
    if @working
      return
    if !(@minLength <= values.length <= @maxLength)
      throw new Error("there must be between #{@minLength} and #{@maxLength} items, not #{values.length}")
    @values = (new Element(value) for value in values)
    @length = @values.length
    # sort a new array, leaving the array "values" in the same order
    sortedValues = @values.slice().sort((a, b) -> a.value - b.value)
    lastVal = null
    @maxNorm = 0
    @minValue = _.first(sortedValues).value
    @maxValue = _.last(sortedValues).value
    for a in sortedValues
      ++@maxNorm if a.value != lastVal
      lastVal = a.value
      a.norm = @maxNorm
    @barWidth = (Math.floor @pxWidth / @length / 2) or 1

  ###
  # Determine how to fit the value in the canvas.
  # @param {number} value The value to fit in.
  # @returns {object} How to place the bar :
  #   - y : the offset to use from the top
  #   - length : the length of the bar
  ###
  scale: (value) =>
    if @normalizeBars
      # this is the same algorithm as the not-normalized branch, but with two
      # properties : minNorm == 0 and maxNorm > 0, which greatly simplify
      # the operations.
      barLength = @height * value.norm / @maxNorm
      y = @height - barLength
    else
      graphMinValue = if @alwaysShowLevelZero then Math.min(@minValue, 0) else @minValue
      graphMaxValue = if @alwaysShowLevelZero then Math.max(@maxValue, 0) else @maxValue
      if graphMinValue is graphMaxValue
        # don't divide by 0 ! The universe might collapse.
        # Arbitrary value : display the line on top
        barLength = @height
        y = 0
      else # universe is safe
        if 0 <= graphMinValue
          zeroLevel = graphMinValue
        else if graphMinValue < 0 < graphMaxValue
          zeroLevel = 0
        else if graphMaxValue <= 0
          zeroLevel = graphMaxValue
        # from = @height * (graphMaxValue - zeroLevel) / (graphMaxValue - graphMinValue)
        # to = @height * (graphMaxValue - value.value) / (graphMaxValue - graphMinValue)
        ratio = @height / (graphMaxValue - graphMinValue)
        barLength = Math.abs(zeroLevel - value.value) * ratio
        y = (graphMaxValue - Math.max(value.value, zeroLevel)) * ratio

    # cheat to display bars without length
    if barLength is 0
      y-- if y > 0
      barLength++

    {y: y, barLength: barLength}

  ###
  # Draw the line at the specified index.
  # @param {number} index the index to draw
  # @param {boolean} markForRedraw false if it doesn't need a redraw next time.
  ###
  drawIndex: (index, markForRedraw = true) =>
    @markedForRedraw.push index if markForRedraw
    bar = @scale @animationValues[index]
    @ctx.fillRect(2 * index * @barWidth, bar.y, @barWidth, bar.barLength)

  ###
  # Completely clear the canvas.
  ###
  clearContext: ->
    @ctx.clearRect 0, 0, @pxWidth, @height
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
  # Redraw everything at an appropriate time.
  ###
  scheduleFullRedraw: ->
    if @working
      @markedForRedraw = [0...VA.length]
    else
      @redraw()

  ###
  # Redraw all of the canvas.
  ###
  redraw: =>
    @clearContext()
    @redrawParts [0...@length]
    @redrawPersistentHighlight()

  shuffle: =>
    # Fisher-Yates shuffle
    for i in [@length-1..1]
      j = Math.floor(Math.random() * (i+1))
      [@values[i], @values[j]] = [@values[j], @values[i]]

  sort: =>
    @values.sort (a, b) => a.value - b.value

  reverse: =>
    @values.reverse()

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

  insert: (i, j) =>
    @checkIndexes("insert", [i, j])
    @inserts++
    @shifts += Math.abs(j - i)
    if i == j
      return
    @animationQueuePush(type: "insert", i: i, j: j)
    [tmp] = @values.splice i, 1
    @values.splice j, 0, tmp

  eq: (i, j) =>
    @checkIndexes("eq", [i, j])
    @compares++
    @animationQueuePush(type: "compare", i: i, j: j)
    @values[i].value == @values[j].value

  neq: (i, j) =>
    @checkIndexes("neq", [i, j])
    @compares++
    @animationQueuePush(type: "compare", i: i, j: j)
    @values[i].value != @values[j].value

  lt: (i, j) =>
    @checkIndexes("lt", [i, j])
    @compares++
    @animationQueuePush(type: "compare", i: i, j: j)
    @values[i].value < @values[j].value

  gt: (i, j) =>
    @checkIndexes("gt", [i, j])
    @compares++
    @animationQueuePush(type: "compare", i: i, j: j)
    @values[i].value > @values[j].value

  lte: (i, j) =>
    @checkIndexes("lte", [i, j])
    @compares++
    @animationQueuePush(type: "compare", i: i, j: j)
    @values[i].value <= @values[j].value

  gte: (i, j) =>
    @checkIndexes("gte", [i, j])
    @compares++
    @animationQueuePush(type: "compare", i: i, j: j)
    @values[i].value >= @values[j].value

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
    @values[index].value

  play: =>
    if @stepLength > 0
      @playStep()
    else
      @working = false
      @animationQueue = []
      @animationValues = @values.slice()
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
