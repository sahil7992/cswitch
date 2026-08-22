#!/usr/bin/env bash
# cswitch installer: copies the script into ~/.claude/router and links it onto PATH.
set -euo pipefail

ROOT="$HOME/.claude/router"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/cswitch"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "cswitch currently supports macOS only (it reads the login keychain)." >&2
  exit 1
fi

mkdir -p "$ROOT/slots" && chmod 700 "$ROOT" "$ROOT/slots"
install -m 700 "$SRC" "$ROOT/cswitch"

mkdir -p "$HOME/.local/bin"
ln -sf "$ROOT/cswitch" "$HOME/.local/bin/cswitch"

echo "installed: $ROOT/cswitch"
echo "linked:    $HOME/.local/bin/cswitch"
echo
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) echo "note: add \$HOME/.local/bin to your PATH" ;;
esac
echo "next:"
echo "  1. cswitch add <name>          # save the account you are logged in as"
echo "  2. run /login in Claude Code   # sign in to the second account"
echo "  3. cswitch add <name2>         # save that one too"
echo "  4. cswitch hook install        # optional auto rotation"
