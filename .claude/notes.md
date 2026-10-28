# Notes

Notes for agents and the owner that belong in no other document: why the tools are set up as they are. OpenECS's `.claude/notes.md` holds the notes that all the repositories share, and OpenECS's `.claude/skills/` the procedures; agents work in OpenECS's `examples/` folder, where they apply.

## Tools

- `.github/scripts/check.sh` runs clang-tidy on `compile_commands.json`, which shuild writes here in OpenECS's build, as OpenECS's notes say.
- The checks follow OpenECS-std's: its `.clang-tidy`, and its names for a plugin's functions (OpenECS-std DESIGN.md, section 1.3).
- `performance-no-int-to-ptr` is off: Sketch keeps a panel's id in a pointer, as OpenECS's user data is one.
