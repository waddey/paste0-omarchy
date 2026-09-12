# paste0 for Omarchy

A bar widget that pastes the clipboard to [paste0.com](https://paste0.com) and copies the URL back.

Left click opens a small panel. Middle click creates immediately. Right click copies the last URL. Pastes are always unlisted.

Plugins run as unsandboxed code inside the long-lived `omarchy-shell` process. Read the files before you enable them. See the [Omarchy shell plugins](https://github.com/omacom/omarchy/blob/quattro/manual/32-shell-plugins.md) manual.

## Install

```sh
omarchy plugin add https://github.com/waddey/paste0-omarchy.git --enable
```

Needs `python3`, `wl-paste`, and `wl-copy`. No pip, no Node, no extra daemon.

Check the folder the same way the shell does:

```sh
omarchy plugin validate ~/.config/omarchy/plugins/com.paste0.paste
```

## Usage

- Click **paste0** to preview the clipboard, pick expiry / burn, then Create
- Middle-click the pill to create from the clipboard without extra clicks
- Right-click copies the last URL
- Escape closes the panel
- `1`–`5` set expiry (10m, 1h, 1d, 1w, 1mo); `b` toggles burn after read; Enter creates; `y` copies the URL
- After create, tap **+** (bottom right) to reveal delete / edit codes when the API returns them; tap a code to copy; `+` / `=` toggles

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
  "burn": false,
  "copyUrl": true
}
```

Expiry values: `10min`, `1hour`, `1day`, `1week`, `1month`. Set `burn` to `true` for burn-after-read by default.

The helper POSTs JSON to `/api` with `X-Paste0-Client: omarchy`. It never uses `/api/paste` (that path is CSRF-gated). Optional field `b` enables burn after read. Successful creates may include `delete_code` and `edit_code`.

## Remove

```sh
omarchy plugin remove com.paste0.paste
```
