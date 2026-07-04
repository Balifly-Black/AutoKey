import QtQuick
import QtQuick.Controls

Rectangle {
    id: sideMenu

    required property var rootWindow
    property int currentPage: 0

    signal pageRequested(int index)

    width: 80
    color: rootWindow.panelColor

    ListModel {
        id: menuModel

        ListElement { title: "操作台"; normalIcon: "riLine-sound-module-line.svg"; activeIcon: "riFill-sound-module-fill.svg" }
        ListElement { title: "编辑器"; normalIcon: "riLine-file-edit-line.svg"; activeIcon: "riFill-file-edit-fill.svg" }
        ListElement { title: "设置"; normalIcon: "riLine-settings-6-line.svg"; activeIcon: "riFill-settings-6-fill.svg" }
        ListElement { title: "云端"; normalIcon: "riLine-cloudy-2-line.svg"; activeIcon: "riFill-cloudy-2-fill.svg" }
        ListElement { title: "我的"; normalIcon: "riLine-account-circle-line.svg"; activeIcon: "riFill-account-circle-fill.svg" }
        ListElement { title: "关于"; normalIcon: "riLine-information-line.svg"; activeIcon: "riFill-information-fill.svg" }
    }

    Column {
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        width: 48
        height: (menuModel.count + 2) * 48 + (menuModel.count - 1) * spacing
        spacing: 8

        Repeater {
            model: menuModel

            delegate: Item {
                id: menuButton

                property bool hovered: false
                width: 44
                height: 44

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: menuButton.hovered
                           ? rootWindow.menuHoverColor
                           : sideMenu.color

                    Behavior on color {
                        enabled: menuButton.hovered
                        ColorAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Image {
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    source: Qt.resolvedUrl(currentPage === index
                                           ? "../icons/nav/orange/" + activeIcon
                                           : "../icons/nav/" + rootWindow.navIconTheme + "/" + normalIcon)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    cache: false
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: menuButton.hovered = true
                    onExited: menuButton.hovered = false
                    onClicked: sideMenu.pageRequested(index)
                }
            }
        }
    }
}
