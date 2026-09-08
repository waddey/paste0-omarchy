// Pure parse/format helpers. Loaded by Panel.qml and by node if you want tests.
// Every string that reaches a QML Text goes through clean() first.

function clean(value, max) {
  var s = String(value === undefined || value === null ? "" : value)
  s = s.replace(/[<>]/g, "").replace(/[\x00-\x1f\x7f]/g, "")
  var cap = max || 64
  return s.length > cap ? s.slice(0, cap) : s
}

function cleanUrl(value) {
  var s = String(value || "").replace(/[\x00-\x1f\x7f<>]/g, "").trim()
  if (s.indexOf("https://") !== 0)
    return ""
  return s.length > 256 ? s.slice(0, 256) : s
}

function normalizeApiUrl(value) {
  var s = String(value || "").trim().replace(/\/+$/, "")
  if (s.indexOf("https://") !== 0)
    return "https://paste0.com/api"
  if (s.slice(-4) !== "/api")
    s += "/api"
  return s
}

function expiryOptions() {
  return [
    { id: "10min", label: "10m" },
    { id: "1hour", label: "1h" },
    { id: "1day", label: "1d" },
    { id: "1week", label: "1w" },
    { id: "1month", label: "1mo" }
  ]
}

function normalizeExpiry(value) {
  var s = String(value || "")
  var opts = expiryOptions()
  for (var i = 0; i < opts.length; i++) {
    if (opts[i].id === s)
      return s
  }
  return "1week"
}

function boolish(value, fallback) {
  if (value === true || value === "true" || value === 1 || value === "1")
    return true
  if (value === false || value === "false" || value === 0 || value === "0")
    return false
  return fallback === true
}

function preview(text, maxChars, maxLines) {
  var s = String(text || "").replace(/\r\n/g, "\n")
  var lines = s.split("\n")
  var capLines = maxLines || 8
  if (lines.length > capLines)
    s = lines.slice(0, capLines).join("\n") + "\n…"
  s = s.replace(/[<>]/g, "")
  var cap = maxChars || 480
  if (s.length > cap)
    s = s.slice(0, cap) + "…"
  return s
}

function meta(text) {
  var s = String(text || "")
  if (!s)
    return "Clipboard is empty"
  var lines = s.split(/\r\n|\n/).length
  var n = s.length
  var size = n < 1024 ? n + " B" : (Math.round(n / 102.4) / 10) + " KB"
  return size + " · " + lines + (lines === 1 ? " line" : " lines")
}

function parseCreate(raw) {
  var data
  try {
    data = JSON.parse(String(raw || ""))
  } catch (e) {
    return { ok: false, message: "Bad response" }
  }
  if (!data || typeof data !== "object")
    return { ok: false, message: "Bad response" }
  if (data.ok === true || data.ok === "true") {
    var url = cleanUrl(data.url)
    if (!url)
      return { ok: false, message: "No URL in response" }
    return {
      ok: true,
      id: clean(data.id, 32),
      url: url,
      raw: cleanUrl(data.raw)
    }
  }
  return {
    ok: false,
    message: clean(data.message || data.error || "Could not create paste", 200)
  }
}

if (typeof module !== "undefined") {
  module.exports = {
    clean: clean,
    cleanUrl: cleanUrl,
    normalizeApiUrl: normalizeApiUrl,
    expiryOptions: expiryOptions,
    normalizeExpiry: normalizeExpiry,
    boolish: boolish,
    preview: preview,
    meta: meta,
    parseCreate: parseCreate
  }
}
