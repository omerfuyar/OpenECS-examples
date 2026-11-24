-- the title bar's workspaces' menu, at its right, shows the current workspace's name; a click opens the list of workspaces, and Return switches

-- the title bar's workspaces' menu
local function menu(test)
  for _, part in ipairs(test.titleBar()) do
    if part.kind == "workspace" then
      return part
    end
  end
end

return {
  preset = "preset.lua",
  run = function(test)
    local part = menu(test)
    test.match(part.label, "C \u{25BE}", "the first workspace's name")

    -- the list opens with the current workspace chosen; Down chooses the next one
    test.click(part.rect.x + part.rect.width / 2, part.rect.y + part.rect.height / 2)
    test.key("Down")
    test.key("Return")
    test.match({ test.session().currentWorkspace, menu(test).label }, { 2, "Lua \u{25BE}" }, "the second workspace, by the menu")
  end,
}
