#!/bin/bash
# Rewrite the first line of a changelog: version and distribution.
# Usage: set-version.sh <package> <changelog> [--meta]
#   driver: <changelog version without revision>+indi<INDI>+kosmos-N~deb13
#   --meta: <INDI>+kosmos-N~deb13
# Env: INDI_VERSION (ex. v2.2.5), REVISIONS (path of revisions.tsv, optional)
# NOT TESTED.
set -euo pipefail
die() { echo "ERROR: $*" >&2; exit 1; }

[ $# -ge 2 ] && [ $# -le 3 ] || die "Usage: $0 <package> <changelog> [--meta]"
pkg=$1; chlog=$2; mode=${3:-driver}
: "${INDI_VERSION:?INDI_VERSION is not set}"
indi=${INDI_VERSION#v}
[ -f "$chlog" ] || die "$chlog not found"

oldver=$(head -n 1 "$chlog" | sed -nE 's/^[^(]*\(([^)]*)\).*/\1/p')
[ -n "$oldver" ] || die "$pkg: cannot read the version from the first line of $chlog"

if [ "$mode" = "--meta" ]; then
	base=$indi
	core=$indi
else
	base=${oldver%-*}      # drops a revision such as -1; no-op without a hyphen
	[[ "$base" =~ ^[0-9][0-9A-Za-z.]*$ ]] \
		|| die "$pkg: unexpected upstream version '$base' (epoch, ~ or + inside?)"
	core="$base+indi$indi"
fi

N=1
if [ -n "${REVISIONS:-}" ] && [ -f "$REVISIONS" ]; then
	while IFS=$'\t' read -r n v r; do
		case "$n" in ''|'#'*) continue ;; esac
		[ "$n" = "$pkg" ] || continue
		if [ "$v" = "$base" ]; then
			[[ "$r" =~ ^[0-9]+$ ]] || die "$REVISIONS: bad revision '$r' for $pkg"
			N=$r
		else
			echo "NOTE: $pkg: revisions.tsv refers to $v, the changelog has $base: N=1" >&2
		fi
	done < "$REVISIONS"
fi

new="$core+kosmos-$N~deb13"
sed -i -E "1s/^([^ ]+) \([^)]*\) [^;]*;/\1 ($new) trixie;/" "$chlog"
head -n 1 "$chlog" | grep -qF "($new) trixie;" || die "$pkg: rewrite of the first line failed"
echo "version: $pkg $oldver -> $new"
