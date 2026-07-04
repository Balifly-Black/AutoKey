pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import "../components/controls"

Item {
    id: settingsPage

    required property var rootWindow

    // 设置页卡片底色复用菜单项 hover 背景，保证页面块面和侧边菜单的层级颜色一致。
    readonly property color sectionColor: rootWindow.darkMode
                                         ? AppConfig.darkMenuHoverColor
                                         : AppConfig.lightMenuHoverColor
    readonly property color sectionBorderColor: rootWindow.darkMode
                                               ? AppConfig.cardBorderColorDark
                                               : AppConfig.cardBorderColorLight
    readonly property color controlLayerColor: rootWindow.darkMode
                                             ? AppConfig.windowButtonHighlightDark
                                             : AppConfig.windowButtonHighlightLight

    // 设置项写入主窗口状态，由主窗口统一保存到 preferences.json。
    function setTheme(theme) {
        rootWindow.themePreference = theme
        rootWindow.saveAppPreferences()
    }

    // 主题选项只负责展示和切换，实际主题颜色仍复用 AppConfig 的全局 Token。
    component ThemeOption: Item {
        id: option

        required property string value
        required property string title
        required property bool darkPreview
        required property bool splitPreview
        property bool checked: settingsPage.rootWindow.themePreference === value

        width: 190
        height: 132

        Rectangle {
            id: preview

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: 150
            height: 104
            radius: 4
            color: option.splitPreview
                   ? AppConfig.transparentColor
                   : (option.darkPreview ? AppConfig.darkPanelColor : AppConfig.lightPanelColor)
            border.color: option.darkPreview ? AppConfig.cardBorderColorDark : AppConfig.cardBorderColorLight
            border.width: option.splitPreview ? 0 : 1
            clip: true

            Item {
                visible: option.splitPreview
                anchors.fill: parent

                Rectangle {
                    // 左半背景保留左侧圆角，再用右侧补片把中线修成直边。
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width / 2
                    radius: preview.radius
                    color: AppConfig.lightPanelColor

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: preview.radius
                        color: parent.color
                    }
                }

                Rectangle {
                    // 右半背景保留右侧圆角，再用左侧补片把中线修成直边。
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width / 2
                    radius: preview.radius
                    color: AppConfig.darkPanelColor

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: preview.radius
                        color: parent.color
                    }
                }

                Item {
                    // 跟随系统左半区裁切完整亮色预览，保证样式和亮色模式示例一致。
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width / 2
                    clip: true

                    Item {
                        width: preview.width
                        height: preview.height

                        Rectangle {
                            x: 14
                            y: 10
                            width: 28
                            height: 28
                            radius: width / 2
                            color: AppConfig.windowButtonBgLight
                        }

                        Rectangle {
                            x: 14
                            y: 42
                            width: 114
                            height: 18
                            radius: 3
                            color: AppConfig.lightMenuHoverColor
                        }

                        Rectangle {
                            x: 14
                            y: 66
                            width: 72
                            height: 8
                            radius: 3
                            color: AppConfig.lightMenuHoverColor
                        }

                        Rectangle {
                            x: 14
                            y: 80
                            width: 100
                            height: 8
                            radius: 3
                            color: AppConfig.lightMenuHoverColor
                        }
                    }
                }

                Item {
                    // 跟随系统右半区裁切完整暗色预览，右侧圆角由 preview.clip 保留。
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width / 2
                    clip: true

                    Item {
                        x: -preview.width / 2
                        width: preview.width
                        height: preview.height

                        Rectangle {
                            x: 14
                            y: 10
                            width: 28
                            height: 28
                            radius: width / 2
                            color: AppConfig.windowButtonBgDark
                        }

                        Rectangle {
                            x: 14
                            y: 42
                            width: 114
                            height: 18
                            radius: 3
                            color: AppConfig.darkMenuHoverColor
                        }

                        Rectangle {
                            x: 14
                            y: 66
                            width: 72
                            height: 8
                            radius: 3
                            color: AppConfig.darkMenuHoverColor
                        }

                        Rectangle {
                            x: 14
                            y: 80
                            width: 100
                            height: 8
                            radius: 3
                            color: AppConfig.darkMenuHoverColor
                        }
                    }
                }
            }

            Item {
                visible: !option.splitPreview
                anchors.fill: parent

                Rectangle {
                    x: 14
                    y: 10
                    width: 28
                    height: 28
                    radius: width / 2
                    color: option.darkPreview ? AppConfig.windowButtonBgDark : AppConfig.windowButtonBgLight
                }

                Rectangle {
                    x: 14
                    y: 42
                    width: 114
                    height: 18
                    radius: 3
                    color: option.darkPreview ? AppConfig.darkMenuHoverColor : AppConfig.lightMenuHoverColor
                }

                Rectangle {
                    x: 14
                    y: 66
                    width: 72
                    height: 8
                    radius: 3
                    color: option.darkPreview ? AppConfig.darkMenuHoverColor : AppConfig.lightMenuHoverColor
                }

                Rectangle {
                    x: 14
                    y: 80
                    width: 100
                    height: 8
                    radius: 3
                    color: option.darkPreview ? AppConfig.darkMenuHoverColor : AppConfig.lightMenuHoverColor
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            height: 22
            spacing: 8

            Rectangle {
                width: 14
                height: 14
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: AppConfig.transparentColor
                border.width: 1
                border.color: AppConfig.accentColor

                Rectangle {
                    anchors.centerIn: parent
                    width: 8
                    height: 8
                    radius: width / 2
                    color: option.checked ? AppConfig.accentColor : AppConfig.transparentColor
                }
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: option.title
                color: settingsPage.rootWindow.textColor
                font.pixelSize: 14
                font.bold: option.checked
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: settingsPage.setTheme(option.value)
        }
    }

    Flickable {
        id: settingsFlickable

        // 设置页内容超出可视高度后显示项目统一滚动条。
        anchors.fill: parent
        contentWidth: width
        contentHeight: settingsContent.implicitHeight + 10
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: AppScrollBar {
            rootWindow: settingsPage.rootWindow
        }

        Column {
        id: settingsContent

        // 页面级边距跟随其他页面：左侧贴父容器，右侧保留统一的 20px 呼吸空间。
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.rightMargin: 20
        spacing: 18

        Label {
            text: qsTr("设置")
            color: settingsPage.rootWindow.textColor
            font.pixelSize: 34
            font.bold: true
        }

        Column {
            width: parent.width
            spacing: 16

            Label {
                text: qsTr("主题")
                color: settingsPage.rootWindow.textColor
                font.pixelSize: 16
                font.bold: true
            }

            Rectangle {
                // 内容宽度跟随父级列宽，避免窗口尺寸变化时卡片仍保持固定宽度。
                width: parent.width
                height: 178
                radius: 7
                color: settingsPage.sectionColor
                border.color: settingsPage.sectionBorderColor
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 28
                    anchors.rightMargin: 28
                    anchors.topMargin: 20
                    anchors.bottomMargin: 16
                    spacing: Math.max(28, (width - 190 * 3) / 2)

                    ThemeOption {
                        value: "light"
                        title: qsTr("亮色模式")
                        darkPreview: false
                        splitPreview: false
                    }

                    ThemeOption {
                        value: "dark"
                        title: qsTr("暗色模式")
                        darkPreview: true
                        splitPreview: false
                    }

                    ThemeOption {
                        value: "system"
                        title: qsTr("跟随系统")
                        darkPreview: false
                        splitPreview: true
                    }
                }
            }
        }

        Column {
            width: parent.width
            spacing: 16

            Label {
                text: qsTr("音量")
                color: settingsPage.rootWindow.textColor
                font.pixelSize: 16
                font.bold: true
            }

            Rectangle {
                // 内容宽度跟随父级列宽，和主题卡片保持同一响应式宽度。
                width: parent.width
                height: 40
                radius: 7
                color: settingsPage.sectionColor
                border.color: settingsPage.sectionBorderColor
                border.width: 1

                Label {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("提示音")
                    color: settingsPage.rootWindow.textColor
                    font.pixelSize: 16
                    font.bold: true
                }

                Slider {
                    id: volumeSlider

                    anchors.right: volumeValueBox.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(180, parent.width * 0.28)
                    // 交互高度独立于视觉轨道高度，保证鼠标在滑块上下区域也能点击和拖动。
                    height: 24
                    from: 0
                    to: 100
                    stepSize: 1
                    value: settingsPage.rootWindow.notificationVolume

                    // 统一入口：拖动和点击轨道都通过这里更新，确保设置立即生效并保存。
                    function commitVolume(newValue) {
                        const clamped = Math.max(volumeSlider.from,
                                                 Math.min(volumeSlider.to, Math.round(newValue)))
                        volumeSlider.value = clamped
                        settingsPage.rootWindow.notificationVolume = clamped
                        settingsPage.rootWindow.saveAppPreferences()
                    }

                    onMoved: {
                        // 拖动后立即影响悬浮窗提示音音量，并持久化到 preferences.json。
                        commitVolume(value)
                    }

                    background: Rectangle {
                        x: volumeSlider.leftPadding
                        y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                        implicitWidth: 180
                        implicitHeight: 4
                        width: volumeSlider.availableWidth
                        height: 4
                        radius: 2
                        color: settingsPage.controlLayerColor

                        Rectangle {
                            // 左侧进度始终使用主题橙色，和选中态保持一致。
                            width: volumeSlider.visualPosition * parent.width
                            height: parent.height
                            radius: 2
                            color: AppConfig.accentColor
                        }
                    }

                    handle: Rectangle {
                        x: volumeSlider.leftPadding + volumeSlider.visualPosition
                           * (volumeSlider.availableWidth - width)
                        y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                        width: 14
                        height: 14
                        radius: width / 2
                        color: AppConfig.whiteTextColor
                        border.color: settingsPage.controlLayerColor
                        border.width: 1
                    }

                    TapHandler {
                        // 点击滑动条任意位置时直接跳转到对应值；TapHandler 不会挡住 Slider 原生拖动。
                        onTapped: eventPoint => {
                            const ratio = Math.max(0, Math.min(1, eventPoint.position.x / volumeSlider.width))
                            volumeSlider.commitVolume(volumeSlider.from
                                                      + ratio
                                                      * (volumeSlider.to - volumeSlider.from))
                        }
                    }
                }

                Item {
                    id: volumeValueBox

                    anchors.right: parent.right
                    anchors.rightMargin: 32
                    anchors.verticalCenter: parent.verticalCenter
                    // 固定数值区域宽度，避免 9/10/100 位数变化时挤动滑动条位置。
                    width: 30
                    height: parent.height

                    Label {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: settingsPage.rootWindow.notificationVolume
                        color: settingsPage.rootWindow.textColor
                        font.pixelSize: 16
                        font.bold: true
                    }
                }
            }
        }
    }
}
}
