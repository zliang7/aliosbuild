#!/bin/bash

# Usage:
#
# $ build.sh [workspace]
#
# the default workspace is current directory.

url="ssh://android.intel.com/manifests"


shopt -s nullglob
has_patch() {
    for f in "$1"/*.patch; do
        return 0
    done
    return 1
}


# determine source directory
srcdir=$(readlink -e $0)
srcdir=${srcdir%/*}
manifests=".repo/manifests"
test -d "$srcdir/$manifests" || exit 1

# get commit hash
commit=""
test -r "$srcdir/commit" && commit=$(<$srcdir/commit)
test -z "$commit" && exit 2

# create workspace if specified
if test -n "$1"; then
    test ! -e "$1" && mkdir -p "$1"
    cd "$1" || exit 3
fi

# fetch code
repo init -u "$url" -b "$commit" || exit 4
git -C "$manifests" am "$srcdir/$manifests/"*.patch || exit 5
repo sync || exit 6

# apply local patches
find "$srcdir" -mindepth 1 -type d | while read pchdir; do
    path=${pchdir#$srcdir/}
    test "${path#.repo}" = "$path" && has_patch "$pchdir" || continue
    git -C "$path" am "$pchdir"/*.patch || exit 7
done

# build
(cd xmake; ./mk_yunos.sh yunhal --enable-closed-source)
