import QtQuick
import QtQuick.Controls

Item {
    id: authPage

    required property var rootWindow

    signal loginAccepted()

    // registerMode 驱动左右两套表单的可用状态，以及上层引导面板的滑动方向。
    property bool registerMode: false
    property string loginTipText: ""
    property string registerTipText: ""
    readonly property bool darkMode: rootWindow.darkMode
    readonly property string iconTheme: rootWindow.navIconTheme
    readonly property color formColor: rootWindow.panelColor
    readonly property color coverColor: rootWindow.menuHoverColor
    readonly property color textColor: rootWindow.textColor
    readonly property color mutedTextColor: rootWindow.mutedTextColor
    readonly property color fieldBorderColor: darkMode ? AppConfig.darkMutedTextColor : AppConfig.lightMutedTextColor
    readonly property color selectedTextColor: darkMode ? AppConfig.darkPanelColor : AppConfig.lightPanelColor
    readonly property int panelRadius: 14
    readonly property int switchAnimDuration: 520
    readonly property int switchFadeDuration: switchAnimDuration / 2
    readonly property int switchAnimEasing: Easing.InOutCubic

    function acceptLogin() {
        loginAccepted()
    }

    Rectangle {
        id: authSurface

        // 登录页覆盖整个主窗口，使用 clip 保证滑动面板和圆角边界一致。
        anchors.fill: parent
        color: formColor
        radius: authPage.panelRadius
        clip: true

        MouseArea {
            anchors.fill: parent
            z: 0
            acceptedButtons: Qt.LeftButton
            onClicked: authSurface.forceActiveFocus()
        }

        // 无边框窗口需要在登录页本身提供拖动和双击最大化能力。
        MouseArea {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 60
            acceptedButtons: Qt.LeftButton
            onPressed: rootWindow.startSystemMove()
            onDoubleClicked: {
                if (rootWindow.visibility === Window.Maximized)
                    rootWindow.showNormal()
                else
                    rootWindow.showMaximized()
            }
        }

        Item {
            id: registerForm

            // 注册表单固定在左侧，实际交互由 registerMode 控制。
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width / 2
            z: 1

            FormContent {
                id: registerContent

                anchors.centerIn: parent
                width: Math.min(280, parent.width - 80)
                mode: "register"
                title: qsTr("注册账号")
                primaryText: qsTr("SIGN UP")
                showConfirmPassword: true
                showEmail: true
                showCaptcha: true
                tipText: authPage.registerTipText
                state: authPage.registerMode ? "visible" : "hidden"
                enabled: authPage.registerMode
                onPrimaryClicked: authPage.acceptLogin()
                transform: Translate {
                    id: registerShift
                }

                states: [
                    State {
                        name: "visible"
                        PropertyChanges { target: registerContent; opacity: 1 }
                        PropertyChanges { target: registerShift; x: 0 }
                    },
                    State {
                        name: "hidden"
                        PropertyChanges { target: registerContent; opacity: 0 }
                        PropertyChanges { target: registerShift; x: registerForm.width }
                    }
                ]

                transitions: [
                    Transition {
                        from: "hidden"
                        to: "visible"

                        ParallelAnimation {
                            NumberAnimation {
                                target: registerShift
                                property: "x"
                                duration: authPage.switchAnimDuration
                                easing.type: authPage.switchAnimEasing
                            }

                            SequentialAnimation {
                                PauseAnimation { duration: authPage.switchFadeDuration }
                                NumberAnimation {
                                    target: registerContent
                                    property: "opacity"
                                    duration: authPage.switchFadeDuration
                                    easing.type: authPage.switchAnimEasing
                                }
                            }
                        }
                    },
                    Transition {
                        from: "visible"
                        to: "hidden"

                        ParallelAnimation {
                            NumberAnimation {
                                target: registerShift
                                property: "x"
                                duration: authPage.switchAnimDuration
                                easing.type: authPage.switchAnimEasing
                            }

                            NumberAnimation {
                                target: registerContent
                                property: "opacity"
                                duration: authPage.switchFadeDuration
                                easing.type: authPage.switchAnimEasing
                            }
                        }
                    }
                ]
            }
        }

        Item {
            id: loginForm

            // 登录表单固定在右侧，启动时默认可见可操作。
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width / 2
            z: 1

            FormContent {
                id: loginContent

                anchors.centerIn: parent
                width: Math.min(280, parent.width - 80)
                mode: "login"
                title: qsTr("登录账号")
                primaryText: qsTr("SIGN IN")
                showForgotPassword: true
                tipText: authPage.loginTipText
                state: authPage.registerMode ? "hidden" : "visible"
                enabled: !authPage.registerMode
                onPrimaryClicked: authPage.acceptLogin()
                transform: Translate {
                    id: loginShift
                }

                states: [
                    State {
                        name: "visible"
                        PropertyChanges { target: loginContent; opacity: 1 }
                        PropertyChanges { target: loginShift; x: 0 }
                    },
                    State {
                        name: "hidden"
                        PropertyChanges { target: loginContent; opacity: 0 }
                        PropertyChanges { target: loginShift; x: -loginForm.width }
                    }
                ]

                transitions: [
                    Transition {
                        from: "hidden"
                        to: "visible"

                        ParallelAnimation {
                            NumberAnimation {
                                target: loginShift
                                property: "x"
                                duration: authPage.switchAnimDuration
                                easing.type: authPage.switchAnimEasing
                            }

                            SequentialAnimation {
                                PauseAnimation { duration: authPage.switchFadeDuration }
                                NumberAnimation {
                                    target: loginContent
                                    property: "opacity"
                                    duration: authPage.switchFadeDuration
                                    easing.type: authPage.switchAnimEasing
                                }
                            }
                        }
                    },
                    Transition {
                        from: "visible"
                        to: "hidden"

                        ParallelAnimation {
                            NumberAnimation {
                                target: loginShift
                                property: "x"
                                duration: authPage.switchAnimDuration
                                easing.type: authPage.switchAnimEasing
                            }

                            NumberAnimation {
                                target: loginContent
                                property: "opacity"
                                duration: authPage.switchFadeDuration
                                easing.type: authPage.switchAnimEasing
                            }
                        }
                    }
                ]
            }
        }

        Rectangle {
            id: coverPanel

            // 上层引导面板始终盖住半个窗口；切换登录/注册时通过 x 做左右滑动。
            x: authPage.registerMode ? parent.width / 2 : 0
            y: 0
            width: parent.width / 2
            height: parent.height
            z: 2
            color: authPage.coverColor
            clip: true

            Behavior on x {
                NumberAnimation {
                    duration: authPage.switchAnimDuration
                    easing.type: authPage.switchAnimEasing
                }
            }

            Item {
                id: coverMotionBackground

                anchors.fill: parent
                z: 0
                opacity: authPage.darkMode ? 0.48 : 0.30

                Rectangle {
                    anchors.fill: parent
                    opacity: authPage.darkMode ? 0.26 : 0.12
                    gradient: Gradient {
                        GradientStop { position: 0; color: AppConfig.transparentColor }
                        GradientStop { position: 0.5; color: AppConfig.successColor }
                        GradientStop { position: 1; color: AppConfig.transparentColor }
                    }
                }

                Repeater {
                    model: Math.ceil(coverPanel.width / 12) + 4

                    Item {
                        id: rainColumn

                        required property int index

                        readonly property int columnIndex: index
                        readonly property int streamLength: 12 + ((index * 13 + index * index * 7) % 39)

                        x: index * 12 - 8
                        y: -codeStream.height - index * 31
                        width: 12
                        height: codeStream.height

                        SequentialAnimation on y {
                            loops: Animation.Infinite
                            PauseAnimation { duration: index * 160 }
                            NumberAnimation {
                                from: -codeStream.height - 80
                                to: coverPanel.height + 40
                                duration: 3600 + (index % 6) * 520
                                easing.type: Easing.Linear
                            }
                        }

                        Column {
                            id: codeStream

                            spacing: 1

                            Repeater {
                                model: rainColumn.streamLength

                                Text {
                                    required property int index

                                    readonly property bool streamHead: index === 0

                                    width: 12
                                    horizontalAlignment: Text.AlignHCenter
                                    text: ((index * 7 + rainColumn.columnIndex * 11) % 5 < 2) ? "1" : "0"
                                    color: streamHead ? AppConfig.warningColor : AppConfig.successColor
                                    opacity: streamHead ? 0.95
                                                        : Math.max(0.08, 0.72 - index / Math.max(1, rainColumn.streamLength) * 0.78)
                                    font.family: "Consolas"
                                    font.bold: streamHead
                                    font.pixelSize: streamHead ? 16 : 14
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 90
                    gradient: Gradient {
                        GradientStop { position: 0; color: authPage.coverColor }
                        GradientStop { position: 1; color: AppConfig.transparentColor }
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 120
                    gradient: Gradient {
                        GradientStop { position: 0; color: AppConfig.transparentColor }
                        GradientStop { position: 1; color: authPage.coverColor }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                width: Math.min(300, parent.width - 70)
                spacing: 18
                z: 1

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: authPage.registerMode ? qsTr("Welcome Back!") : qsTr("Hello Friend!")
                    color: authPage.textColor
                    font.bold: true
                    font.pixelSize: 30
                    wrapMode: Text.WordWrap
                }

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: authPage.registerMode
                          ? qsTr("已有账号，点击按钮，体验年轻人的第一款轮椅！")
                          : qsTr("点击下方按钮注册账号，体验年轻人的第一款轮椅！")
                    color: authPage.mutedTextColor
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                }

                AuthButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: 22
                    text: authPage.registerMode ? qsTr("SIGN IN") : qsTr("SIGN UP")
                    onClicked: authPage.registerMode = !authPage.registerMode
                }
            }
        }

        Row {
            id: windowButtons

            // 登录页没有主标题栏，因此单独放置 macOS 风格窗口控制按钮。
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 24
            anchors.rightMargin: 24
            spacing: 10
            z: 3

            WindowDot {
                baseColor: AppConfig.warningColor
                hoverColor: AppConfig.warningHoverColor
                borderColor: AppConfig.minimizeBtnBorder
                onClicked: rootWindow.showMinimized()
            }

            WindowDot {
                baseColor: AppConfig.successColor
                hoverColor: AppConfig.successHoverColor
                borderColor: AppConfig.maximizeBtnBorder
                onClicked: {
                    if (rootWindow.visibility === Window.Maximized)
                        rootWindow.showNormal()
                    else
                        rootWindow.showMaximized()
                }
            }

            WindowDot {
                baseColor: AppConfig.dangerColor
                hoverColor: AppConfig.dangerHoverColor
                borderColor: AppConfig.closeBtnBorder
                onClicked: rootWindow.close()
            }
        }
    }

    component FormContent: Column {
        id: formContent

        // 复用的账号表单骨架；通过 show* 开关组合出登录和注册两种形态。
        property string mode: "login"
        property string title: ""
        property string primaryText: ""
        property bool showConfirmPassword: false
        property bool showEmail: false
        property bool showCaptcha: false
        property bool showForgotPassword: false
        property string tipText: ""

        signal primaryClicked()

        function clearTip() {
            tipText = ""
        }

        function findEmptyRequiredField(items) {
            for (let index = 0; index < items.length; ++index) {
                const item = items[index]
                if (!item.visible)
                    continue
                if (item.requiredForSubmit === true
                        && String(item.text).trim().length === 0) {
                    return item
                }
                const emptyChild = findEmptyRequiredField(item.children || [])
                if (emptyChild)
                    return emptyChild
            }
            return null
        }

        function validateRequiredFields() {
            const emptyField = findEmptyRequiredField(inputGroup.children)
            if (emptyField) {
                tipText = qsTr("请填写%1").arg(emptyField.placeholderText)
                return false
            }
            clearTip()
            return true
        }

        spacing: mode === "register" ? 12 : 18

        Label {
            width: parent.width
            text: formContent.title
            color: authPage.textColor
            font.bold: true
            font.pixelSize: 40
            horizontalAlignment: Text.AlignHCenter
        }

        Item {
            width: 1
            height: 4
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            height: 28

            Image {
                width: 32
                height: 32
                anchors.verticalCenter: parent.verticalCenter
                source: Qt.resolvedUrl("../icons/logo/" + authPage.iconTheme + "/riFill-keyboard-box-fill 1 32.svg")
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("AutoKey")
                color: authPage.textColor
                font.family: Fonts.titleFamily
                font.bold: true
                font.italic: true
                font.pixelSize: 28
            }
        }

        Label {
            width: parent.width
            text: qsTr("Autokey ottowin —— 年轻人的第一款轮椅！")
            color: authPage.mutedTextColor
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }

        Item {
            width: 1
            height: mode === "register" ? 6 : 12
        }

        Column {
            id: inputGroup
            width: parent.width
            spacing: formContent.spacing

        AuthField {
            width: parent.width
            placeholderText: qsTr("账号")
        }

        AuthField {
            width: parent.width
            placeholderText: qsTr("密码")
            echoMode: TextInput.Password
        }

        AuthField {
            width: parent.width
            visible: formContent.showConfirmPassword
            height: visible ? implicitHeight : 0
            placeholderText: qsTr("再次输入密码")
            echoMode: TextInput.Password
        }

        AuthField {
            width: parent.width
            visible: formContent.showEmail
            height: visible ? implicitHeight : 0
            placeholderText: qsTr("邮箱")
        }

        Row {
            width: parent.width
            height: formContent.showCaptcha ? 36 : 0
            visible: formContent.showCaptcha
            spacing: 10

            AuthField {
                width: parent.width - sendCodeButton.width - parent.spacing
                placeholderText: qsTr("验证码")
            }

            AuthButton {
                id: sendCodeButton
                width: 118
                height: 36
                fontSize: 12
                radius: 8
                text: qsTr("发送验证码")
                topPadding: 0
            }
        }

        Label {
            width: parent.width
            visible: formContent.showForgotPassword
            height: visible ? 28 : 0
            text: qsTr("忘记密码")
            color: authPage.mutedTextColor
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: forgotArea.containsMouse ? 1 : 0.72
            textFormat: Text.PlainText
            font.underline: true

            MouseArea {
                id: forgotArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
            }
        }

        Item {
            width: parent.width
            height: 36

            Label {
                anchors.fill: parent
                text: formContent.tipText
                color: AppConfig.accentColor
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                opacity: text.length > 0 ? 1 : 0
            }
        }

        }

        AuthButton {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: mode === "register" ? 18 : 10
            text: formContent.primaryText
            onClicked: {
                if (formContent.validateRequiredFields())
                    formContent.primaryClicked()
            }
        }
    }

    component AuthField: TextField {
        id: field

        // 聚焦或已有输入时，提示文字浮到边框左上方并缩小字号。
        readonly property bool labelFloated: activeFocus || text.length > 0

        property bool requiredForSubmit: true

        implicitHeight: 36
        leftPadding: 14
        rightPadding: 14
        color: authPage.textColor
        placeholderTextColor: AppConfig.transparentColor
        selectedTextColor: authPage.selectedTextColor
        selectionColor: AppConfig.accentColor
        font.bold: true
        font.pixelSize: 13
        verticalAlignment: TextInput.AlignVCenter
        background: Rectangle {
            // 背景保持透明，只绘制边框；浮动标签负责遮住一小段边框。
            radius: 8
            color: AppConfig.transparentColor
            border.width: 2
            border.color: field.activeFocus ? AppConfig.accentColor : authPage.fieldBorderColor
        }

        Rectangle {
            // 标签背景色与表单面板一致，制造边框被“切开”的视觉效果。
            x: field.labelFloated ? 10 : field.leftPadding
            y: field.labelFloated ? -8 : (field.height - height) / 2
            width: floatingLabel.implicitWidth + 10
            height: floatingLabel.implicitHeight
            color: field.labelFloated ? authPage.formColor : AppConfig.transparentColor
            z: 2

            Behavior on x {
                NumberAnimation {
                    duration: AppConfig.animDurationFast
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on y {
                NumberAnimation {
                    duration: AppConfig.animDurationFast
                    easing.type: Easing.OutCubic
                }
            }

            Label {
                id: floatingLabel

                anchors.centerIn: parent
                text: field.placeholderText
                color: authPage.textColor
                font.bold: true
                font.pixelSize: field.labelFloated ? 12 : 13

                Behavior on font.pixelSize {
                    NumberAnimation {
                        duration: AppConfig.animDurationFast
                        easing.type: Easing.OutCubic
                    }
                }

            }
        }
    }

    component AuthButton: Item {
        id: authButton

        // topPadding 让同一按钮组件既能作为常规按钮，也能在表单底部留出上间距。
        property alias text: buttonText.text
        property int fontSize: 13
        property int topPadding: 0
        property real radius: -1

        signal clicked()

        width: 150
        height: topPadding + 44

        Rectangle {
            id: buttonBackground

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height - authButton.topPadding
            radius: authButton.radius >= 0 ? authButton.radius : height / 2
            color: buttonArea.containsMouse ? AppConfig.accentHoverColor : AppConfig.accentColor
            border.color: AppConfig.accentColor
            border.width: 1

            Behavior on color {
                ColorAnimation {
                    duration: AppConfig.animDurationFast
                }
            }

            Label {
                id: buttonText

                anchors.centerIn: parent
                color: AppConfig.whiteTextColor
                font.bold: true
                font.pixelSize: authButton.fontSize
                font.letterSpacing: 2
            }

            MouseArea {
                id: buttonArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: authButton.clicked()
            }
        }
    }

    component WindowDot: Rectangle {
        id: dot

        // 简化窗口控制圆点：颜色由调用方传入，点击行为通过 signal 暴露。
        property color baseColor
        property color hoverColor
        property color borderColor

        signal clicked()

        width: AppConfig.windowButtonSize
        height: AppConfig.windowButtonSize
        radius: width / 2
        color: dotArea.containsMouse ? hoverColor : baseColor
        border.color: borderColor
        border.width: 1

        MouseArea {
            id: dotArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.ArrowCursor
            onClicked: dot.clicked()
        }
    }
}
