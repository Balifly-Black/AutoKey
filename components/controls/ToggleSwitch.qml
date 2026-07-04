import QtQuick

Item {
    id: toggleSwitch

    // 默认颜色和尺寸统一从 AppConfig 获取
    property bool checked: false
    property bool interactive: true
    property color accentColor: AppConfig.accentColor
    property color offColor: AppConfig.toggleOffColor
    property color knobColor: AppConfig.toggleKnobColor

    signal toggled(bool checked)

    implicitWidth: AppConfig.toggleSwitchWidth
    implicitHeight: AppConfig.toggleSwitchHeight

    Rectangle {
        id: track

        anchors.fill: parent
        radius: height / 2
        color: toggleSwitch.checked ? toggleSwitch.accentColor : toggleSwitch.offColor

        Behavior on color {
            ColorAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        id: knob

        readonly property real margin: Math.max(2, toggleSwitch.height * 0.12)

        width: toggleSwitch.height - margin * 2
        height: width
        radius: width / 2
        x: toggleSwitch.checked ? toggleSwitch.width - width - margin : margin
        anchors.verticalCenter: parent.verticalCenter
        color: toggleSwitch.knobColor

        Behavior on x {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: toggleSwitch.interactive
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            toggleSwitch.checked = !toggleSwitch.checked
            toggleSwitch.toggled(toggleSwitch.checked)
        }
    }
}
