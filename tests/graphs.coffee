module "scale", # {{{
  setup: ->
    @VA = new VisualArray $("#js-canvas")[0]

  testScale: (index, result, message) ->
    deepEqual @VA.scale(@VA.values[index]), result, @VA.values[index] + " " + (message or "")

################################################################################

test "0 < values, normalizeBars = true", ->
  @VA.setValues [2..5]
  @VA.normalizeBars = true
  @testScale 0, {y:150, barLength:50 }
  @testScale 1, {y:100, barLength:100}
  @testScale 2, {y:50,  barLength:150}
  @testScale 3, {y:0,   barLength:200}

test "0 in values, normalizeBars = true", ->
  @VA.setValues [-2..1]
  @VA.normalizeBars = true
  @testScale 0, {y:150, barLength:50 }
  @testScale 1, {y:100, barLength:100}
  @testScale 2, {y:50,  barLength:150}
  @testScale 3, {y:0,   barLength:200}

test "values < 0, normalizeBars = true", ->
  @VA.setValues [-5..-2]
  @VA.normalizeBars = true
  @testScale 0, {y:150, barLength:50 }
  @testScale 1, {y:100, barLength:100}
  @testScale 2, {y:50,  barLength:150}
  @testScale 3, {y:0,   barLength:200}

test "same values, normalizeBars = true", ->
  @VA.setValues [42, 42, 42, 42]
  @VA.normalizeBars = true
  @testScale 0, {y:0, barLength:200}
  @testScale 1, {y:0, barLength:200}
  @testScale 2, {y:0, barLength:200}
  @testScale 3, {y:0, barLength:200}

################################################################################

test "0 < values, normalizeBars = false, alwaysShowLevelZero = false", ->
  @VA.setValues [2..5]
  @VA.normalizeBars = false
  @VA.alwaysShowLevelZero = false
  @testScale 0, {y:199,       barLength:1}, "1px cheat"
  @testScale 1, {y:133 + 1/3, barLength:66  + 2/3}
  @testScale 2, {y:66  + 2/3, barLength:133 + 1/3}
  @testScale 3, {y:0,         barLength:200}

test "0 in values, normalizeBars = false, alwaysShowLevelZero = false", ->
  @VA.setValues [-2..1]
  @VA.normalizeBars = false
  @VA.alwaysShowLevelZero = false
  @testScale 0, {y:66 + 2/3, barLength:133 + 1/3}
  @testScale 1, {y:66 + 2/3, barLength:66  + 2/3}
  @testScale 2, {y:65 + 2/3, barLength:1}
  @testScale 3, {y:0,        barLength:66  + 2/3}

test "values < 0, normalizeBars = false, alwaysShowLevelZero = false", ->
  @VA.setValues [-5..-2]
  @VA.normalizeBars = false
  @VA.alwaysShowLevelZero = false
  @testScale 0, {y:0, barLength:200}
  @testScale 1, {y:0, barLength:133 + 1/3}
  @testScale 2, {y:0, barLength:66  + 2/3}
  @testScale 3, {y:0, barLength:1}, "1px cheat"

test "same values, normalizeBars = false, alwaysShowLevelZero = false", ->
  @VA.setValues [42, 42, 42, 42]
  @VA.normalizeBars = false
  @VA.alwaysShowLevelZero = false
  @testScale 0, {y:0, barLength:200}
  @testScale 1, {y:0, barLength:200}
  @testScale 2, {y:0, barLength:200}
  @testScale 3, {y:0, barLength:200}

################################################################################

test "0 < values, normalizeBars = false, alwaysShowLevelZero = true", ->
  @VA.setValues [2..5]
  @VA.normalizeBars = false
  @VA.alwaysShowLevelZero = true
  @testScale 0, {y:120, barLength:80 }
  @testScale 1, {y:80,  barLength:120}
  @testScale 2, {y:40,  barLength:160}
  @testScale 3, {y:0,   barLength:200}

test "0 in values, normalizeBars = false, alwaysShowLevelZero = true", ->
  @VA.setValues [-2..1]
  @VA.normalizeBars = false
  @VA.alwaysShowLevelZero = true
  @testScale 0, {y:66 + 2/3, barLength:133 + 1/3}
  @testScale 1, {y:66 + 2/3, barLength:66  + 2/3}
  @testScale 2, {y:65 + 2/3, barLength:1}
  @testScale 3, {y:0,        barLength:66  + 2/3}

test "values < 0, normalizeBars = false, alwaysShowLevelZero = true", ->
  @VA.setValues [-5..-2]
  @VA.normalizeBars = false
  @VA.alwaysShowLevelZero = true
  @testScale 0, {y:0, barLength:200}
  @testScale 1, {y:0, barLength:160}
  @testScale 2, {y:0, barLength:120}
  @testScale 3, {y:0, barLength:80 }

test "same values, normalizeBars = false, alwaysShowLevelZero = true", ->
  @VA.setValues [42, 42, 42, 42]
  @VA.normalizeBars = false
  @VA.alwaysShowLevelZero = true
  @testScale 0, {y:0, barLength:200}
  @testScale 1, {y:0, barLength:200}
  @testScale 2, {y:0, barLength:200}
  @testScale 3, {y:0, barLength:200}

################################################################################

# }}}

module "setValues", # {{{
  setup: ->
    @VA = new VisualArray $("#js-canvas")[0]

test "setValues works", ->
  @VA.setValues [-30..69]
  equal @VA.length, 100, "length"
  equal @VA.barWidth, 4, "barWidth"
  equal @VA.maxNorm, 100, "maxNorm"
  equal @VA.minValue, -30, "minValue"
  equal @VA.maxValue, 69, "maxValue"

test "setValues works with arrays that don't fit easily in the canvas", ->
  @VA.setValues [-30..70]
  equal @VA.length, 101, "length"
  equal @VA.barWidth, 3, "barWidth, can't fill in all the canvas, but will display all values"
  equal @VA.maxNorm, 101, "maxNorm"
  equal @VA.minValue, -30, "minValue"
  equal @VA.maxValue, 70, "maxValue"

# }}}

# vim: set foldmethod=marker:
