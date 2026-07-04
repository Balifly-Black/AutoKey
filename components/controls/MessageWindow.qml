import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Popup {
    id: messageWindow

    // rootWindow 提供深浅主题和窗口颜色。
    required property var rootWindow
    property string titleText: qsTr("提示")
    property string messageText: ""

    // 统一设置消息内容并打开弹窗，供不同业务场景复用。
    function showMessage(title, message) {
        titleText = title
        messageText = message
        open()
    }

    // Popup 挂载到全局 Overlay，并始终在主窗口中心显示。
    parent: Overlay.overlay
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: 360
    // 正文优先撑高弹窗，但总高度不超过窗口可用高度的 90%。
    height: Math.min(parent.height * 0.9,
                     Math.max(160, 129 + messageLabel.implicitHeight))
    modal: true
    focus: true
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    // 单层半透明遮罩随 Popup 的打开和关闭由 Overlay 自动管理。
    Overlay.modal: Rectangle {
        color: AppConfig.messageOverlayColor
    }

    background: Item {
        // 阴影位于面板后方，使用自动扩展区域避免柔化边缘被裁切。
        MultiEffect {
            anchors.fill: panel
            z: -1
            source: panel
            shadowEnabled: true
            shadowColor: AppConfig.shadowColor
            shadowOpacity: messageWindow.rootWindow.darkMode ? 0.55 : 0.28
            shadowBlur: 0.9
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 4
            autoPaddingEnabled: true
        }

        Rectangle {
            id: panel

            anchors.fill: parent
            radius: 8
            color: messageWindow.rootWindow.panelColor
        }
    }

    contentItem: Item {
        // 消息标题使用主文字色，保持信息层级清晰。
        Label {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 20
            text: messageWindow.titleText
            color: messageWindow.rootWindow.textColor
            font.pixelSize: 24
            font.bold: true
        }

        // 正文超过最大弹窗高度时在此区域滚动，标题和按钮保持可见。
        Flickable {
            id: messageFlick

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 65
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.bottom: confirmButton.top
            anchors.bottomMargin: 16
            contentWidth: width
            contentHeight: Math.max(height, messageLabel.implicitHeight)
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            ScrollBar.vertical: AppScrollBar {
                rootWindow: messageWindow.rootWindow
            }

            Label {
                id: messageLabel

                width: messageFlick.width - 10
                text: messageWindow.messageText
                color: messageWindow.rootWindow.mutedTextColor
                font.pixelSize: 14
                wrapMode: Text.WordWrap
            }
        }

        // 确认按钮沿用应用主色，并提供悬浮反馈。
        Rectangle {
            id: confirmButton

            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 20
            anchors.bottomMargin: 16
            width: 90
            height: 32
            radius: 4
            color: confirmArea.containsMouse
                   ? AppConfig.accentHoverColor
                   : AppConfig.accentColor

            Label {
                anchors.centerIn: parent
                text: qsTr("确定")
                color: AppConfig.whiteTextColor
                font.pixelSize: 14
                font.bold: true
            }

            MouseArea {
                id: confirmArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: messageWindow.close()
            }
        }
    }
}
