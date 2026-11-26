-- A panel that lists the plugins in the plugin folders when it opens. The folder beside it holds two plugins whose manifests are
-- not valid: the list leaves them out, and the core logs why, which the panel hears through ecs.logged and keeps.

local ecs = require("ecs")

local refused = {}

-- the core's lines have the plugin "ecs"
ecs.event.subscribe("ecs.logged", function(_, line)
  if line.plugin == "ecs" and line.level == "error" and line.message:find("is not valid", 1, true) then
    refused[#refused + 1] = line.message
  end
end)

ecs.panel.registerType({
  name = "panel",
  title = "Lister",

  create = function()
    local listed = {}

    for _, plugin in ipairs(ecs.plugins.list()) do
      listed[#listed + 1] = plugin.name
    end

    return { listed = listed }
  end,

  saveState = function(self)
    return { listed = self.listed, refused = refused }
  end,

  draw = function(_, surface)
    surface:fill(0, 0, surface.width, surface.height, "#3B4252")
  end,
})
