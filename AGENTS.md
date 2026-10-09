# AGENTS.md

Instructions for AI agents working in this repository. Read this file fully before doing anything.

This repository is part of OpenECS. OpenECS's [AGENTS.md](https://github.com/omerfuyar/OpenECS/blob/dev/AGENTS.md) applies here in full: how to work with the owner, the boundaries, git and writing documents. Read it first; when this repository is checked out in OpenECS's `examples/` folder, it is `../AGENTS.md`. This file names only what is different here.

## Where things are

| Path                   | What it holds                                                      |
| ---------------------- | ------------------------------------------------------------------ |
| [README.md](README.md) | Short introduction, and how to run, build and test the examples.   |
| `1_hello/` and on      | The examples, in the order a reader learns.                        |
| `.github/`             | Checks and rulesets.                                               |
| `LICENSE.md`           | The license, zlib.                                                 |

OpenECS's DESIGN.md, section 17.6, says what an example is and how its comments are written. Read it, and OpenECS's OVERVIEW.md and DESIGN.md, before you propose or change anything.

## Differences

- Work in a checkout of OpenECS with its submodules, in its `examples/` folder, so you build and test with OpenECS (README.md).
- Releases are OpenECS's: this repository has no tags or release descriptions of its own. OpenECS's submodule names the commit that ships.
- After a change here is merged into `dev`, move OpenECS's `examples/` submodule to it in a pull request to OpenECS.
- Examples teach how OpenECS behaves. Each explains a concept of OpenECS the first time it uses it, and not the example's own logic.
