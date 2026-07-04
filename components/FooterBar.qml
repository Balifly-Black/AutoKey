import QtQuick
import QtQuick.Controls

Rectangle {
    required property var rootWindow

    height: AppConfig.footerBarHeight
    color: rootWindow.panelColor

    Label {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        // 使用 .arg() 模板方式拼接文本，便于国际化
        text: qsTr("Author %1  Released %2  Version %3")
              .arg(rootWindow.authorName)
              .arg(rootWindow.releaseDate)
              .arg(rootWindow.appVersion)
        color: rootWindow.mutedTextColor
        font.pixelSize: 10
    }
}
