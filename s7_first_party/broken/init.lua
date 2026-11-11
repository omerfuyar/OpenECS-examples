-- A plugin that fails when it starts. No preset names it, so it is not loaded; the plugin list shows it, and enabling it there reports the error
-- and leaves it disabled, so the user can enable it again once it is fixed.

error("this plugin fails on purpose")
