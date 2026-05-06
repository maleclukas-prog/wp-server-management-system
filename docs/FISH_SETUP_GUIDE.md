# WSMS PRO v4.3 - Fish Setup Guide

## Requirements

- Fish installed (`sudo apt install fish`)
- WSMS installed using `installers/install_wsms.sh` or `installers/install_wsms_pl.sh`
- ClamAV installed to ensure all security-related commands listed in `wp-help` run correctly

## Automatic Setup

Installers append Fish aliases automatically when Fish is detected.

Reload config:

```fish
source ~/.config/fish/config.fish
```

## Verify

```fish
wp-help
wp-status
wp-hosts-sync
alias | grep wp-
```

Note: `wp-hosts-sync` updates a managed block in `/etc/hosts` and may request sudo.

Note: WSMS is an author-driven personal server management system and includes solutions used in the author's own server environment.

## Troubleshooting

- If aliases are missing, rerun installer or inspect `~/.config/fish/config.fish`.
- If Fish is not installed during install, installer skips Fish aliases and prints a tip.
- To preview uninstall cleanup actions without modifying files, run `bash tools/wsms-uninstall.sh --dry-run`.

## Optional: Make Fish Default

```bash
which fish
echo /usr/bin/fish | sudo tee -a /etc/shells
chsh -s /usr/bin/fish
```
