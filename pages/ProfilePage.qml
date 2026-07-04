import QtQuick
import QtQuick.Controls

Item {
    required property var rootWindow

    Column {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.rightMargin: 20
        anchors.bottomMargin: 10
        spacing: 14

        Label {
            text: qsTr("我的")
            color: rootWindow.textColor
            font.pixelSize: 34
            font.bold: true
        }

        Label {
            text: qsTr("这里放账户和个人信息。")
            color: rootWindow.mutedTextColor
            font.pixelSize: 13
        }
    }
}
