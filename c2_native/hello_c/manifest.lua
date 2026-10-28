-- The same plugin as c1_hello, in C. The build compiles every C file of the folder into the plugin's library.
---@type ecs.Manifest
return {
  name = "hello_c",
  version = "0.1.0",
  api = 2,
  description = "The smallest native plugin: one panel of one colour",
  type = "native", -- its code is libhello_c.so in this folder, which the build makes from the folder's C files
}
