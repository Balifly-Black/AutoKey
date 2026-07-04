import QtQuick
import QtQuick.Controls
import QtQml
import QtMultimedia
import "controls"

Window {
    id: floatingWindow

    required property var rootWindow
    property var configs: []
    property bool engineRunning: false
    property bool enginePaused: false
    property int elapsedMs: 0
    property double accumulatedMs: 0
    property double runningSince: 0
    readonly property int contentMargin: 6
    readonly property color mainRowColor: rootWindow.darkMode
                                         ? AppConfig.floatingStatusMainRowDark
                                         : AppConfig.floatingStatusMainRowLight
    readonly property color toggleAreaColor: rootWindow.darkMode
                                           ? AppConfig.floatingStatusToggleAreaDark
                                           : AppConfig.floatingStatusToggleAreaLight
    readonly property var visibleConfigs: configs.filter(config => config.enabled)
    // 提示音开关：key = configTitle 或 configTitle + "\n" + toggleName
    // value = { enabled: bool, onSound: "on.mp3", offSound: "off.mp3" }
    // 左键点击切换 enabled，同时触发对应的开关提示音
    property var notifyStates: ({})

    signal pauseResumeRequested()
    signal stopRequested()
    // 点击高级配置图标 → 触发屏幕识别扫描 + 叠加层展示
    signal recognitionCheckRequested(int configIndex)

    function toggleEntries(toggles, bindings) {
        const entries = []
        const source = toggles || ({})
        const triggerBindings = bindings || ({})
        const names = Object.keys(source).sort()
        for (let index = 0; index < names.length; ++index) {
            const name = names[index]
            entries.push({
                name: name,
                enabled: Boolean(source[name]),
                triggerKey: triggerBindings[name] || ""
            })
        }
        return entries
    }

    function formatElapsed(milliseconds) {
        const seconds = Math.floor(milliseconds / 1000)
        const hours = Math.floor(seconds / 3600)
        const minutes = Math.floor((seconds % 3600) / 60)
        const remainingSeconds = seconds % 60
        return String(hours).padStart(2, "0") + ":"
             + String(minutes).padStart(2, "0") + ":"
             + String(remainingSeconds).padStart(2, "0")
    }

    function startClock() {
        accumulatedMs = 0
        elapsedMs = 0
        runningSince = Date.now()
        elapsedTimer.start()
    }

    function pauseClock() {
        if (runningSince > 0)
            accumulatedMs += Date.now() - runningSince
        runningSince = 0
        elapsedMs = Math.floor(accumulatedMs)
        elapsedTimer.stop()
    }

    function resumeClock() {
        if (runningSince > 0)
            return
        runningSince = Date.now()
        elapsedTimer.start()
    }

    function finishAndHide() {
        pauseClock()
        hide()
    }

    function showStatus() {
        show()
        requestActivate()
        Qt.callLater(() => {
            AcrylicWindow.enable(floatingWindow)
            // show() 后原生 HWND 已创建，清除 Windows owner → 主窗口最小化不影响本窗口
            AcrylicWindow.detachWindow(floatingWindow)
        })
    }

    width: 240
    height: Math.min(390, windowHeader.height + statusColumn.implicitHeight + contentMargin)
    minimumHeight: windowHeader.height + contentMargin
    color: AppConfig.transparentColor
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus
    title: qsTr("AutoKey 运行状态")

    onEngineRunningChanged: {
        if (engineRunning)
            startClock()
        else
            finishAndHide()
    }
    onEnginePausedChanged: {
        if (!engineRunning)
            return
        if (enginePaused)
            pauseClock()
        else
            resumeClock()
    }
    onVisibleChanged: {
        if (visible)
            Qt.callLater(() => AcrylicWindow.enable(floatingWindow))
    }
    onWidthChanged: {
        if (visible)
            AcrylicWindow.enable(floatingWindow)
    }
    onHeightChanged: {
        if (visible)
            AcrylicWindow.enable(floatingWindow)
    }

    MediaPlayer {
        id: notifyPlayer
        audioOutput: AudioOutput {
            // 音量由设置页维护为 0-100，这里转换成 Qt Multimedia 需要的 0.0-1.0。
            volume: Math.max(0, Math.min(1, floatingWindow.rootWindow.notificationVolume / 100))
        }
    }

    // ── 提示音设置窗口 ──

    function showNotifySettings(btn) {
        notifySettingsWindow.pendingOnSound = btn.onFile
        notifySettingsWindow.pendingOffSound = btn.offFile
        notifySettingsWindow.notifyBtn = btn
        const targetScreen = floatingWindow.screen
        const availableX = targetScreen ? targetScreen.virtualX : 0
        const availableY = targetScreen ? targetScreen.virtualY : 0
        const availableWidth = targetScreen
                             ? targetScreen.desktopAvailableWidth
                             : Screen.desktopAvailableWidth
        const availableHeight = targetScreen
                              ? targetScreen.desktopAvailableHeight
                              : Screen.desktopAvailableHeight
        const preferredX = floatingWindow.x + floatingWindow.width + 8
        const preferredY = floatingWindow.y
        notifySettingsWindow.x = Math.max(
            availableX,
            Math.min(preferredX,
                     availableX + availableWidth - notifySettingsWindow.width))
        notifySettingsWindow.y = Math.max(
            availableY,
            Math.min(preferredY,
                     availableY + availableHeight - notifySettingsWindow.height))
        notifySettingsWindow.show()
        notifySettingsWindow.requestActivate()
    }

    Window {
        id: notifySettingsWindow

        flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        transientParent: floatingWindow
        width: 200
        height: settingsHeader.height + contentTopMargin
                + contentColumn.implicitHeight + contentBottomMargin
        color: surfaceColor
        visible: false

        readonly property int contentTopMargin: 2
        readonly property int contentBottomMargin: 12
        property var notifyBtn: null
        property string pendingOnSound: "on.mp3"
        property string pendingOffSound: "off.mp3"
        readonly property string targetName: notifyBtn
                                             ? notifyBtn.notifyKey.split("\n").pop()
                                             : ""
        readonly property color surfaceColor: rootWindow.darkMode
                                               ? AppConfig.darkPanelColor
                                               : AppConfig.lightPanelColor
        readonly property color optionColor: rootWindow.darkMode
                                              ? AppConfig.configCardColorDark
                                              : AppConfig.configCardColorLight
        readonly property color optionHoverColor: rootWindow.darkMode
                                                   ? AppConfig.notifyOptionHoverDark
                                                   : AppConfig.notifyOptionHoverLight
        readonly property color optionBorderColor: rootWindow.darkMode
                                                    ? AppConfig.cardBorderColorDark
                                                    : AppConfig.cardBorderColorLight

        onVisibleChanged: {
            if (visible)
                Qt.callLater(() => AcrylicWindow.enableBorder(notifySettingsWindow))
        }

        function commitSounds() {
            if (!notifyBtn)
                return

            const cur = floatingWindow.notifyStates[notifyBtn.notifyKey]
            let ns = JSON.parse(JSON.stringify(floatingWindow.notifyStates))
            const enabled = cur === undefined ? true : cur.enabled
            ns[notifyBtn.notifyKey] = {
                enabled: enabled,
                onSound: pendingOnSound,
                offSound: pendingOffSound
            }
            floatingWindow.notifyStates = ns
        }

        Rectangle {
            anchors.fill: parent
            color: notifySettingsWindow.surfaceColor

            Item {
                id: settingsHeader

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 36

                Label {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.right: settingsCloseButton.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("提示音[%1]").arg(notifySettingsWindow.targetName)
                    color: rootWindow.textColor
                    font.pixelSize: 15
                    font.bold: false
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.ArrowCursor
                    onPressed: notifySettingsWindow.startSystemMove()
                }

                Rectangle {
                    id: settingsCloseButton

                    width: 14
                    height: 14
                    radius: width / 2
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: settingsCloseArea.containsMouse
                           ? AppConfig.dangerHoverColor
                           : AppConfig.dangerColor
                    border.color: AppConfig.closeBtnBorder
                    border.width: 1

                    MouseArea {
                        id: settingsCloseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.ArrowCursor
                        onClicked: notifySettingsWindow.close()
                    }
                }
            }

            Column {
                id: contentColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: settingsHeader.bottom
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.topMargin: notifySettingsWindow.contentTopMargin
                spacing: 8

                // ── 开音效 ──
                Label {
                    text: qsTr("开启")
                    font.bold: false
                    font.pixelSize: 13
                    color: rootWindow.mutedTextColor
                }

                ListView {
                    id: onListView
                    width: parent.width
                    height: Math.min(count * 28 + Math.max(0, count - 1) * spacing, 124)
                    model: PreferencesStore.mediaFiles()
                    clip: true
                    interactive: count > 4
                    spacing: 4

                    delegate: Rectangle {
                        required property string modelData
                        width: onListView.width
                        height: 28
                        radius: 4
                        color: itemArea.containsMouse
                               ? notifySettingsWindow.optionHoverColor
                               : notifySettingsWindow.optionColor
                        border.color: modelData === notifySettingsWindow.pendingOnSound
                                      ? AppConfig.accentColor
                                      : notifySettingsWindow.optionBorderColor
                        border.width: 1

                        Behavior on color {
                            ColorAnimation { duration: AppConfig.animDurationFast }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: AppConfig.animDurationFast }
                        }

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            text: modelData
                            color: rootWindow.textColor
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: itemArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                notifySettingsWindow.pendingOnSound = modelData
                                notifySettingsWindow.commitSounds()
                            }
                        }
                    }
                }

                // ── 关音效 ──
                Label {
                    text: qsTr("关闭")
                    font.bold: false
                    font.pixelSize: 13
                    color: rootWindow.mutedTextColor
                }

                ListView {
                    id: offListView
                    width: parent.width
                    height: Math.min(count * 28 + Math.max(0, count - 1) * spacing, 124)
                    model: PreferencesStore.mediaFiles()
                    clip: true
                    interactive: count > 4
                    spacing: 4

                    delegate: Rectangle {
                        required property string modelData
                        width: offListView.width
                        height: 28
                        radius: 4
                        color: itemArea2.containsMouse
                               ? notifySettingsWindow.optionHoverColor
                               : notifySettingsWindow.optionColor
                        border.color: modelData === notifySettingsWindow.pendingOffSound
                                      ? AppConfig.accentColor
                                      : notifySettingsWindow.optionBorderColor
                        border.width: 1

                        Behavior on color {
                            ColorAnimation { duration: AppConfig.animDurationFast }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: AppConfig.animDurationFast }
                        }

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            text: modelData
                            color: rootWindow.textColor
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: itemArea2
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                notifySettingsWindow.pendingOffSound = modelData
                                notifySettingsWindow.commitSounds()
                            }
                        }
                    }
                }
            }
        }
    }

    // ── 提示音播放 ──
    function notifyStateChanged(key, newState) {
        const ns = floatingWindow.notifyStates[key]
        // 未显式关闭就视为开启，使用默认 on.mp3 / off.mp3
        if (ns !== undefined && !ns.enabled)
            return
        const onFile = (ns === undefined || !ns.onSound) ? "on.mp3" : ns.onSound
        const offFile = (ns === undefined || !ns.offSound) ? "off.mp3" : ns.offSound
        const fileName = newState ? onFile : offFile
        const url = PreferencesStore.mediaFileUrl(fileName)
        if (url.length > 0) {
            notifyPlayer.stop()
            notifyPlayer.source = url
            notifyPlayer.play()
        }
    }

    Timer {
        id: elapsedTimer
        interval: 200
        repeat: true
        onTriggered: floatingWindow.elapsedMs = Math.floor(
                         floatingWindow.accumulatedMs + Date.now() - floatingWindow.runningSince)
    }

    Rectangle {
        anchors.fill: parent
        color: floatingWindow.rootWindow.acrylicPanelColor

        Item {
            id: windowHeader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 38

            MouseArea {
                anchors.fill: parent
                onPressed: floatingWindow.startSystemMove()
            }

            Item {
                id: pauseResumeButton
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28

                Rectangle {
                    anchors.fill: parent
                    radius: 5
                    color: pauseResumeArea.containsMouse
                           ? floatingWindow.mainRowColor
                           : AppConfig.transparentColor
                }

                Image {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: floatingWindow.enginePaused
                            ? "../icons/common/other/riFill-play-fill 1.svg"
                            : "../icons/common/other/riFill-pause-fill.svg"
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: pauseResumeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: floatingWindow.pauseResumeRequested()
                }
            }

            Item {
                anchors.left: pauseResumeButton.right
                anchors.leftMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28

                Rectangle {
                    anchors.fill: parent
                    radius: 5
                    color: stopArea.containsMouse
                           ? floatingWindow.mainRowColor
                           : AppConfig.transparentColor
                }

                Image {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: "../icons/common/other/riFill-stop-fill 1.svg"
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: stopArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: floatingWindow.stopRequested()
                }
            }

            Label {
                anchors.right: parent.right
                anchors.rightMargin: 13
                anchors.verticalCenter: parent.verticalCenter
                text: floatingWindow.formatElapsed(floatingWindow.elapsedMs)
                color: floatingWindow.rootWindow.textColor
                font.pixelSize: 14
                font.weight: Font.Medium
            }
        }

        Flickable {
            id: statusFlickable
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: windowHeader.bottom
            anchors.bottom: parent.bottom
            anchors.leftMargin: floatingWindow.contentMargin
            anchors.rightMargin: floatingWindow.contentMargin
            anchors.bottomMargin: floatingWindow.contentMargin
            contentWidth: width
            contentHeight: statusColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            ScrollBar.vertical: AppScrollBar {
                rootWindow: floatingWindow.rootWindow
            }

            Column {
                id: statusColumn
                width: statusFlickable.width
                spacing: 6

                Label {
                    visible: floatingWindow.visibleConfigs.length === 0
                    width: parent.width
                    height: 40
                    text: qsTr("暂无配置")
                    color: floatingWindow.rootWindow.mutedTextColor
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Repeater {
                    model: floatingWindow.visibleConfigs

                    Rectangle {
                        id: configCard
                        required property var modelData
                        readonly property var toggleItems: floatingWindow.toggleEntries(
                                                               modelData.toggles,
                                                               modelData.toggleBindings)

                        width: statusColumn.width
                        height: 34 + toggleItems.length * 24
                        radius: 6
                        color: floatingWindow.toggleAreaColor
                        clip: true

                        Rectangle {
                            z: 1
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.leftMargin: 1
                            anchors.rightMargin: 1
                            anchors.topMargin: 1
                            height: 32
                            radius: 5
                            color: floatingWindow.mainRowColor

                            Item {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 22
                                height: 22

                                Image {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    source: "../icons/common/" + floatingWindow.rootWindow.navIconTheme
                                            + "/" + configCard.modelData.iconName
                                    fillMode: Image.PreserveAspectFit
                                }

                                // 高级配置图标可点击触发识别扫描
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: configCard.modelData.isAdvanced
                                                 ? Qt.PointingHandCursor
                                                 : Qt.ArrowCursor
                                    enabled: configCard.modelData.isAdvanced
                                    hoverEnabled: configCard.modelData.isAdvanced
                                    onClicked: {
                                        floatingWindow.recognitionCheckRequested(
                                            configCard.modelData.configIndex)
                                    }
                                }
                            }

                            Label {
                                anchors.left: parent.left
                                anchors.leftMargin: 35
                                anchors.right: configKeyBadge.left
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                text: configCard.modelData.title
                                color: floatingWindow.rootWindow.textColor
                                font.pixelSize: 14
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                id: configKeyBadge

                                visible: String(configCard.modelData.switchKey || "").length > 0
                                anchors.right: configNotifyBtn.left
                                anchors.rightMargin: configNotifyBtn.visible ? 4 : 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: visible ? configKeyBadgeText.implicitWidth + 10 : 0
                                height: 16
                                radius: 4
                                color: AppConfig.transparentColor
                                border.color: floatingWindow.rootWindow.mutedTextColor
                                border.width: 1

                                Label {
                                    id: configKeyBadgeText

                                    anchors.centerIn: parent
                                    text: configCard.modelData.switchKey || ""
                                    color: floatingWindow.rootWindow.mutedTextColor
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            Item {
                                id: configNotifyBtn

                                anchors.right: configState.left
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20
                                height: 20

                                readonly property string notifyKey: configCard.modelData.title
                                readonly property var notifyState: floatingWindow.notifyStates[notifyKey]
                                readonly property bool notifyEnabled: notifyState === undefined ? true : notifyState.enabled

                                readonly property string onFile: (notifyState === undefined || !notifyState.onSound)
                                                                ? "on.mp3" : notifyState.onSound
                                readonly property string offFile: (notifyState === undefined || !notifyState.offSound)
                                                                 ? "off.mp3" : notifyState.offSound

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 3
                                    color: configNotifyArea.containsMouse
                                           ? floatingWindow.mainRowColor
                                           : AppConfig.transparentColor
                                }

                                Image {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    source: "../icons/common/" + floatingWindow.rootWindow.navIconTheme
                                            + "/" + (configNotifyBtn.notifyEnabled
                                                     ? "riLine-notification-line.svg"
                                                     : "riLine-notification-off-line.svg")
                                    fillMode: Image.PreserveAspectFit
                                }

                                MouseArea {
                                    id: configNotifyArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: mouse => {
                                        if (mouse.button === Qt.RightButton) {
                                            showNotifySettings(configNotifyBtn)
                                        } else {
                                            const cur = floatingWindow.notifyStates[configNotifyBtn.notifyKey]
                                            let ns = JSON.parse(JSON.stringify(floatingWindow.notifyStates))
                                            if (cur === undefined) {
                                                ns[configNotifyBtn.notifyKey] = { enabled: false, onSound: "on.mp3", offSound: "off.mp3" }
                                            } else {
                                                ns[configNotifyBtn.notifyKey] = { enabled: !cur.enabled, onSound: cur.onSound || "on.mp3", offSound: cur.offSound || "off.mp3" }
                                            }
                                            floatingWindow.notifyStates = ns
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: configState
                                anchors.right: parent.right
                                anchors.rightMargin: 11
                                anchors.verticalCenter: parent.verticalCenter
                                width: 12
                                height: 12
                                radius: 6
                                color: configCard.modelData.active
                                       ? AppConfig.successColor
                                       : (configCard.modelData.enabled
                                          ? AppConfig.warningColor
                                          : AppConfig.dangerColor)
                                border.width: 1
                                border.color: Qt.lighter(configState.color, 1.1)
                            }
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.leftMargin: 1
                            anchors.rightMargin: 1
                            anchors.topMargin: 33

                            Repeater {
                                model: configCard.toggleItems

                                Rectangle {
                                    required property var modelData
                                    width: parent.width
                                    height: 24
                                    color: AppConfig.transparentColor

                                    Image {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 22
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 14
                                        height: 14
                                        source: "../icons/common/" + floatingWindow.rootWindow.navIconTheme
                                                + "/riFill-arrow-right-s-fill 1.svg"
                                        fillMode: Image.PreserveAspectFit
                                    }

                                    Label {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 40
                                        anchors.right: toggleKeyBadge.left
                                        anchors.rightMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.name
                                        color: floatingWindow.rootWindow.textColor
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        id: toggleKeyBadge

                                        visible: modelData.triggerKey.length > 0
                                        anchors.right: toggleNotifyBtn.left
                                        anchors.rightMargin: toggleNotifyBtn.visible ? 4 : 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: visible ? toggleKeyBadgeText.implicitWidth + 10 : 0
                                        height: 16
                                        radius: 4
                                        color: AppConfig.transparentColor
                                        border.color: floatingWindow.rootWindow.mutedTextColor
                                        border.width: 1

                                        Label {
                                            id: toggleKeyBadgeText

                                            anchors.centerIn: parent
                                            text: modelData.triggerKey
                                            color: floatingWindow.rootWindow.mutedTextColor
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }

                                    Item {
                                        id: toggleNotifyBtn

                                        anchors.right: toggleState.left
                                        anchors.rightMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 20
                                        height: 20

                                        readonly property string notifyKey: configCard.modelData.title + "\n"
                                                                           + modelData.name
                                        readonly property var notifyState: floatingWindow.notifyStates[notifyKey]
                                        readonly property bool notifyEnabled: notifyState === undefined ? true : notifyState.enabled

                                        readonly property string onFile: (notifyState === undefined || !notifyState.onSound)
                                                                        ? "on.mp3" : notifyState.onSound
                                        readonly property string offFile: (notifyState === undefined || !notifyState.offSound)
                                                                         ? "off.mp3" : notifyState.offSound

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 3
                                            color: toggleNotifyArea.containsMouse
                                                   ? floatingWindow.mainRowColor
                                                   : AppConfig.transparentColor
                                        }

                                        Image {
                                            anchors.centerIn: parent
                                            width: 16
                                            height: 16
                                            source: "../icons/common/" + floatingWindow.rootWindow.navIconTheme
                                                    + "/" + (toggleNotifyBtn.notifyEnabled
                                                             ? "riLine-notification-line.svg"
                                                             : "riLine-notification-off-line.svg")
                                            fillMode: Image.PreserveAspectFit
                                        }

                                        MouseArea {
                                            id: toggleNotifyArea

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: mouse => {
                                                if (mouse.button === Qt.RightButton) {
                                                    showNotifySettings(toggleNotifyBtn)
                                                } else {
                                                    const cur = floatingWindow.notifyStates[toggleNotifyBtn.notifyKey]
                                                    let ns = JSON.parse(JSON.stringify(floatingWindow.notifyStates))
                                                    if (cur === undefined) {
                                                        ns[toggleNotifyBtn.notifyKey] = { enabled: false, onSound: "on.mp3", offSound: "off.mp3" }
                                                    } else {
                                                        ns[toggleNotifyBtn.notifyKey] = { enabled: !cur.enabled, onSound: cur.onSound || "on.mp3", offSound: cur.offSound || "off.mp3" }
                                                    }
                                                    floatingWindow.notifyStates = ns
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        id: toggleState
                                        anchors.right: parent.right
                                        anchors.rightMargin: 11
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 12
                                        height: 12
                                        radius: 6
                                        color: modelData.enabled
                                               ? AppConfig.successColor
                                               : AppConfig.dangerColor
                                        border.width: 1
                                        border.color: Qt.lighter(toggleState.color, 1.1)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

}
