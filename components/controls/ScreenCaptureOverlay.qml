import QtQuick
import QtQuick.Controls

Window {
    id: captureOverlay

    required property var controller
    required property var rootWindow
    property point dragStart: Qt.point(0, 0)
    property bool dragging: false
    property bool hasSelection: false
    property real savedSelectionX: 0
    property real savedSelectionY: 0
    property real savedSelectionWidth: 0
    property real savedSelectionHeight: 0
    readonly property real selectionX: dragging
                                            ? Math.min(dragStart.x, captureMouse.mouseX)
                                            : savedSelectionX
    readonly property real selectionY: dragging
                                            ? Math.min(dragStart.y, captureMouse.mouseY)
                                            : savedSelectionY
    readonly property real selectionWidth: dragging
                                                ? Math.abs(captureMouse.mouseX - dragStart.x)
                                                : savedSelectionWidth
    readonly property real selectionHeight: dragging
                                                 ? Math.abs(captureMouse.mouseY - dragStart.y)
                                                 : savedSelectionHeight

    x: controller.virtualX
    y: controller.virtualY
    width: controller.virtualWidth
    height: controller.virtualHeight
    visible: controller.active
    color: AppConfig.transparentColor
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    // 选择层必须独立于已隐藏的主窗口，否则部分平台会连带隐藏 transient 子窗口。
    transientParent: null

    onVisibleChanged: {
        if (visible) {
            // 每次进入截图都从空选区开始，避免沿用上一次框选结果。
            dragging = false
            hasSelection = false
            requestActivate()
            Qt.callLater(() => captureMouse.forceActiveFocus())
        } else if (!rootWindow.visible) {
            // 截图完成或取消后恢复主窗口及键盘焦点。
            rootWindow.show()
            rootWindow.requestActivate()
        }
    }

    Rectangle {
        id: fullMask

        anchors.fill: parent
        // 截图产生选区后改用四块遮罩，为选区内部留出透明窗口。
        visible: controller.mode === "pixel"
                 || (!captureOverlay.dragging && !captureOverlay.hasSelection)
        color: AppConfig.screenCaptureOverlayColor
    }

    Item {
        id: selectionMasks

        anchors.fill: parent
        visible: controller.mode !== "pixel"
                 && (captureOverlay.dragging || captureOverlay.hasSelection)

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: Math.max(0, captureOverlay.selectionY)
            color: AppConfig.screenCaptureOverlayColor
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            y: captureOverlay.selectionY + captureOverlay.selectionHeight
            height: Math.max(0, parent.height - y)
            color: AppConfig.screenCaptureOverlayColor
        }

        Rectangle {
            x: 0
            y: captureOverlay.selectionY
            width: Math.max(0, captureOverlay.selectionX)
            height: captureOverlay.selectionHeight
            color: AppConfig.screenCaptureOverlayColor
        }

        Rectangle {
            x: captureOverlay.selectionX + captureOverlay.selectionWidth
            y: captureOverlay.selectionY
            width: Math.max(0, parent.width - x)
            height: captureOverlay.selectionHeight
            color: AppConfig.screenCaptureOverlayColor
        }
    }

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 24
        text: controller.mode === "pixel"
              ? qsTr("点击选择取点位置，Esc 取消")
              : (captureOverlay.hasSelection
                 ? qsTr("拖动可重新选择，Enter 确认，Esc 取消")
                 : (controller.mode === "region"
                    ? qsTr("拖动设置识别区域，Enter 确认，Esc 取消")
                    : qsTr("拖动选择截图区域，Enter 确认，Esc 取消")))
        color: AppConfig.whiteTextColor
        font.pixelSize: 16
        font.bold: true
    }

    Rectangle {
        id: selectionRect

        visible: captureOverlay.controller.mode !== "pixel"
                 && (captureOverlay.dragging || captureOverlay.hasSelection)
        x: captureOverlay.selectionX
        y: captureOverlay.selectionY
        width: captureOverlay.selectionWidth
        height: captureOverlay.selectionHeight
        // 选区内部保持完全透明，只显示主题色边框。
        color: AppConfig.transparentColor
        border.color: AppConfig.accentColor
        border.width: 1
    }

    MouseArea {
        id: captureMouse

        anchors.fill: parent
        focus: true
        cursorShape: Qt.CrossCursor
        hoverEnabled: true
        Keys.onPressed: event => {
            // 方向键每次将系统光标移动一个像素，便于结合放大镜精确定位。
            if (event.key === Qt.Key_Left)
                captureOverlay.controller.moveCursor(-1, 0)
            else if (event.key === Qt.Key_Right)
                captureOverlay.controller.moveCursor(1, 0)
            else if (event.key === Qt.Key_Up)
                captureOverlay.controller.moveCursor(0, -1)
            else if (event.key === Qt.Key_Down)
                captureOverlay.controller.moveCursor(0, 1)
            else
                return
            event.accepted = true
        }
        onPositionChanged: mouse => {
            // 一次跨语言调用取得完整 11×11 颜色矩阵，避免逐像素调用 C++。
            magnifier.pixels = captureOverlay.controller.magnifierPixels(
                Math.round(mouse.x), Math.round(mouse.y))
        }
        onPressed: mouse => {
            if (captureOverlay.controller.mode === "pixel") {
                // 取点模式单击即保存全局坐标与十六进制颜色。
                captureOverlay.controller.savePoint(
                    Math.round(mouse.x), Math.round(mouse.y))
                return
            }
            captureOverlay.dragStart = Qt.point(mouse.x, mouse.y)
            // 再次按下会立即开始替换已有选区。
            captureOverlay.hasSelection = false
            captureOverlay.dragging = true
        }
        onReleased: mouse => {
            if (!captureOverlay.dragging || captureOverlay.controller.mode === "pixel")
                return

            const left = Math.min(captureOverlay.dragStart.x, mouse.x)
            const top = Math.min(captureOverlay.dragStart.y, mouse.y)
            const width = Math.abs(mouse.x - captureOverlay.dragStart.x)
            const height = Math.abs(mouse.y - captureOverlay.dragStart.y)
            captureOverlay.dragging = false
            // 松开鼠标只记录选区，用户可继续重选，Enter 才会真正保存。
            captureOverlay.savedSelectionX = left
            captureOverlay.savedSelectionY = top
            captureOverlay.savedSelectionWidth = width
            captureOverlay.savedSelectionHeight = height
            captureOverlay.hasSelection = width >= 2 && height >= 2
        }
    }

    Canvas {
        id: magnifier

        readonly property int sampleCount: 11
        readonly property int pixelScale: 8
        property var pixels: []

        // 默认位于光标右下方，靠近屏幕边缘时翻转方向以保持完整可见。
        x: captureMouse.mouseX + width + 18 <= captureOverlay.width
           ? captureMouse.mouseX + 18
           : captureMouse.mouseX - width - 18
        y: captureMouse.mouseY + height + 18 <= captureOverlay.height
           ? captureMouse.mouseY + 18
           : captureMouse.mouseY - height - 18
        width: sampleCount * pixelScale + 2
        height: sampleCount * pixelScale + 2
        visible: captureOverlay.controller.active && pixels.length === 121

        onPixelsChanged: requestPaint()

        onPaint: {
            const context = getContext("2d")
            context.clearRect(0, 0, width, height)

            // 每个采样像素放大为 8×8 色块，保持最近邻的清晰边缘。
            for (let row = 0; row < sampleCount; ++row) {
                for (let column = 0; column < sampleCount; ++column) {
                    context.fillStyle = pixels[row * sampleCount + column]
                    context.fillRect(1 + column * pixelScale,
                                     1 + row * pixelScale,
                                     pixelScale,
                                     pixelScale)
                }
            }

            // 中心格保持原色，上下左右四个相邻像素格完整填充主题橙色。
            context.fillStyle = AppConfig.magnifierCrosshairColor
            const crosshairCells = [[5, 4], [5, 6], [4, 5], [6, 5]]
            for (let index = 0; index < crosshairCells.length; ++index) {
                const cell = crosshairCells[index]
                context.fillRect(1 + cell[0] * pixelScale,
                                 1 + cell[1] * pixelScale,
                                 pixelScale,
                                 pixelScale)
            }

            // 网格最后绘制，确保橙色准星仍保留清晰的单像素格边界。
            context.strokeStyle = AppConfig.magnifierGridColor
            context.lineWidth = 1
            context.beginPath()
            for (let line = 1; line < sampleCount; ++line) {
                const offset = 1 + line * pixelScale + 0.5
                context.moveTo(offset, 1)
                context.lineTo(offset, height - 1)
                context.moveTo(1, offset)
                context.lineTo(width - 1, offset)
            }
            context.stroke()

            context.strokeStyle = AppConfig.magnifierBorderColor
            context.strokeRect(0.5, 0.5, width - 1, height - 1)
        }
    }

    Shortcut {
        sequence: "Return"
        enabled: captureOverlay.controller.mode !== "pixel"
                 && captureOverlay.hasSelection
        onActivated: {
            // 截图来自选择层显示前缓存的桌面，不包含遮罩和选区边框。
            captureOverlay.controller.saveRegion(
                Math.round(captureOverlay.savedSelectionX),
                Math.round(captureOverlay.savedSelectionY),
                Math.round(captureOverlay.savedSelectionWidth),
                Math.round(captureOverlay.savedSelectionHeight))
        }
    }

    Shortcut {
        sequence: "Enter"
        enabled: captureOverlay.controller.mode !== "pixel"
                 && captureOverlay.hasSelection
        onActivated: {
            // 数字键盘 Enter 与主键盘 Enter 使用相同确认行为。
            captureOverlay.controller.saveRegion(
                Math.round(captureOverlay.savedSelectionX),
                Math.round(captureOverlay.savedSelectionY),
                Math.round(captureOverlay.savedSelectionWidth),
                Math.round(captureOverlay.savedSelectionHeight))
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            captureOverlay.dragging = false
            captureOverlay.hasSelection = false
            captureOverlay.controller.cancel()
        }
    }
}
