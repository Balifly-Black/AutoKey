import QtQuick
import QtQuick.Controls

Item {
    id: keyboardPreview

    required property var rootWindow

    signal keyClicked(string keyName)

    Item {
        anchors.fill: parent

        Column {
            id:keyboard1
            width: 540
            spacing: 0

            Repeater {
                model: [
                    [{name: "esc"}, {space: 30}, {name: "f1"}, {name: "f2"}, {name: "f3"}, {name: "f4"}, {space: 15}, {name: "f5"}, {name: "f6"}, {name: "f7"}, {name: "f8"}, {space: 15}, {name: "f9"}, {name: "f10"}, {name: "f11"}, {name: "f12"}, {name: "del"}, {name: "end"}, {name: "pgup"}],
                    [{name: "~"}, {name: "1"}, {name: "2"}, {name: "3"}, {name: "4"}, {name: "5"}, {name: "6"}, {name: "7"}, {name: "8"}, {name: "9"}, {name: "0"}, {name: "-"}, {name: "="}, {name: "backspace", width: 60}, {name: "num"}, {name: "/"}, {name: "*"}],
                    [{name: "tab", width: 45}, {name: "q"}, {name: "w"}, {name: "e"}, {name: "r"}, {name: "t"}, {name: "y"}, {name: "u"}, {name: "i"}, {name: "o"}, {name: "p"}, {name: "["}, {name: "]"}, {name: "\\", width: 45}, {name: "7"}, {name: "8"}, {name: "9"}],
                    [{name: "caps lock", width: 60}, {name: "a"}, {name: "s"}, {name: "d"}, {name: "f"}, {name: "g"}, {name: "h"}, {name: "j"}, {name: "k"}, {name: "l"}, {name: ";"}, {name: "'"}, {name: "enter", width: 60}, {name: "4"}, {name: "5"}, {name: "6"}],
                    [{name: "shift", width: 75}, {name: "z"}, {name: "x"}, {name: "c"}, {name: "v"}, {name: "b"}, {name: "n"}, {name: "m"}, {name: ","}, {name: "."}, {name: "/"}, {name: "shift", width: 45}, {name: "↑"}, {name: "1"}, {name: "2"}, {name: "3"}],
                    [{name: "ctrl", width: 45}, {name: "win"}, {name: "alt", width: 45}, {name: "space", width: 180}, {name: "alt"}, {name: "win"}, {name: "ctrl"}, {name: "←"}, {name: "↓"}, {name: "→"}, {name: "0"}, {name: "."}]
                ]

                delegate: Row {
                    spacing: 0

                    Repeater {
                        model: modelData

                        delegate: Rectangle {
                            width: modelData.space !== undefined ? modelData.space : (modelData.width !== undefined ? modelData.width : 30)
                            height: modelData.height !== undefined ? modelData.height : 30
                            radius: 2
                            color: keyArea.pressed
                                   ? AppConfig.accentColor
                                   : AppConfig.transparentColor
                            border.color: (modelData.space !== undefined)
                                          ? AppConfig.transparentColor
                                          : (keyArea.containsMouse
                                             ? AppConfig.accentColor
                                             : keyboardPreview.rootWindow.mutedTextColor)
                            border.width: (modelData.space !== undefined) ? 0 : 1

                            Label {
                                visible: modelData.name !== undefined
                                anchors.centerIn: parent
                                text: modelData.name ?? ""
                                color: keyArea.pressed
                                       ? keyboardPreview.rootWindow.panelColor
                                       : (keyArea.containsMouse ? AppConfig.accentColor : keyboardPreview.rootWindow.textColor)
                                font.pixelSize: 10
                            }

                            MouseArea {
                                id: keyArea

                                visible: modelData.space === undefined
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: keyboardPreview.keyClicked(modelData.name)
                            }
                        }
                    }
                }
            }
        }

        Column {
            width: 30
            anchors.left: keyboard1.right
            spacing: 0

            Repeater {
                model: [
                    [{name: "pgdn"}],
                    [{name: "-"}],
                    [{name: "+", height: 60}],
                    [{name: "enter", height: 60}]
                ]

                delegate: Row {
                    spacing: 0

                    Repeater {
                        model: modelData

                        delegate: Rectangle {
                            width: 30
                            height: modelData.height !== undefined ? modelData.height : 30
                            radius: 2
                            color: keypadKeyArea.pressed
                                   ? AppConfig.accentColor
                                   : AppConfig.transparentColor
                            border.color: keypadKeyArea.containsMouse
                                          ? AppConfig.accentColor
                                          : keyboardPreview.rootWindow.mutedTextColor
                            border.width: 1

                            Label {
                                anchors.centerIn: parent
                                text: modelData.name ?? ""
                                color: keypadKeyArea.pressed
                                       ? keyboardPreview.rootWindow.panelColor
                                       : (keypadKeyArea.containsMouse
                                          ? AppConfig.accentColor
                                          : keyboardPreview.rootWindow.textColor)
                                font.pixelSize: 10
                            }

                            MouseArea {
                                // 数字区使用独立 ID，避免与主键区 delegate 的 MouseArea 冲突。
                                id: keypadKeyArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: keyboardPreview.keyClicked(modelData.name)
                            }
                        }
                    }
                }
            }
        }
    }
}
