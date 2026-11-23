-- Functions that disable and enable the primes plugin while its workers count, so the test checks that the core stops them with it.
-- A plugin may be disabled at any time, by the user or by another plugin: its workers stop, and its panels become placeholders that keep
-- their state until it is enabled again.

local ecs = require("ecs")

-- bound functions run as a key would run them, so a test runs them with test.call
ecs.service.register({
  disable = { sig = "void()", doc = "Disable the primes plugin", fn = function() ecs.plugins.disable("primes") end },
  enable = { sig = "void()", doc = "Enable the primes plugin", fn = function() ecs.plugins.enable("primes") end },
})
