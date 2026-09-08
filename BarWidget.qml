import QtQuick
import qs.Commons
import qs.Ui

// Bar host. Owns the slot and pill; Panel.qml owns clipboard, create, popup.
// Shape contract: shell summon/hide/toggle needs open/close/opened on this root.
BarWidget {
  id: root
  moduleName: "com.paste0.paste"

  function injectPanel() {
    var target = panelLoader.item
    if (!target)
      return
    if ("bar" in target)
      target.bar = root.bar
    if ("settings" in target)
      target.settings = root.settings
    if ("anchorItem" in target)
      target.anchorItem = button
    if ("hostWidget" in target)
      target.hostWidget = root
  }

  function refresh() {
    if (panelLoader.item && panelLoader.item.refresh)
      panelLoader.item.refresh()
  }

  function togglePanel() {
    if (panelLoader.item && panelLoader.item.toggle)
      panelLoader.item.toggle()
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item && panelLoader.item.openFromHotkey)
      panelLoader.item.openFromHotkey()
  }

  function close() {
    if (panelLoader.item && panelLoader.item.close)
      panelLoader.item.close()
  }

  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function closeForPopoutSwitch() {
    if (panelLoader.item)
      panelLoader.item.closeForPopoutSwitch()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: (root.bar && root.bar.vertical) ? "P0" : "paste0"
    fontSize: Style.font.caption
    horizontalMargin: 6
    active: panelLoader.item ? panelLoader.item.isAlert === true : false
    tooltipText: panelLoader.item ? panelLoader.item.tooltip : "Paste clipboard to paste0.com"
    Accessible.role: Accessible.Button
    Accessible.name: root.opened ? "Close paste0" : "Open paste0"

    onPressed: function (b) {
      if (!panelLoader.item)
        return
      if (b === Qt.MiddleButton)
        panelLoader.item.createFromClipboard()
      else if (b === Qt.RightButton)
        panelLoader.item.copyLastUrl()
      else
        root.togglePanel()
    }
  }
}
