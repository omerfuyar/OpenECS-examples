# AGENTS.md

Instructions for AI agents working in this repository. Read this file fully before doing anything.

This repository is part of OpenECS. OpenECS's [AGENTS.md](https://github.com/omerfuyar/OpenECS/blob/dev/AGENTS.md) applies here in full: how to work with the owner, the boundaries, git and writing documents. Read it first; when this repository is checked out in OpenECS's `examples/` folder, it is `../AGENTS.md`. This file names only what is different here.

## Where things are

| Path                   | What it holds                                                                                                                                                              |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [README.md](README.md) | Short introduction, and how to run, build and test the examples.                                                                                                           |
| `1_hello/` and on      | The examples, in the order a reader learns.                                                                                                                                |
| `shuild.c`             | The build of the examples, which OpenECS's build compiles and runs.                                                                                                        |
| `.github/`             | Checks, rulesets and the agents' check script.                                                                                                                             |
| `.clang-format`        | How clang-format formats the C code, as OpenECS's does.                                                                                                                    |
| `.clang-tidy`          | What clang-tidy checks in the C code: OpenECS-std's names for a plugin's functions, how complex functions are, and common bugs.                                                                       |
| `.clangd`              | How clangd reads the compilation database that shuild writes, `compile_commands.json`, without gcc's own flags.                                                                                       |
| `.claude/`             | Claude Code's settings and notes: it formats each C file it edits; `notes.md` says why the tools are set up as they are. OpenECS's `.claude/skills/` holds the procedures. |
| `LICENSE.md`           | The license, zlib.                                                                                                                                                         |

OpenECS's DESIGN.md, section 17.6, says what an example is and how its comments are written. Before you propose or change anything, read it, then the Contents of OpenECS's OVERVIEW.md and DESIGN.md and every section the task touches.

## Differences

- Work in a checkout of OpenECS with its submodules, in its `examples/` folder, so you build and test with OpenECS (README.md).
- Releases are made with OpenECS's, at the same time and with the same version, as OpenECS's AGENTS.md says: `dev` is merged into `main` with a pull request that the owner reviews, and the owner tags it. A release's description is `.github/release-notes/vVERSION.md`; it says what changed in the examples, and OpenECS's description links to it. OpenECS's submodule names the commit that ships.
- The examples are the tests of OpenECS and OpenECS-std. A change there that breaks an example changes the example in the same piece of work, so every test passes.
- Before each commit, run `.github/scripts/check.sh` here, in place of OpenECS's: it formats the changed C files of the examples and checks them with clang-tidy, and checks the changed Lua files with the Lua language server when it is installed. clang-tidy needs OpenECS's Debug build first.
- After a change here is merged into `dev`, move OpenECS's `examples/` submodule to it in a pull request to OpenECS.
- Examples teach how OpenECS and its standard plugins behave. Each explains a concept the first time it uses it, and not the example's own logic. Examples 1 to 12 teach OpenECS; from 13, each teaches a standard plugin or a first-party plugin.
