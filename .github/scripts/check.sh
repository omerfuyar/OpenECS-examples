#!/bin/sh
# Formats the examples' C files with clang-format and checks them with clang-tidy (.clang-format, .clang-tidy), for agents before they commit.
# With no files named, it takes the examples' C files that differ from dev, committed or not.
# It prints only the problems, and fails when clang-tidy finds one.
# It runs in the examples/ folder of an OpenECS checkout, after OpenECS's Debug build, whose include/ and definitions/ folders have the headers.
set -u
cd "$(dirname "$0")/../.." || exit 2

if [ $# -eq 0 ]; then
    base=$(git merge-base HEAD origin/dev 2> /dev/null || echo HEAD)
    # shellcheck disable=SC2046
    set -- $({
        git diff --name-only "$base"
        git ls-files --others --exclude-standard
    } | grep -E '^[0-9]+_.*\.[ch]$' | sort -u)
fi

files=
for file in "$@"; do
    [ -f "$file" ] && files="$files $file"
done
[ -z "$files" ] && exit 0

# shellcheck disable=SC2086
clang-format -i $files || exit 2

build=../build/Debug/include
if [ ! -f "$build/OpenECS.h" ]; then
    echo "clang-tidy needs OpenECS's Debug build first: in OpenECS, .github/scripts/build.sh D"
    exit 2
fi

# the flags of an example's Debug build in shuild.c; definitions/ has the standard plugins' headers
flags="-std=c23 -DDEBUG -DSDL_ASSERT_LEVEL=2 -isystem $build -isystem ../build/Debug/definitions"

failed=0
for file in $files; do
    case "$file" in
    *.c) ;;
    *) continue ;;
    esac

    # shellcheck disable=SC2086
    if ! clang-tidy --quiet "$file" -- $flags > ../build/tidy.log 2>&1; then
        grep -E "(warning|error):" -A3 ../build/tidy.log | grep -v -E "^[0-9]+ warnings? generated"
        failed=1
    fi
done

exit $failed
