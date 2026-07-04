import QtQuick
import QtQuick.Controls
import "../components/controls"

Item {
    id: basicPage

    required property var rootWindow
    required property color chipColor
    required property color chipTextColor
    required property var keyTags
    required property int keyTagsRevision

    property bool isDeleting: false

    signal keyClicked(string keyName)
    signal keyRemoved(int index)

    Timer {
        id: resetHoverTimer
        interval: 100
        onTriggered: {
            basicPage.isDeleting = false
        }
    }

    Flow {
        id: selectedTags

        anchors.left: parent.left
        anchors.top: parent.top
        width: parent.width
        spacing: 7

        Repeater {
            model: (basicPage.keyTagsRevision, basicPage.keyTags)

            delegate: Rectangle {
                height: 24
                width: tagText.implicitWidth + 14
                radius: 4
                // Tag 悬浮统一使用主题橙色，删除操作不再使用危险红色提示。
                color: (tagMouseArea.containsMouse && !basicPage.isDeleting)
                       ? AppConfig.accentColor
                       : basicPage.chipColor

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }

                Label {
                    id: tagText

                    anchors.centerIn: parent
                    text: modelData
                    color: basicPage.chipTextColor
                    font.pixelSize: 16
                    font.bold: true
                }

                MouseArea {
                    id: tagMouseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        basicPage.isDeleting = true
                        resetHoverTimer.stop()
                        resetHoverTimer.start()
                        basicPage.keyRemoved(index)
                    }
                }
            }
        }
    }

    KeyboardPreview {
        id: keyboardPreview

        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        width: 570
        height: 200
        rootWindow: basicPage.rootWindow
        onKeyClicked: keyName => basicPage.keyClicked(keyName)
    }

    MousePreview {
        anchors.leftMargin: 40
        anchors.left: keyboardPreview.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        width: 150
        height: 200
        rootWindow: basicPage.rootWindow
        onKeyClicked: keyName => basicPage.keyClicked(keyName)
    }

}
