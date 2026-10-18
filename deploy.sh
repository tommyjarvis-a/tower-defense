#!/usr/bin/env bash
# Build + version-bump + deploy Neon TD to GitHub Pages.
# Usage: ./deploy.sh ["commit message"]   (needs GITHUB_TOKEN_TOMMYJARVIS)
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)"; REPO="${REPO_DIR:-/tmp/td}"
V="$(date -u +%Y%m%d%H%M%S)"
[ -d "$REPO/.git" ] || git clone -q https://github.com/tommyjarvis-a/tower-defense.git "$REPO"
python3 - "$SRC" "$V" <<'PY'
import sys,base64,re
src,v=sys.argv[1],sys.argv[2]
s=open(src+'/tpl.html').read().replace('ICON',base64.b64encode(open(src+'/icon.png','rb').read()).decode())
s,n=re.subn(r"const APP_VERSION='[^']*';","const APP_VERSION='%s';"%v,s); assert n==1
open(src+'/index.html','w').write(s); open(src+'/version.json','w').write('{"v":"%s"}\n'%v)
PY
cp "$SRC/index.html" "$SRC/icon.png" "$SRC/version.json" "$SRC/deploy.sh" "$REPO/"
rm -rf "$REPO/sprites"; mkdir -p "$REPO/sprites"; cp "$SRC"/sprites/*.png "$SRC/sprites/sprites.json" "$REPO/sprites/"   # art-v2 sheets (lazy-loaded)
cd "$REPO"; git add -A
git -c user.name=tommyjarvis-a -c user.email=tommyjarvis@mail.grokbot.com commit -qm "${1:-Deploy} (v$V)"
T="${GITHUB_TOKEN_TOMMYJARVIS:?missing token}"
git push -q "https://x-access-token:${T}@github.com/tommyjarvis-a/tower-defense.git" main 2>&1 | sed "s/${T}/***/g"
echo "deployed v$V ($(git rev-parse --short HEAD))"
