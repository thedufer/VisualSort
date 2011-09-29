$("#js-stop").hide()

sorts = {
  bubble: """
bubbleSort = ->
  VA.locals.swapped = true
  VA.locals.y = VA.length
  while VA.locals.swapped
    VA.locals.y--
    VA.locals.swapped = false
    for x in [0...VA.locals.y]
      VA.locals.x = x
      if VA.gt(x, x + 1)
        VA.swap(x, x + 1)
        VA.locals.swapped = true

bubbleSort()
  """
  select: """
for x in [0...VA.length - 1]
  minIndex = x
  for y in [x + 1...VA.length]
    if VA.lt(y, minIndex)
      minIndex = y
  VA.swap(minIndex, x)
  """
  insert: """
for x in [1...VA.length]
  y = 0
  while VA.gt(x, y)
    y++
    if y == x
      break
  VA.insert(x, y)
  """
  quick: """
slowsort = (left, right) ->
  #left, right are inclusive
  for x in [left..right]
    for y in [x + 1..right] by 1
      if VA.gt(x, y)
        VA.swap(x, y)

quicksort = (left, right) ->
  if right <= left
    return
  VA.persistHighlight([left..right])
  #left, right are inclusive
  #pivot is the left-most value
  if right - left < 5
    slowsort(left, right)
    return
  pivot = left
  leftMove = left + 1
  rightMove = right
  while leftMove < rightMove
    if VA.lte(leftMove, pivot)
      leftMove++
    else if VA.gt(rightMove, pivot)
      rightMove--
    else
      VA.swap(rightMove, leftMove)
  #now, leftMove == rightMove
  if VA.gt(leftMove, pivot)
    leftMove -= 2
  else
    rightMove++
    leftMove--
  VA.swap(leftMove + 1, pivot)
  quicksort(left, leftMove)
  quicksort(rightMove, right)

quicksort(0, VA.length - 1)
  """
  msbradix: """
sort = (begin, end, bit) ->
  VA.persistHighlight([begin...end])
  VA.locals.bit = bit
  i = begin
  j = end
  mask = 1 << bit
  while i < j
    while i < j and !(VA.get(i) & mask)
      ++i
    while i < j and (VA.get(j - 1) & mask)
      --j
    if i < j
      VA.swap(i++, --j)

  if bit and i > begin
    sort(begin, i, bit - 1)
  if bit and i < end
    sort(i, end, bit - 1)

sort(0, VA.length, 30)
  """
  lsbradix: """
bit = 0
loop
  VA.locals.bit = bit
  mask = 1 << bit
  i = 0; end = VA.length
  while i < end
    if (VA.get(i) & mask)
      VA.insert i, VA.length-1
      end--
    else
      i++

  bit++
  break if end == VA.length
  """
  merge: """
mergesort = (lo, hi) ->
  if lo==hi
    return
  if lo+1==hi
    if VA.gt(lo,hi)
      VA.swap(lo,hi)
    return
  mid=Math.floor(lo+(hi-lo)/2)
  mergesort(lo,mid)
  mergesort(mid+1,hi)
  mid++
  while lo<=mid && mid<=hi
    if VA.gt(lo,mid)
      VA.insert(mid, lo)
      mid++
    else
      lo++
mergesort(0,VA.length - 1)
  """
  heap: """
fix_heap = (y, size) ->
  loop
    y1 = 2*y+1
    if y1 >= size then break
    if y1 + 1 < size && VA.gt(y1 + 1, y1)
      y1++
    if VA.lt(y, y1)
      VA.swap(y, y1)
      y = y1
    else
      break

for x in [VA.length >> 1 ... -1] by -1
  fix_heap(x, VA.length)

for x in [VA.length-1 ... 0] by -1
  VA.swap(x, 0)
  fix_heap(0, x)
  """
  clear: ""
}

sleep = (ms) ->
  start = new Date()
  while((new Date()) - start < ms)
    0

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

window.VA = new VisualArray $("#js-canvas")[0]
VA.setLength(100)
VA.shuffle()
VA.saveInitialState()
VA.redraw()

evaluate = (code) ->
  $("#js-error").html("").hide()
  if VA.working
    return
  VA.saveInitialState()
  VA.starting()
  try
    CoffeeScript.eval(code)
  catch error
    $("#js-error").html(error.message).show()
  VA.play()

$("#js-run").click ->
  $("#js-run").hide()
  $("#js-stop").show()
  evaluate $("#js-code").val()

$("#js-stop").click ->
  VA.stop = true

$("#js-set-values").click ->
  if VA.working
    return
  len = $("#js-length").val()
  if isFinite len
    VA.setLength +len
  $("#js-length").val VA.length

  state = $("#js-state").val()
  if state == "random"
    VA.shuffle()
  else if state == "sort"
    VA.sort()
  else if state == "reverse"
    VA.sort()
    VA.reverse()

  VA.saveInitialState()
  VA.redraw()

$("#js-speed").change ->
  speed = $("#js-speed").val()
  if isFinite speed
    VA.stepLength = +speed
  return

$("#js-quick-highlight").click ->
  VA.quickHighlight = $("#js-quick-highlight").is(":checked")
  return

$("#js-quick-compare").click ->
  VA.quickCompare = $("#js-quick-compare").is(":checked")
  return

$(".js-show-sort").click (e) ->
  $("#js-code").val(sorts[e.currentTarget.id])

$("#js-code").val(sorts.bubble)
