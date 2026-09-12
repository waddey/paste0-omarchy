import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "com.paste0.paste"
  ipcTarget: "com.paste0.paste"
  manageIpc: false

  property var anchorItem: null
  property bool openedFromHotkey: false
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  readonly property string helperPath: String(Qt.resolvedUrl("bin/paste0-create")).replace(/^file:\/\//, "")
  readonly property string apiUrl: Model.normalizeApiUrl(setting("apiUrl", "https://paste0.com/api"))
  readonly property bool copyUrl: Model.boolish(setting("copyUrl", true), true)

  property string clipText: ""
  property bool clipReady: false
  property bool createAfterClip: false
  property bool creating: false
  property string pendingBody: ""
  property string expiry: Model.normalizeExpiry(setting("expiry", "1week"))
  property string lastUrl: ""
  property string statusText: ""
  property bool isAlert: false

  readonly property string label: "paste0"
  readonly property string tooltip: {
    if (isAlert && statusText)
      return statusText
    if (lastUrl)
      return lastUrl
    return "Paste clipboard to paste0.com"
  }

  readonly property color muted: Qt.darker(root.barForeground, 1.35)

  function open() {
    openedFromHotkey = false
    root.controller.show()
    root.prepare()
  }

  function openFromHotkey() {
    openedFromHotkey = true
    root.controller.show()
    root.prepare()
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    if (root.opened)
      root.close()
    else
      root.openFromHotkey()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function prepare() {
    expiry = Model.normalizeExpiry(setting("expiry", "1week"))
    isAlert = false
    if (!creating)
      statusText = ""
    refresh()
  }

  function refresh() {
    if (clipProc.running)
      return
    clipReady = false
    clipProc.running = true
  }

  function createFromClipboard() {
    createAfterClip = true
    if (!root.opened)
      root.controller.show()
    refresh()
  }

  function create() {
    var body = String(clipText || "")
    if (creating || createProc.running)
      return
    if (!body.replace(/^\s+|\s+$/g, "")) {
      statusText = "Clipboard is empty"
      isAlert = true
      return
    }
    pendingBody = body
    creating = true
    isAlert = false
    statusText = "Creating…"
    lastUrl = ""
    createProc.stdinEnabled = true
    createProc.command = ["python3", helperPath, apiUrl, expiry, "", "auto"]
    createProc.running = true
  }

  function copyLastUrl() {
    if (!lastUrl)
      return
    copyProc.command = ["wl-copy", lastUrl]
    copyProc.running = true
    statusText = "Copied"
    isAlert = false
  }

  function applyCreate(raw) {
    var parsed = Model.parseCreate(raw)
    creating = false
    pendingBody = ""
    if (parsed.ok) {
      lastUrl = parsed.url
      statusText = "Created"
      isAlert = false
      if (copyUrl)
        copyLastUrl()
      return
    }
    statusText = parsed.message || "Could not create paste"
    isAlert = true
  }

  IpcHandler {
    target: root.ipcTarget

    function open(): void {
      root.openFromHotkey()
    }
    function close(): void {
      root.close()
    }
    function show(): void {
      root.openFromHotkey()
    }
    function hide(): void {
      root.close()
    }
    function toggle(): void {
      root.toggle()
    }
    function refresh(): void {
      if (root.hostWidget && typeof root.hostWidget.broadcast === "function")
        root.hostWidget.broadcast("refresh")
      else
        root.refresh()
    }
    function create(): string {
      root.createFromClipboard()
      return "ok"
    }
  }

  Process {
    id: clipProc
    running: false
    command: ["wl-paste", "-n", "--type", "text"]
    stdout: StdioCollector {
      id: clipOut
      waitForEnd: true
    }
    onExited: function () {
      root.clipText = String(clipOut.text || "")
      root.clipReady = true
      if (root.createAfterClip) {
        root.createAfterClip = false
        root.create()
      }
    }
  }

  Process {
    id: createProc
    running: false
    command: []
    stdinEnabled: true
    stdout: StdioCollector {
      id: createOut
      waitForEnd: true
    }
    stderr: StdioCollector {
      id: createErr
      waitForEnd: true
    }
    onStarted: {
      createProc.write(root.pendingBody)
      createProc.stdinEnabled = false
    }
    onExited: function () {
      var raw = String(createOut.text || "")
      if (!raw)
        raw = String(createErr.text || "")
      root.applyCreate(raw)
    }
  }

  Process {
    id: copyProc
    running: false
    command: []
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function (direction) {
        root.switchPanel(direction)
      }
      onActivateRequested: root.create()
      onTextKey: function (t) {
        var map = {
          "1": "10min",
          "2": "1hour",
          "3": "1day",
          "4": "1week",
          "5": "1month"
        }
        if (map[t])
          root.expiry = map[t]
        else if (t === "y" || t === "Y")
          root.copyLastUrl()
        else if (t === "r" || t === "R")
          root.refresh()
      }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(10)

        Column {
          width: parent.width
          spacing: Style.space(2)

          Text {
            width: parent.width
            text: "paste0"
            textFormat: Text.PlainText
            color: root.barForeground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
            font.letterSpacing: 1
          }

          Text {
            width: parent.width
            text: root.clipReady ? Model.meta(root.clipText) : "Reading clipboard…"
            textFormat: Text.PlainText
            color: root.muted
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
        }

        Text {
          width: parent.width
          visible: root.clipReady && root.clipText !== ""
          text: Model.preview(root.clipText, 420, 7)
          textFormat: Text.PlainText
          wrapMode: Text.WrapAnywhere
          maximumLineCount: 8
          elide: Text.ElideRight
          color: root.muted
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.bodySmall
        }

        PanelSeparator {
          foreground: root.barForeground
        }

        Row {
          width: parent.width
          spacing: Style.space(14)

          Repeater {
            model: Model.expiryOptions()

            Text {
              required property var modelData
              text: modelData.label
              textFormat: Text.PlainText
              color: root.expiry === modelData.id ? root.barForeground : root.muted
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.body
              font.bold: root.expiry === modelData.id
              Accessible.role: Accessible.Button
              Accessible.name: "Expires " + modelData.label

              MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expiry = modelData.id
              }
            }
          }
        }

        Item {
          width: parent.width
          height: createLabel.implicitHeight

          Text {
            id: createLabel
            anchors.left: parent.left
            text: root.creating ? "Creating…" : "Create"
            textFormat: Text.PlainText
            color: root.barForeground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
            font.bold: true
            opacity: root.creating ? 0.6 : 1

            MouseArea {
              anchors.fill: parent
              anchors.margins: -4
              enabled: !root.creating
              cursorShape: Qt.PointingHandCursor
              onClicked: root.create()
            }
          }

          Text {
            anchors.right: parent.right
            anchors.verticalCenter: createLabel.verticalCenter
            visible: root.statusText !== ""
            text: Model.clean(root.statusText, 40)
            textFormat: Text.PlainText
            color: root.isAlert ? root.barForeground : root.muted
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
          }
        }

        Text {
          width: parent.width
          visible: root.lastUrl !== ""
          text: root.lastUrl
          textFormat: Text.PlainText
          wrapMode: Text.WrapAnywhere
          color: root.muted
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.copyLastUrl()
          }
        }
      }
    }
  }
}
