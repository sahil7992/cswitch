<h1 align="center">cswitch</h1>

<p align="center">
  <b>Rotate Claude Code between your accounts automatically, before you hit the wall.</b>
</p>

<p align="center">
  <img alt="license" src="https://img.shields.io/badge/license-MIT-blue.svg">
  <img alt="platform" src="https://img.shields.io/badge/platform-macOS-lightgrey.svg">
  <img alt="python" src="https://img.shields.io/badge/python-3.9%2B-3776AB.svg">
  <img alt="dependencies" src="https://img.shields.io/badge/dependencies-none-brightgreen.svg">
</p>

---

You have more than one Claude account. You burn through the weekly window on one,
Claude Code stops, and you go log in to the other one by hand. Then you do it again
tomorrow.

`cswitch` saves each account once and swaps between them at the credential layer.
No re-authorizing, no restarting your session, no losing your place.

```console
$ cswitch ls
  slot        account                          5h     7d   resets(7d)
* work        you@company.com                  8%    91%   2026-08-24 05:00
  personal    you@gmail.com                    2%    14%   2026-08-26 05:00

threshold 90%  |  * = active

$ cswitch auto
account rotated: work (91% used) -> personal (14% used)
```

Wire it into a hook and that second command runs itself.

## Install

```bash
git clone https://github.com/sahil7992/cswitch.git
cd cswitch && ./install.sh
```

No package manager, no runtime dependencies. It uses the `python3`, `curl`, and
`security` binaries that already ship with macOS.

## Setup

You authorize each account exactly once, ever.

```bash
# 1. you are already signed in to one account
cswitch add work

# 2. run /login inside Claude Code and sign in to the other account
cswitch add personal

# 3. optional: rotate automatically instead of by hand
cswitch hook install
```

That is the whole setup. From here `cswitch` keeps both tokens alive on its own.

## How it works

Claude Code keeps its login in one keychain item and re-reads it every 30 seconds
or so. `cswitch` rewrites that item underneath a running session, which is why a
swap needs no restart.

```
  Claude Code
      |  re-reads every ~30s
      v
  keychain: "Claude Code-credentials"
      |
      +-- claudeAiOauth     <- the account. cswitch swaps ONLY this
      |
      +-- mcpOAuth.*        <- your MCP server logins. left untouched
      +
  ~/.claude.json
      +-- oauthAccount      <- identity shown in the UI, swapped to match
```

Three details do the real work:

**Tokens are written back before every swap.** Refresh tokens rotate on use. A
switcher that restores an old snapshot restores a dead token, and you are back to
clicking authorize. `cswitch` captures the live token on the way out, into the slot
of whichever account is actually signed in, so a `/login` behind its back cannot
cross-wire two slots.

**Idle accounts get refreshed.** Refresh tokens expire about 29 days after issue.
The account you are not using would quietly die. `cswitch` renews it whenever it
reads that account's quota, so both slots stay valid indefinitely.

**MCP logins survive.** The keychain blob holds your MCP server OAuth next to your
Claude login. Only the Claude half is replaced.

## Auto rotation

There is no rate limit event to hook into, so `cswitch` checks on the way in. The
`UserPromptSubmit` hook reads the active account's usage, and if it is past the
threshold it rotates to whichever saved account has the most headroom.

It fires before your prompt is sent, so the swap lands on the request that would
otherwise have failed. Checks are cached for 90 seconds, so the common case costs
nothing. If anything goes wrong it exits quietly and your prompt goes through
untouched.

Rotating at 90 percent rather than at the hard limit is deliberate. It means you
never see the wall.

## Commands

| Command | What it does |
| :--- | :--- |
| `cswitch add <name>` | Save the account you are currently signed in as |
| `cswitch ls` | All slots with live usage on both windows |
| `cswitch use <name>` | Switch now |
| `cswitch auto` | Switch if the active account is past the threshold |
| `cswitch whoami` | Active account and its usage |
| `cswitch sync` | Write the live token back to its slot |
| `cswitch hook install` | Register the auto rotation hook |
| `cswitch hook uninstall` | Remove it |
| `cswitch set threshold=85` | Tune `threshold`, `margin`, or `cache_ttl` |

## Security

Everything stays on your machine. There is no server, no telemetry, and no network
call to anywhere except `api.anthropic.com`.

Saved tokens live in `~/.claude/router/slots/`, written `0600` inside a `0700`
directory. Nothing in that directory is tracked by git, and `.gitignore` is set up
so a careless `git add` cannot pick it up.

Keychain writes go over stdin rather than through argv, so your token never appears
in the process list. Every write is read back and compared before it is trusted, and
the previous blob is backed up first.

If you use a company account, note that its token sits in that directory like any
other. Treat the machine accordingly.

## Limitations

- **macOS only.** It reads the login keychain. Linux keeps credentials in
  `~/.claude/.credentials.json`, which would be a small change, but it is untested
  so it is not claimed.
- **A swap cannot rescue the turn you are in.** If you hit the limit mid response,
  nothing can save that response. The threshold check exists so you do not get there.
- **It leans on two undocumented endpoints** for usage and token refresh, the same
  ones Claude Code itself uses. If Anthropic changes them, this breaks and you fix
  it in one file.

## A note on accounts

This is for rotating between accounts you personally hold and pay for. Each account
uses its own quota and nothing here touches how limits are calculated. If one of
your accounts belongs to an employer, whether you use it for personal work is a
question for them and not for a README.

## License

MIT. See [LICENSE](LICENSE).
