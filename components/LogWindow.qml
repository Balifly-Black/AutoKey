import QtQuick
import QtQuick.Controls
import "controls"

Window {
    id: logWindow

    required property var rootWindow

    // 日志窗口默认尺寸
    width: 700
    height: 500
    minimumWidth: 500
    minimumHeight: 350
    color: rootWindow.panelColor
    flags: Qt.Window | Qt.FramelessWindowHint
    title: qsTr("AutoKey 日志")

    // 最大日志条数，防止内存无限增长
    readonly property int maxLogEntries: 10000

    // 四个等级独立开关（true=显示）
    property bool showError: true
    property bool showWarn: true
    property bool showInfo: true
    property bool showDebug: true

    function appendLog(message) {
        while (logModel.count >= maxLogEntries) {
            logModel.remove(0)
        }
        // 从格式化前缀 "[LEVEL] ..." 提取等级
        var level = 2  // 默认 INFO
        if (message.startsWith("[ERROR]"))      level = 0
        else if (message.startsWith("[WARN ]")) level = 1
        else if (message.startsWith("[INFO ]")) level = 2
        else if (message.startsWith("[DEBUG]")) level = 3
        logModel.append({
            timestamp: Qt.formatDateTime(new Date(), "HH:mm:ss.zzz"),
            message: message,
            level: level
        })
    }

    // 委托用：检查某等级是否可见
    function isLevelVisible(level) {
        switch (level) {
            case 0: return showError
            case 1: return showWarn
            case 2: return showInfo
            case 3: return showDebug
        }
        return true
    }

    function showLog() {
        show()
        requestActivate()
        Qt.callLater(() => {
            x = rootWindow.x + rootWindow.width + 10
            y = rootWindow.y
            // show() 后原生 HWND 已创建，清除 Windows owner → 主窗口最小化不影响本窗口
            AcrylicWindow.detachWindow(logWindow)
        })
    }

    // 置顶切换
    property bool pinned: false

    function togglePinned() {
        pinned = !pinned
        if (pinned) {
            flags = Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        } else {
            flags = Qt.Window | Qt.FramelessWindowHint
        }
    }

    // Win11 亚克力圆角边框
    onVisibleChanged: {
        if (visible)
            Qt.callLater(() => AcrylicWindow.enableBorder(logWindow))
    }

    // ====== 标题栏 ======
    Rectangle {
        id: titleBar

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: AppConfig.titleBarHeight
        color: rootWindow.titleBarColor

        // 拖拽移动 + 双击最大化
        MouseArea {
            anchors.fill: parent
            onPressed: logWindow.startSystemMove()
            onDoubleClicked: {
                if (logWindow.visibility === Window.Maximized)
                    logWindow.showNormal()
                else
                    logWindow.showMaximized()
            }
        }

        // 左侧标题："日志"
        Label {
            id: titleLabel
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("日志")
            color: rootWindow.textColor
            font.family: Fonts.titleFamily
            font.pixelSize: 20
        }

        // 标题右侧：等级过滤按钮
        Row {
            anchors.left: titleLabel.right
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // ERROR — 红色填充（和关闭功能键同色）
            Rectangle {
                id: errorChip
                property bool hovered: false
                width: 50
                height: 22
                radius: 4
                color: AppConfig.dangerColor
                opacity: logWindow.showError ? 1.0 : 0.25
                border.color: hovered
                              ? AppConfig.logErrorBorderHoverColor
                              : AppConfig.logErrorBorderColor
                border.width: 1

                Behavior on opacity {
                    NumberAnimation { duration: AppConfig.animDurationFast }
                }
                Behavior on border.color {
                    ColorAnimation { duration: AppConfig.animDurationFast }
                }

                Label {
                    anchors.centerIn: parent
                    text: "ERROR"
                    color: AppConfig.logChipTextColor
                    font.pixelSize: 10
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: errorChip.hovered = true
                    onExited: errorChip.hovered = false
                    onClicked: logWindow.showError = !logWindow.showError
                }
            }

            // WARN — 黄色填充（和最小化功能键同色）
            Rectangle {
                id: warnChip
                property bool hovered: false
                width: 50
                height: 22
                radius: 4
                color: AppConfig.warningColor
                opacity: logWindow.showWarn ? 1.0 : 0.25
                border.color: hovered
                              ? AppConfig.logWarningBorderHoverColor
                              : AppConfig.minimizeBtnBorder
                border.width: 1

                Behavior on opacity {
                    NumberAnimation { duration: AppConfig.animDurationFast }
                }
                Behavior on border.color {
                    ColorAnimation { duration: AppConfig.animDurationFast }
                }

                Label {
                    anchors.centerIn: parent
                    text: "WARN"
                    color: AppConfig.logChipTextColor
                    font.pixelSize: 10
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: warnChip.hovered = true
                    onExited: warnChip.hovered = false
                    onClicked: logWindow.showWarn = !logWindow.showWarn
                }
            }

            // INFO — 绿色填充（和最大化功能键同色）
            Rectangle {
                id: infoChip
                property bool hovered: false
                width: 50
                height: 22
                radius: 4
                color: AppConfig.successColor
                opacity: logWindow.showInfo ? 1.0 : 0.25
                border.color: hovered
                              ? AppConfig.logInfoBorderHoverColor
                              : AppConfig.maximizeBtnBorder
                border.width: 1

                Behavior on opacity {
                    NumberAnimation { duration: AppConfig.animDurationFast }
                }
                Behavior on border.color {
                    ColorAnimation { duration: AppConfig.animDurationFast }
                }

                Label {
                    anchors.centerIn: parent
                    text: "INFO"
                    color: AppConfig.logChipTextColor
                    font.pixelSize: 10
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: infoChip.hovered = true
                    onExited: infoChip.hovered = false
                    onClicked: logWindow.showInfo = !logWindow.showInfo
                }
            }

            // DEBUG — 灰色填充
            Rectangle {
                id: debugChip
                property bool hovered: false
                width: 46
                height: 22
                radius: 4
                color: AppConfig.logDebugChipColor
                opacity: logWindow.showDebug ? 1.0 : 0.25
                border.color: hovered
                              ? AppConfig.logDebugBorderHoverColor
                              : AppConfig.logDebugBorderColor
                border.width: 1

                Behavior on opacity {
                    NumberAnimation { duration: AppConfig.animDurationFast }
                }
                Behavior on border.color {
                    ColorAnimation { duration: AppConfig.animDurationFast }
                }

                Label {
                    anchors.centerIn: parent
                    text: "DEBUG"
                    color: AppConfig.logChipTextColor
                    font.pixelSize: 10
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: debugChip.hovered = true
                    onExited: debugChip.hovered = false
                    onClicked: logWindow.showDebug = !logWindow.showDebug
                }
            }
        }

        // 右侧：置顶按钮 + 分隔符 + 三大窗口控制按钮
        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 18
            spacing: 10

            // 置顶按钮
            Rectangle {
                width: 24
                height: 24
                radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: pinArea.containsMouse || logWindow.pinned
                       ? rootWindow.menuHoverColor
                       : rootWindow.titleBarColor

                Behavior on color {
                    enabled: pinArea.containsMouse || logWindow.pinned
                    ColorAnimation { duration: AppConfig.animDurationFast }
                }

                Image {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    source: "../icons/common/" + rootWindow.navIconTheme
                            + "/riLine-pushpin-2-line.svg"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                MouseArea {
                    id: pinArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: logWindow.togglePinned()
                }
            }

            // 分隔符
            Rectangle {
                width: 1
                height: 18
                anchors.verticalCenter: parent.verticalCenter
                color: rootWindow.borderColor
                opacity: 0.45
            }

            // 最小化按钮 — 黄色
            Rectangle {
                width: AppConfig.windowButtonSize
                height: AppConfig.windowButtonSize
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: minimizeArea.containsMouse
                       ? AppConfig.warningHoverColor
                       : AppConfig.warningColor
                border.color: AppConfig.minimizeBtnBorder
                border.width: 1

                MouseArea {
                    id: minimizeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.ArrowCursor
                    onClicked: logWindow.showMinimized()
                }
            }

            // 最大化按钮 — 绿色
            Rectangle {
                width: AppConfig.windowButtonSize
                height: AppConfig.windowButtonSize
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: maximizeArea.containsMouse
                       ? AppConfig.successHoverColor
                       : AppConfig.successColor
                border.color: AppConfig.maximizeBtnBorder
                border.width: 1

                MouseArea {
                    id: maximizeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.ArrowCursor
                    onClicked: {
                        if (logWindow.visibility === Window.Maximized)
                            logWindow.showNormal()
                        else
                            logWindow.showMaximized()
                    }
                }
            }

            // 关闭按钮 — 红色（隐藏窗口而非销毁）
            Rectangle {
                width: AppConfig.windowButtonSize
                height: AppConfig.windowButtonSize
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: closeArea.containsMouse
                       ? AppConfig.dangerHoverColor
                       : AppConfig.dangerColor
                border.color: AppConfig.closeBtnBorder
                border.width: 1

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.ArrowCursor
                    onClicked: logWindow.hide()
                }
            }
        }
    }

    // ====== 日志列表区域 ======
    ListView {
        id: logListView

        anchors.top: titleBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        spacing: 0
        boundsBehavior: Flickable.StopAtBounds

        // 自动滚动控制：用户手动上滚时暂停，滚回底部时恢复
        property bool shouldAutoScroll: true

        onContentYChanged: {
            if (atYEnd) {
                shouldAutoScroll = true
            } else if (moving || flicking) {
                shouldAutoScroll = false
            }
        }

        model: ListModel {
            id: logModel
        }

        delegate: Item {
            width: logListView.width
            property bool isVisible: logWindow.isLevelVisible(model.level)
            height: isVisible ? Math.max(22, messageLabel.implicitHeight + 4) + 2 : 0
            visible: isVisible

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                // 时间戳
                Label {
                    id: timeLabel
                    anchors.verticalCenter: parent.verticalCenter
                    text: model.timestamp
                    color: rootWindow.mutedTextColor
                    font.family: Fonts.codeFamily
                    font.pixelSize: 12
                }

                // 日志内容
                Label {
                    id: messageLabel
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(10, parent.width - timeLabel.width - parent.spacing)
                    text: model.message
                    color: rootWindow.textColor
                    font.family: Fonts.codeFamily
                    font.pixelSize: 13
                    wrapMode: Text.WrapAnywhere
                    textFormat: Text.PlainText
                }
            }
        }

        // 空状态占位
        Label {
            anchors.centerIn: parent
            text: qsTr("暂无日志")
            color: rootWindow.mutedTextColor
            font.pixelSize: 14
            visible: logModel.count === 0
        }

        ScrollBar.vertical: AppScrollBar {
            rootWindow: logWindow.rootWindow
        }

        // 新日志自动滚动到底部（仅在用户未手动上滚时）
        Connections {
            target: logModel
            function onCountChanged() {
                if (logListView.shouldAutoScroll)
                    Qt.callLater(() => logListView.positionViewAtEnd())
            }
        }
    }

    // ====== 窗口缩放边框 ======
    // 注意：ResizeBorder 自身有 required property rootWindow，在其实例化花括号内
    // "rootWindow" 始终解析为 ResizeBorder 的属性，而非外层 Window 的同名属性。
    // 因此 width/height 必须使用 AppConfig.resizeBorderWidth（或 logWindow.rootWindow.resizeBorderWidth），
    // 不能裸写 rootWindow.resizeBorderWidth（会解析到 logWindow 上，该属性不存在 → 0 → 边框不可见）。
    //
    // 四条边（水平/垂直缩放）
    ResizeBorder {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: AppConfig.resizeBorderWidth
        edge: Qt.LeftEdge
        rootWindow: logWindow
    }

    ResizeBorder {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: AppConfig.resizeBorderWidth
        edge: Qt.RightEdge
        rootWindow: logWindow
    }

    ResizeBorder {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: AppConfig.resizeBorderWidth
        edge: Qt.TopEdge
        rootWindow: logWindow
    }

    ResizeBorder {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: AppConfig.resizeBorderWidth
        edge: Qt.BottomEdge
        rootWindow: logWindow
    }

    // 四个角（对角线缩放，必须在边之后声明以确保 z 序在上层）
    ResizeBorder {
        anchors.left: parent.left
        anchors.top: parent.top
        width: AppConfig.resizeBorderWidth
        height: AppConfig.resizeBorderWidth
        edge: Qt.LeftEdge | Qt.TopEdge
        rootWindow: logWindow
    }

    ResizeBorder {
        anchors.right: parent.right
        anchors.top: parent.top
        width: AppConfig.resizeBorderWidth
        height: AppConfig.resizeBorderWidth
        edge: Qt.RightEdge | Qt.TopEdge
        rootWindow: logWindow
    }

    ResizeBorder {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: AppConfig.resizeBorderWidth
        height: AppConfig.resizeBorderWidth
        edge: Qt.LeftEdge | Qt.BottomEdge
        rootWindow: logWindow
    }

    ResizeBorder {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: AppConfig.resizeBorderWidth
        height: AppConfig.resizeBorderWidth
        edge: Qt.RightEdge | Qt.BottomEdge
        rootWindow: logWindow
    }
}
