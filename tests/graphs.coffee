module "scale",
  setup: ->
    @VA = new VisualArray $("#js-canvas")[0]

test "test scale", ->
  @VA.setValues [2..5]
  @VA.normalizeBars = true
  @VA.alwaysShowLevelZero = false
  deepEqual @VA.scale(@VA.values[0]), 50
  deepEqual @VA.scale(@VA.values[1]), 100
  deepEqual @VA.scale(@VA.values[2]), 150
  deepEqual @VA.scale(@VA.values[3]), 200
