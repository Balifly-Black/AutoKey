import QtQuick
import QtQuick.Controls

Rectangle {
    id: titleBar

    required property var rootWindow
    signal logoutRequested()

    height: 50
    color: rootWindow.titleBarColor

    MouseArea {
        anchors.fill: parent

        onPressed: rootWindow.startSystemMove()
        onDoubleClicked: {
            if (rootWindow.visibility === Window.Maximized)
                rootWindow.showNormal()
            else
                rootWindow.showMaximized()
        }
    }

    Row {
        id: titleLeftContent

        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - titleRightControls.width - 48
        height: parent.height
        spacing: 8

        Image {
            id: titleLogo

            width: 25
            height: 25
            anchors.verticalCenter: parent.verticalCenter
            source: rootWindow.darkMode
                    ? Qt.resolvedUrl("../icons/logo/white/riFill-keyboard-box-fill 1.svg")
                    : Qt.resolvedUrl("../icons/logo/black/riFill-keyboard-box-fill 1.svg")
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        Label {
            width: titleLeftContent.width - titleLogo.width - titleLeftContent.spacing
            anchors.verticalCenter: parent.verticalCenter
            text: rootWindow.title
            color: rootWindow.textColor
            elide: Text.ElideRight
            // 标题区域统一使用字体管理器注册的标题字体。
            font.family: Fonts.titleFamily
            font.pixelSize: 20
        }
    }

    Label {
        anchors.centerIn: parent
        text: rootWindow.currentTimeText
        color: rootWindow.textColor
        font.family: Fonts.titleFamily
        font.pixelSize: 16
    }

    Row {
        id: titleRightControls

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 18
        spacing: 10
        height: 26

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5
            height: parent.height

            Rectangle {
                width: 22
                height: 22
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                // 窗口按钮背景和边框统一从 AppConfig 获取
                color: rootWindow.darkMode ? AppConfig.windowButtonBgDark : AppConfig.windowButtonBgLight
                border.color: rootWindow.darkMode ? AppConfig.windowButtonHighlightDark : AppConfig.windowButtonHighlightLight
                border.width: 1

                Image {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: Qt.resolvedUrl("../icons/nav/" + rootWindow.navIconTheme + "/riLine-account-circle-line.svg")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    cache: false
                }
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("用户名")
                color: rootWindow.textColor
                font.pixelSize: 14
            }

            Rectangle {
                width: 24
                height: 24
                radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: logoutArea.containsMouse
                       ? rootWindow.menuHoverColor
                       : AppConfig.transparentColor

                Image {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    source: Qt.resolvedUrl("../icons/common/" + rootWindow.navIconTheme + "/riLine-logout-box-line.svg")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    cache: false
                }

                MouseArea {
                    id: logoutArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: titleBar.logoutRequested()
                }
            }

            Rectangle {
                width: 24
                height: 24
                radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: githubArea.containsMouse
                       ? rootWindow.menuHoverColor
                       : AppConfig.transparentColor

                Image {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    source: Qt.resolvedUrl("../icons/common/" + rootWindow.navIconTheme + "/antOutline-github.svg")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    cache: false
                }

                MouseArea {
                    id: githubArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                    }
                }
            }

            Rectangle {
                width: 24
                height: 24
                radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: menuArea.containsMouse
                       ? rootWindow.menuHoverColor
                       : AppConfig.transparentColor

                Image {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    source: Qt.resolvedUrl("../icons/common/" + rootWindow.navIconTheme + "/riLine-menu-line.svg")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    cache: false
                }

                MouseArea {
                    id: menuArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                    }
                }
            }

            // 置顶按钮
            Rectangle {
                width: 24
                height: 24
                radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: pinArea.containsMouse || rootWindow.pinned
                       ? rootWindow.menuHoverColor
                       : rootWindow.titleBarColor

                Behavior on color {
                    enabled: pinArea.containsMouse || rootWindow.pinned
                    ColorAnimation { duration: AppConfig.animDurationFast }
                }

                Image {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    source: Qt.resolvedUrl("../icons/common/" + rootWindow.navIconTheme
                                           + "/riLine-pushpin-2-line.svg")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                MouseArea {
                    id: pinArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rootWindow.togglePinned()
                }
            }
        }

        Rectangle {
            width: 1
            height: 18
            anchors.verticalCenter: parent.verticalCenter
            color: rootWindow.borderColor
            opacity: 0.45
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            height: parent.height

            Rectangle {
                width: 14
                height: 14
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                // 最小化按钮：黄色警告色系
                color: minimizeArea.containsMouse ? AppConfig.warningHoverColor : AppConfig.warningColor
                border.color: AppConfig.minimizeBtnBorder
                border.width: 1

                MouseArea {
                    id: minimizeArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.ArrowCursor

                    onClicked: rootWindow.showMinimized()
                }
            }

            Rectangle {
                width: 14
                height: 14
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                // 最大化按钮：绿色成功色系
                color: maximizeArea.containsMouse ? AppConfig.successHoverColor : AppConfig.successColor
                border.color: AppConfig.maximizeBtnBorder
                border.width: 1

                MouseArea {
                    id: maximizeArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.ArrowCursor

                    onClicked: {
                        if (rootWindow.visibility === Window.Maximized)
                            rootWindow.showNormal()
                        else
                            rootWindow.showMaximized()
                    }
                }
            }

            Rectangle {
                width: 14
                height: 14
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                // 关闭按钮：红色危险色系
                color: closeArea.containsMouse ? AppConfig.dangerHoverColor : AppConfig.dangerColor
                border.color: AppConfig.closeBtnBorder
                border.width: 1

                MouseArea {
                    id: closeArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.ArrowCursor

                    onClicked: rootWindow.close()
                }
            }
        }
    }
}
