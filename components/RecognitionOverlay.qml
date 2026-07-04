import QtQuick
import QtQuick.Controls
import "../"

// 识别结果叠加层 —— 全屏透明窗口，使用 QML Item（场景图双缓冲）消除 Canvas 闪烁。
// 再次点击悬浮窗终端图标时关闭（由 main.qml 控制 toggle）。
Window {
    id: overlay

    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
           | Qt.WindowTransparentForInput | Qt.WindowDoesNotAcceptFocus
    color: AppConfig.transparentColor
    visible: false

    // 将叠加层窗口从 screen->grabWindow 屏幕捕获中排除，
    // 消除"叠加层被识别截取→干扰模板匹配→结果闪烁"的反馈回路
    Component.onCompleted: AutoKeyEngine.excludeWindowFromCapture(overlay)

    // 虚拟桌面矩形（覆盖所有屏幕）
    x: 0
    y: 0
    width: Screen.virtualX + Screen.desktopAvailableWidth
    height: Screen.virtualY + Screen.desktopAvailableHeight

    property var scanResult: null

    readonly property color regionStroke: AppConfig.recognitionRegionStrokeColor
    readonly property color imageStroke: AppConfig.recognitionImageStrokeColor
    readonly property color imageFill: AppConfig.recognitionImageFillColor
    readonly property color pixelColor: AppConfig.recognitionPixelColor
    readonly property color textColor: AppConfig.recognitionTextColor
    readonly property color textBgColor: AppConfig.recognitionTextBgColor
    readonly property int   labelFontSize: 12

    // 解析后的列表，供 Repeater 驱动
    property var imageItems: []
    property var pixelItems: []
    property var regionData: null
    property string configTitle: ""

    onScanResultChanged: {
        if (!scanResult) {
            imageItems = []
            pixelItems = []
            regionData = null
            configTitle = ""
            return
        }
        configTitle = String(scanResult.title || "")
        regionData = scanResult.region || null

        const imgs = scanResult.images || []
        const newImgs = []
        for (let i = 0; i < imgs.length; ++i) {
            if (imgs[i].found)
                newImgs.push(imgs[i])
        }
        imageItems = newImgs

        const pxs = scanResult.pixels || []
        const newPxs = []
        for (let j = 0; j < pxs.length; ++j) {
            if (pxs[j].found)
                newPxs.push(pxs[j])
        }
        pixelItems = newPxs
    }

    // ── 识别区域框 ──
    Rectangle {
        id: regionRect
        x: regionData ? Number(regionData.x) : 0
        y: regionData ? Number(regionData.y) : 0
        width: regionData ? Number(regionData.width) : 0
        height: regionData ? Number(regionData.height) : 0
        visible: regionData && regionData.valid && width > 0 && height > 0
        color: AppConfig.transparentColor
        border.color: overlay.regionStroke
        border.width: 2
    }

    // 区域左上角配置名
    Label {
        visible: regionRect.visible && overlay.configTitle.length > 0
        x: regionRect.x + 8
        y: regionRect.y - labelBg.height
        leftPadding: 6
        rightPadding: 6
        topPadding: 2
        bottomPadding: 2
        text: overlay.configTitle
        color: overlay.textColor
        font.pixelSize: overlay.labelFontSize
        font.bold: true

        Rectangle {
            id: labelBg
            anchors.fill: parent
            z: -1
            color: overlay.textBgColor
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 3
                color: overlay.regionStroke
            }
        }
    }

    // ── 截图匹配框 ──
    Repeater {
        model: overlay.imageItems

        Item {
            required property var modelData
            readonly property real ix: Number(modelData.globalX) || 0
            readonly property real iy: Number(modelData.globalY) || 0
            readonly property real iw: Number(modelData.width) || 0
            readonly property real ih: Number(modelData.height) || 0

            x: ix
            y: iy
            width: iw
            height: ih

            Rectangle {
                anchors.fill: parent
                color: overlay.imageFill
                border.color: overlay.imageStroke
                border.width: 1
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.top
                anchors.bottomMargin: 2
                leftPadding: 6
                rightPadding: 6
                topPadding: 2
                bottomPadding: 2
                text: String(modelData.name || "")
                color: overlay.textColor
                font.pixelSize: overlay.labelFontSize
                font.bold: true

                Rectangle {
                    anchors.fill: parent
                    z: -1
                    color: overlay.textBgColor
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 3
                        color: overlay.imageStroke
                    }
                }
            }
        }
    }

    // ── 取点标记 ──
    Repeater {
        model: overlay.pixelItems

        Item {
            required property var modelData
            readonly property real px: Number(modelData.x) || 0
            readonly property real py: Number(modelData.y) || 0

            x: px - 8
            y: py - 8
            width: 16
            height: 16

            // 十字准星 — 横线
            Rectangle { width: 16; height: 2; anchors.centerIn: parent; color: overlay.pixelColor }
            // 十字准星 — 竖线
            Rectangle { width: 2; height: 16; anchors.centerIn: parent; color: overlay.pixelColor }
            // 外圈
            Rectangle {
                anchors.centerIn: parent
                width: 10; height: 10; radius: 5
                color: AppConfig.transparentColor; border.color: overlay.pixelColor; border.width: 1
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.top
                anchors.bottomMargin: 2
                leftPadding: 6
                rightPadding: 6
                topPadding: 2
                bottomPadding: 2
                text: String(modelData.name || "")
                color: overlay.textColor
                font.pixelSize: overlay.labelFontSize
                font.bold: true

                Rectangle {
                    anchors.fill: parent
                    z: -1
                    color: overlay.textBgColor
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 3
                        color: overlay.pixelColor
                    }
                }
            }
        }
    }
}
