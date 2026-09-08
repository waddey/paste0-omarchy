# paste0 for Omarchy

A bar widget that pastes the clipboard to [paste0.com](https://paste0.com) and copies the URL back.

Left click opens a small panel. Middle click creates immediately. Right click copies the last URL. Pastes are always unlisted.

This folder is the plugin. `omarchy plugin add` expects a git repo with `manifest.json` at the root — publish this directory as its own repository, not the paste0.com website tree.

Plugins run as unsandboxed code inside the long-lived `omarchy-shell` process. Read the files before you enable them. See the [Omarchy shell plugins](https://github.com/omacom/omarchy/blob/quattro/manual/32-shell-plugins.md) manual.

## Install

```sh
omarchy plugin add https://github.com/YOURNAME/paste0-omarchy.git --enable
```

Or drop the folder in by hand:

```sh
cp -r omarchy-plugin ~/.config/omarchy/plugins/com.paste0.paste
omarchy-shell shell rescanPlugins
omarchy plugin enable com.paste0.paste
```

Needs `python3`, `wl-paste`, and `wl-copy`. No pip, no Node, no extra daemon.

Check the folder the same way the shell does:

```sh
omarchy plugin validate ~/.config/omarchy/plugins/com.paste0.paste
```

## Usage

- Click **paste0** to preview the clipboard, pick expiry, then Create
- Middle-click the pill to create from the clipboard without extra clicks
- Right-click copies the last URL
- Escape closes the panel
- `1`–`5` set expiry (10m, 1h, 1d, 1w, 1mo); Enter creates; `y` copies the URL

Summon from the shell:

```sh
omarchy-shell shell summon com.paste0.paste '{}'
omarchy-shell shell call com.paste0.paste create
```

## Configure

The pill lands on the right. Move it with:

```sh
omarchy bar move com.paste0.paste --section right
```

Settings live inline on the bar layout entry in `~/.config/omarchy/shell.json`:

```json
{
  "id": "com.paste0.paste",
  "apiUrl": "https://paste0.com/api",
  "expiry": "1week",
  "copyUrl": true
}
```

Expiry values: `10min`, `1hour`, `1day`, `1week`, `1month`.

The helper POSTs JSON to `/api` with `X-Paste0-Client: omarchy`. It never uses `/api/paste` (that path is CSRF-gated).

## Remove

```sh
omarchy plugin remove com.paste0.paste
```
