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
            text: qsTr("云端")
            color: rootWindow.textColor
            font.pixelSize: 34
            font.bold: true
        }

        Label {
            text: qsTr("云端下载相关功能暂未开放，敬请期待！。")
            color: rootWindow.mutedTextColor
            font.pixelSize: 13
        }
    }
}
