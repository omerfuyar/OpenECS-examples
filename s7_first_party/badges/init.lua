-- A badge, a panel that needs the shapes plugin: disabling shapes in the plugin list disables badges too, and enabling badges enables shapes.

local ecs = require("ecs")
local draw = require("draw")

ecs.panel.registerType({
  name = "badge",
  title = "Badge",
  create = function(panel)
    return { panel = panel }
  end,
  draw = function(_, surface)
    surface:fill(0, 0, surface.width, surface.height, "#2E3440")
    draw.text(surface, draw.font("ui"), "Badge", 16, 16, 20, ecs.setting.get("shapes.color"))
  end,
})
