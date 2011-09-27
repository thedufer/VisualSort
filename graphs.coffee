$("#js-stop").hide()

sorts = {
  bubble: """
bubbleSort = ->
  VA.locals.swapped = true
  while VA.locals.swapped
    VA.locals.swapped = false
    for x in [0...VA.length - 1]
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
    for y in [x + 1..right]
      if VA.gt(x, y)
        VA.swap(x, y)

quicksort = (left, right) ->
  VA.persistHighlight([left..right])
  if right <= left
    return
  #left, right are inclusive
  #pivot is the left-most value
  if right - left < 5
    slowsort(left, right)
    return
  pivot = left
  leftMove = left + 1
  rightMove = right
  while leftMove < rightMove
    if VA.lt(leftMove, pivot)
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
  radix: """
sort = (begin, end, bit) ->
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
mergesort(0,VA.length)
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
    @values =  [1..@length]
    @barWidth = 1
    while @pxWidth / @barWidth / 2 > @length
      @barWidth++

  scale: (value) =>
    @height / @length * value

  drawIndex: (index) =>
    @ctx.fillRect(2 * index * @barWidth, @height - @scale(@animationValues[index]), @barWidth, @scale(@animationValues[index]))

  redraw: =>
    @ctx.clearRect(0, 0, @pxWidth, @height)
    @ctx.fillStyle = @colors.normal
    for index in [0...@length]
      @drawIndex(index)
    @ctx.fillStyle = @colors.persistHighlight
    for index in @currentHighlight
      @drawIndex(index)

  shuffle: =>
    order = ( Math.random() for x in [0...@length] )
    for x in [0...@length]
      for y in [x + 1...@length]
        if order[x] > order[y]
          tmp = order[x]
          order[x] = order[y]
          order[y] = tmp
          tmp = @values[x]
          @values[x] = @values[y]
          @values[y] = tmp

  sort: =>
    for x in [0...@length]
      for y in [x + 1...@length]
        if @values[x] > @values[y]
          tmp = @values[x]
          @values[x] = @values[y]
          @values[y] = tmp

  reverse: =>
    for x in [0...@length / 2]
      tmp = @values[x]
      @values[x] = @values[@length - x - 1]
      @values[@length - x - 1] = tmp

  animationQueuePush: (dict) =>
    dict.swaps = @swaps
    dict.inserts = @inserts
    dict.shifts = @shifts
    dict.compares = @compares
    dict.locals = _.extend {}, @locals
    @animationQueue.push dict

  swap: (i, j) =>
    @swaps++
    if i == j
      return
    @animationQueuePush(type: "swap", i: i, j: j)
    tmp = @values[i]
    @values[i] = @values[j]
    @values[j] = tmp

  insert: (i, j) =>
    @inserts++
    @shifts += Math.abs(j - i)
    if i == j
      return
    @animationQueuePush(type: "insert", i: i, j: j)
    tmp = @values[i]
    k = i
    if i < j
      while k < j
        @values[k] = @values[k + 1]
        k++
    else
      while k > j
        @values[k] = @values[k - 1]
        k--
    @values[j] = tmp
  
  eq: (i, j) =>
    @compares++
    @animationQueuePush(type: "compare", i: i, j: j)
    @values[i] == @values[j]

  neq: (i, j) =>
    @compares++
    @animationQueuePush(type: "compare", i: i, j: j)
    @values[i] != @values[j]

  lt: (i, j) =>
    @compares++
    @animationQueuePush(type: "compare", i: i, j: j)
    @values[i] < @values[j]

  gt: (i, j) =>
    @compares++
    @animationQueuePush(type: "compare", i: i, j: j)
    @values[i] > @values[j]

  lte: (i, j) =>
    @compares++
    @animationQueuePush(type: "compare", i: i, j: j)
    @values[i] <= @values[j]

  gte: (i, j) =>
    @compares++
    @animationQueuePush(type: "compare", i: i, j: j)
    @values[i] >= @values[j]

  highlight: (indices) =>
    if !$.isArray indices
      indices = [indices]
    @animationQueuePush(type: "highlight", indices: indices)

  persistHighlight: (indices) =>
    if !$.isArray indices
      indices = [indices]
    @animationQueuePush(type: "persistHighlight", indices: indices)
  
  saveInitialState: =>
    @animationValues = @values.slice()
    @locals = {}
    @swaps = 0
    @inserts = 0
    @shifts = 0
    @compares = 0
    @currentHighlight = []

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
      @redraw()
  
  playStep: =>
    step = @animationQueue.shift()
    if step?
      $("#js-swaps").html(step.swaps)
      $("#js-inserts").html(step.inserts)
      $("#js-shifts").html(if step.inserts then Math.floor(step.shifts / step.inserts) else 0)
      $("#js-compares").html(step.compares)
      localsString = ""
      for k, v of step.locals
        localsString += "#{k}: #{v}<br />"
      $("#js-result").html(localsString)
    if !step? || @stop
      $("#js-stop").hide()
      $("#js-run").show()
      @stop = false
      @working = false
      @animationQueue = []
      @values = @animationValues.slice()
      @currentHighlight = []
      @redraw()
      return
    else if step.type == "swap"
      @redraw()
      @ctx.fillStyle = @colors.swap
      @drawIndex(step.i)
      @drawIndex(step.j)
      setTimeout =>
        tmp = @animationValues[step.i]
        @animationValues[step.i] = @animationValues[step.j]
        @animationValues[step.j] = tmp
        @redraw()
        @ctx.fillStyle = @colors.swap
        @drawIndex(step.i)
        @drawIndex(step.j)
        setTimeout @play, @stepLength
      , @stepLength
    else if step.type == "highlight"
      @redraw()
      @ctx.fillStyle = @colors.highlight
      for index in step.indices
        @drawIndex(index)
      setTimeout @play, if @quickHighlight then @stepLength / 10 else @stepLength
    else if step.type == "persistHighlight"
      @currentHighlight = step.indices
      setTimeout @play, 0
    else if step.type == "compare"
      @redraw()
      @ctx.fillStyle = @colors.compare
      @drawIndex(step.i)
      @drawIndex(step.j)
      setTimeout @play, if @quickCompare then @stepLength / 10 else @stepLength
    else if step.type == "insert"
      if step.i < step.j
        slideRange = [step.i..step.j]
      else
        slideRange = [step.j..step.i]
      @redraw()
      @ctx.fillStyle = @colors.slide
      for x in slideRange
        @drawIndex(x)
      @ctx.fillStyle = @colors.insert
      @drawIndex(step.i)
      setTimeout =>
        tmp = @animationValues[step.i]
        k = step.i
        if step.i < step.j
          while k < step.j
            @animationValues[k] = @animationValues[k + 1]
            k++
        else
          while k > step.j
            @animationValues[k] = @animationValues[k - 1]
            k--
        @animationValues[step.j] = tmp
        @redraw()
        @ctx.fillStyle = @colors.slide
        for x in slideRange
          @drawIndex(x)
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
  $("#js-error").html("")
  if VA.working
    return
  VA.saveInitialState()
  VA.starting()
  try
    CoffeeScript.eval(code)
  catch error
    $("#js-error").html(error.message + "<br /><br />")
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
  if $("#js-quick-highlight").is(":checked")
    VA.quickHighlight = true
  else
    VA.quickHighlight = false
  return

$("#js-quick-compare").click ->
  if $("#js-quick-compare").is(":checked")
    VA.quickCompare = true
  else
    VA.quickCompare = false
  return

$(".js-show-sort").click (e) ->
  $("#js-code").val(sorts[e.currentTarget.id])

$("#js-code").val(sorts.bubble)
