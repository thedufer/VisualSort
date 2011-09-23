sorts = {
  bubble: """
for x in [0...VA.length]
  for y in [x + 1...VA.length]
    VA.highlight([x, y])
    if VA.get(x) > VA.get(y)
      VA.swap(x, y)
  """
  insert: """
for x in [0...VA.length - 1]
  minIndex = x
  for y in [x + 1...VA.length]
    VA.highlight([minIndex, y])
    if VA.get(y) < VA.get(minIndex)
      minIndex = y
  VA.insert(minIndex, x)
  """
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
    @stepLength = 50
    @animationQueue = []
    @working = false
    @quickHighlight = false
    @colors = {
      normal: "rgb(0,0,0)"
      swap: "rgb(255, 0, 0)"
      highlight: "rgb(0,255,0)"
      insert: "rgb(0,0,255)"
      slide: "rgb(127,127,255)"
    }

  setLength: (length) =>
    if @working
      return
    @length = Math.max 2, Math.min @maxLength, length
    @values =  ( value * @height / @length for value in [1..@length] )
    @barWidth = 1
    while @pxWidth / @barWidth / 2 > @length
      @barWidth++

  drawIndex: (index) =>
    @ctx.fillRect(2 * index * @barWidth, @height - @animationValues[index], @barWidth, @animationValues[index])

  redraw: =>
    @ctx.clearRect(0, 0, @pxWidth, @height)
    @ctx.fillStyle = @colors.normal
    for index in [0...@length]
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

  swap: (i, j) =>
    @animationQueue.push(type: "swap", i: i, j: j)
    tmp = @values[i]
    @values[i] = @values[j]
    @values[j] = tmp
    @swaps++

  insert: (i, j) =>
    @animationQueue.push(type: "insert", i: i, j: j)
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
    @inserts++

  highlight: (indices) =>
    if !$.isArray indices
      indices = [indices]
    @animationQueue.push(type: "highlight", indices: indices)
  
  saveInitialState: =>
    @animationValues = @values.slice()
    @swaps = 0
    @inserts = 0

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
    if !step?
      @working = false
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
    $("#js-error").html(error.message)
  VA.play()

$("#js-run").click ->
  evaluate $("#js-code").val()
  $("#js-result").html("# of swaps: #{VA.swaps}<br /># of inserts: #{VA.inserts}")

$("#js-set-values").click ->
  if VA.working
    return
  len = $("#js-length").val()
  if isFinite len
    VA.setLength +len

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

$("#js-set-speed").click ->
  speed = $("#js-speed").val()
  if isFinite speed
    VA.stepLength = +speed
  
  if $("#js-quick-highlight").is(":checked")
    VA.quickHighlight = true
  else
    VA.quickHighlight = false

$(".js-show-sort").click (e) ->
  $("#js-code").val(sorts[e.currentTarget.id])
