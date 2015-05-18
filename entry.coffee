$ = require('jquery')
_ = require('underscore')
VisualArray = require('./VisualArray.coffee')

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
  y = x
  while y > 0 and VA.gt(y - 1, x)
    y--
  VA.insert(x, y)
  """
  insertswap: """
for x in [1...VA.length]
  y = x
  while y > 0 and VA.gt(y - 1, y)
    VA.swap(y - 1, y)
    y--
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
  gnome: """
s = 0
pos = 0
while pos < VA.length
  VA.locals.pos = pos
  if pos == 0 or VA.lte(pos-1, pos)
    ++pos
  else
    VA.swap(pos-1, pos)
    --pos
  """
  clear: ""
}

$(document).ready ->
  $("#js-stop").hide()

  sleep = (ms) ->
    start = new Date()
    while((new Date()) - start < ms)
      0

  window.VA = new VisualArray($("#js-canvas")[0])
  VA.generateValues(100)
  VA.shuffle()
  VA.saveForRestore()
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

  $("#js-options").submit ->
    if VA.working
      return
    $("#js-error").html("").hide()
    len = $("#js-length").val()
    if isFinite(len)
      VA.generateValues +len
    $("#js-length").val VA.length

    state = $("#js-state").val()
    if state == "random"
      VA.shuffle()
    else if state == "sort"
      VA.sort()
    else if state == "reverse"
      VA.sort()
      VA.reverse()
    else if state == "custom"
      try
        values = CoffeeScript.eval("return " + $("#js-custom-values").val())
        VA.setValues values
      catch error
        $("#js-error").html(error.message).show()
        return false

    VA.saveForRestore()
    VA.saveInitialState()
    VA.redraw()
    false # don't submit the form

  $("#js-restore").click ->
    VA.restore()
    VA.saveInitialState()
    VA.redraw()
    false

  $("#js-state").change ->
    if $(this).val() is "custom"
      $("#js-length").prop('disabled', true)
      $("#js-custom-values").val('[' + _.map(VA.values, (a) -> a.value) + ']')
      $("#custom-values").show()
    else
      $("#js-length").prop('disabled', false)
      $("#custom-values").hide()

  $("#js-speed").change ->
    speed = $("#js-speed").val()
    if isFinite speed
      VA.stepLength = 501 - +speed
    return

  updateQuickHighlight = ->
    VA.quickHighlight = $("#js-quick-highlight").is(":checked")

  updateQuickCompare = ->
    VA.quickCompare = $("#js-quick-compare").is(":checked")

  updateNormalizeBars = ->
    VA.normalizeBars = $("#js-normalize-bars").is(":checked")

  updateAlwaysShowLevelZero = ->
    VA.alwaysShowLevelZero = $("#js-always-show-level-zero").is(":checked")

  $("#js-quick-highlight").click ->
    updateQuickHighlight()
    return

  $("#js-quick-compare").click ->
    updateQuickCompare()
    return

  $("#js-normalize-bars").click ->
    updateNormalizeBars()
    VA.scheduleFullRedraw()
    return

  $("#js-always-show-level-zero").click ->
    updateAlwaysShowLevelZero()
    VA.scheduleFullRedraw()
    return

  $(".js-show-sort").click (e) ->
    $("#js-code").val(sorts[e.currentTarget.id])

  $("#show-more-options").click ->
    $("#more-options").toggle('slow')

  $("#js-code").val(sorts.bubble)

  updateQuickHighlight()
  updateQuickCompare()
  updateNormalizeBars()
  updateAlwaysShowLevelZero()
  VA.scheduleFullRedraw()
