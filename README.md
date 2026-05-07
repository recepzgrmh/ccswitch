# ccswitch

**Instantly switch between multiple Claude Code accounts — no browser, no login codes.**

If you use more than one Claude account (work, personal, backup), you know the pain: hit your rate limit, open the terminal, type `claude auth login`, wait for the browser, copy the verification code... every single time.

`ccswitch` saves each account's session to macOS Keychain and swaps the active credentials in under a second.

```
$ ccswitch use work
✓ 'work' (work@example.com, pro) hesabına geçildi
```

---

## How it works

Claude Code stores its auth token in macOS Keychain under `Claude Code-credentials`. `ccswitch` saves a named snapshot of that entry for each account and hot-swaps it when you switch — no re-authentication needed.

Your tokens never leave your machine. Everything goes through the macOS Keychain API (`security`).

---

## Requirements

- macOS (uses Keychain)
- [Claude Code](https://claude.ai/code) CLI installed
- Python 3.8+

---

## Installation

```bash
git clone https://github.com/YOUR_USERNAME/ccswitch.git
cd ccswitch
bash install.sh
```

Or one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ccswitch/main/install.sh | bash
# then copy ccswitch to ~/.local/bin manually or clone the repo first
```

> **Manual install:** Copy the `ccswitch` file to any directory in your `$PATH` and run `chmod +x ccswitch`.

---

## Usage

### Save your current account

```bash
ccswitch save main
# ✓ 'main' olarak kaydedildi (you@example.com, pro)
```

### Add a new account

Opens a browser for login, then saves the session automatically.

```bash
ccswitch add work
# Browser opens → log in → session saved as 'work'
```

### Switch accounts instantly

```bash
ccswitch use work
# ✓ switched to 'work' in <1 second, no browser
```

### List saved profiles

```bash
ccswitch list

  PROFIL             HESAP                          TİP        KAYDEDİLDİ
  ────────────────────────────────────────────────────────────────────────
  main               you@example.com                pro        2026-05-07 10:00
  work               work@company.com               pro        2026-05-07 10:05 ◀ aktif
  backup             backup@gmail.com               free       2026-05-07 10:10
```

### Show active account

```bash
ccswitch current

  Hesap     : work@company.com
  Profil    : work
  Plan      : pro (default_claude_ai)
  Token son : 2026-06-15 12:00 UTC
```

### Remove a profile

```bash
ccswitch remove backup
# ✓ 'backup' profili silindi
```

---

## Typical workflow

```bash
# First time setup — save all your accounts
ccswitch save main
ccswitch add work      # opens browser for second account
ccswitch add backup    # opens browser for third account

# Day to day — hit rate limit on 'main', switch instantly
ccswitch use work

# Check where you are
ccswitch current
```

---

## Security

- Credentials are stored in **macOS Keychain** under the service name `ccswitch-profiles/<profile-name>`.
- The tool only calls the standard `security` CLI — no network requests, no third-party libraries.
- Tokens are never written to disk in plaintext.

---

## FAQ

**Does this work with Claude Max / Pro / Free?**  
Yes. The tool works with any Claude Code subscription type.

**Will switching break anything mid-session?**  
No. Claude Code reads credentials at the start of each request, so switching takes effect on the next command.

**Can I use this on Linux?**  
Not yet — Linux doesn't have Keychain. A `libsecret` / `pass` backend is a potential future addition. PRs welcome.

**Is this official / supported by Anthropic?**  
No. This is an unofficial community tool that interacts with Claude Code's local credential storage.

---

## Contributing

Issues and PRs are welcome. Keep it simple — the goal is a single-file script with no dependencies beyond the Python standard library and macOS `security`.

---

## License

MIT
