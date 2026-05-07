# Troubleshooting

## "No active credentials found"

Claude Code isn't logged in, or it logged in after `ccswitch` was installed.

```bash
claude auth login
ccswitch save main   # then save it
```

## "could not write to Keychain"

macOS Keychain denied the write. This usually means the Terminal app doesn't have Keychain access.

**Fix:**
1. Open **System Preferences → Privacy & Security → Keychain Access**
2. Make sure your terminal app (Terminal, iTerm2, etc.) is allowed
3. Or try running the command again — macOS sometimes shows a permission dialog

## "login was cancelled or the same account was used"

`ccswitch add` detected that credentials didn't change after `claude auth login`. This means:

- You closed the browser without logging in
- You logged in with the same account that's already active

**Fix:** Make sure you log in with a **different** account in the browser.

## `ccswitch use` works but Claude still uses the old account

Claude Code reads credentials at the start of each request. If a session is already running, it will use the new credentials on the **next command**, not the current one.

**Fix:** Just run your next Claude command — it will use the switched account automatically. You don't need to restart anything.

## "profile not found in Keychain" after switching Macs or reinstalling

Keychain entries are machine-local and don't sync across devices. If you migrated to a new Mac, you need to re-add each account:

```bash
ccswitch add main      # re-authenticate each account
ccswitch add work
```

## `ccswitch` command not found after installation

Your `~/.local/bin` is not in `$PATH`.

Add this to your `~/.zshrc` (or `~/.bashrc`):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then reload:

```bash
source ~/.zshrc
```

## Installed via Homebrew but `ccswitch` not found

Try:

```bash
brew link ccswitch
```

Or check if brew's bin is in your PATH:

```bash
echo $PATH | tr ':' '\n' | grep brew
```

## Token shows as expired in `ccswitch status`

Access tokens expire (typically every 30 days), but Claude Code automatically refreshes them using the refresh token. This is normal — the active session is still valid.

If Claude Code itself is showing auth errors, re-authenticate:

```bash
ccswitch save main   # save current profile first (backup)
claude auth login    # re-authenticate
ccswitch save main   # overwrite with fresh token
```

## Keychain password prompt appears repeatedly

macOS may prompt for your login password when ccswitch accesses the Keychain. To allow permanent access:

1. When the prompt appears, click **Always Allow** instead of Allow
2. This whitelists your terminal for future Keychain reads

## Something else?

[Open an issue](https://github.com/recepzgrmh/ccswitch/issues) with the output of:

```bash
ccswitch status
sw_vers
python3 --version
```
