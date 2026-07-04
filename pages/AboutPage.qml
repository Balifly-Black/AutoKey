pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import "../components/controls"

Item {
    id: aboutPage

    required property var rootWindow

    // 关于页只从 rootWindow 读取状态和版本数据，颜色全部从 AppConfig 派生。
    readonly property bool darkMode: rootWindow.darkMode
    readonly property string iconTheme: darkMode ? "white" : "black"
    readonly property color sectionColor: darkMode
                                         ? AppConfig.darkMenuHoverColor
                                         : AppConfig.lightMenuHoverColor
    readonly property color sectionBorderColor: darkMode
                                               ? AppConfig.cardBorderColorDark
                                               : AppConfig.cardBorderColorLight
    readonly property color textColor: darkMode
                                     ? AppConfig.darkTextColor
                                     : AppConfig.lightTextColor
    readonly property color mutedTextColor: darkMode
                                          ? AppConfig.darkMutedTextColor
                                          : AppConfig.lightMutedTextColor
    readonly property color menuHoverColor: darkMode
                                          ? AppConfig.darkMenuHoverColor
                                          : AppConfig.lightMenuHoverColor

    // 小号信息块用于版本、作者、发布日期等元信息，避免每项重复写布局。
    component InfoTile: Rectangle {
        id: tile

        required property string title
        required property string value

        width: 180
        height: 62
        radius: 7
        color: AppConfig.transparentColor
        border.color: aboutPage.sectionBorderColor
        border.width: 1

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 6

            Label {
                width: parent.width
                text: tile.title
                color: aboutPage.mutedTextColor
                font.pixelSize: 12
                elide: Text.ElideRight
            }

            Label {
                width: parent.width
                text: tile.value
                color: aboutPage.textColor
                font.pixelSize: 16
                font.bold: true
                elide: Text.ElideRight
            }
        }
    }

    // 技术项不放图标，避免低分辨率图标破坏关于页的干净排版。
    component TechRow: Rectangle {
        id: techRow

        required property string title
        required property string detail

        width: parent ? parent.width : 0
        height: Math.max(42, techContent.implicitHeight)
        radius: 7
        color: AppConfig.transparentColor

        Column {
            id: techContent

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Label {
                width: parent.width
                text: techRow.title
                color: aboutPage.textColor
                font.pixelSize: 14
                font.bold: true
                elide: Text.ElideRight
            }

            Label {
                width: parent.width
                text: techRow.detail
                color: aboutPage.mutedTextColor
                font.pixelSize: 12
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }
    }

    Flickable {
        id: aboutFlickable

        // About content can overflow after adding metadata or tech rows.
        anchors.fill: parent
        contentWidth: width
        contentHeight: aboutContent.implicitHeight + 10
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: AppScrollBar {
            rootWindow: aboutPage.rootWindow
        }

        Column {
        id: aboutContent

        // 页面级边距和其他页面保持一致，内容宽度由父容器控制。
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.rightMargin: 20
        spacing: 12

        Label {
            text: qsTr("关于")
            color: aboutPage.textColor
            font.pixelSize: 34
            font.bold: true
        }

        Rectangle {
            width: parent.width
            height: 114
            radius: 7
            color: aboutPage.sectionColor
            border.color: aboutPage.sectionBorderColor
            border.width: 0

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Row {
                    width: parent.width
                    height: 34
                    spacing: 10

                    Image {
                        // 使用项目原有 32px SVG logo，避免运行时引用未打包资源。
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32
                        source: Qt.resolvedUrl("../icons/logo/" + aboutPage.iconTheme
                                                + "/riFill-keyboard-box-fill 1 32.svg")
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        cache: false
                    }

                    Label {
                        width: parent.width - 42
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("AutoKey")
                        color: aboutPage.textColor
                        font.pixelSize: 28
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }

                Label {
                    width: parent.width
                    text: qsTr("Autokey ottowin —— 年轻人的第一款轮椅！")
                    color: aboutPage.mutedTextColor
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }

                Row {
                    // 这里展示的是元信息而不是操作按钮，所以只用文字和弱分隔符。
                    spacing: 8

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "v" + aboutPage.rootWindow.appVersion
                        color: AppConfig.accentColor
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("·")
                        color: aboutPage.mutedTextColor
                        font.pixelSize: 13
                    }

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("本地自动化")
                        color: aboutPage.mutedTextColor
                        font.pixelSize: 13
                        font.bold: true
                    }
                }
            }
        }

        Row {
            width: parent.width
            spacing: 14

            InfoTile {
                width: (parent.width - parent.spacing * 2) / 3
                title: qsTr("作者")
                value: aboutPage.rootWindow.authorName
            }

            InfoTile {
                width: (parent.width - parent.spacing * 2) / 3
                title: qsTr("发布日期")
                value: aboutPage.rootWindow.releaseDate
            }

            InfoTile {
                width: (parent.width - parent.spacing * 2) / 3
                title: qsTr("当前版本")
                value: "v" + aboutPage.rootWindow.appVersion
            }
        }

        Rectangle {
            width: parent.width
            height: techColumn.implicitHeight + 28
            radius: 7
            color: aboutPage.sectionColor
            border.color: aboutPage.sectionBorderColor
            border.width: 0

            Column {
                id: techColumn

                // 技术栈条目数量会变化，卡片高度跟随内容，避免新增条目后挤压。
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                anchors.topMargin: 14
                spacing: 8

                Label {
                    text: qsTr("技术栈")
                    color: aboutPage.textColor
                    font.pixelSize: 16
                    font.bold: true
                }

                TechRow {
                    title: qsTr("Qt Quick / QML")
                    detail: qsTr("负责窗口、页面、主题和交互界面")
                }

                TechRow {
                    title: qsTr("Lua 5.4")
                    detail: qsTr("负责脚本逻辑执行")
                }

                TechRow {
                    title: qsTr("DiDouDriver + AK_Rim")
                    detail: qsTr("DiDouDriver：键盘鼠标控制；AK_Rim：区分真实/虚拟键鼠输入监听")
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 48
            radius: 7
            color: githubArea.containsMouse ? aboutPage.menuHoverColor : AppConfig.transparentColor
            border.color: aboutPage.sectionBorderColor
            border.width: 1

            Image {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                height: 20
                source: Qt.resolvedUrl("../icons/common/" + aboutPage.iconTheme + "/antOutline-github.svg")
                fillMode: Image.PreserveAspectFit
                smooth: true
                cache: false
            }

            Label {
                anchors.left: parent.left
                anchors.leftMargin: 48
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "github.com/Balifly/AutoKey"
                color: aboutPage.textColor
                font.pixelSize: 14
                font.bold: true
                elide: Text.ElideRight
            }

            MouseArea {
                id: githubArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                // 链接点击交给 Qt 打开系统默认浏览器；失败时页面不改变状态。
                onClicked: Qt.openUrlExternally("https://github.com/Balifly/AutoKey")
            }
        }
    }
}
}
