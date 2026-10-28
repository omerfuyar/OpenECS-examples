#!/bin/sh
# Checks that clang-format leaves the examples' C files as they are (.clang-format), so the code keeps one format; the check Format runs it.
# CLANG_FORMAT names clang-format, clang-format if it is not set. It prints the files that differ, and how.
set -u
cd "$(dirname "$0")/../.." || exit 2

# shellcheck disable=SC2046
"${CLANG_FORMAT:-clang-format}" --dry-run --Werror $(git ls-files '[cs][0-9]*_*/*.c' '[cs][0-9]*_*/*.h')
