import QtQuick

Item {
    id: mousePreview

    required property var rootWindow

    signal keyClicked(string keyName)

    readonly property real previewScale: 180 / 142
    readonly property real bodyWidth: 110 * previewScale
    readonly property real bodyHeight: 180
    readonly property real bodyLeft: (width - bodyWidth + sideWidth) / 2
    readonly property real bodyTop: 0
    readonly property real dividerY: bodyTop + 65 * previewScale
    readonly property real centerX: bodyLeft + bodyWidth / 2
    readonly property real wheelWidth: 16 * previewScale
    readonly property real wheelHeight: 40 * previewScale
    readonly property real wheelTop: bodyTop + 13 * previewScale
    readonly property real sideWidth: 6 * previewScale
    readonly property real sideButtonHeight: 26 * previewScale
    readonly property real sideOffsetY: 4 * previewScale
    readonly property real sideDividerY: dividerY + sideOffsetY
    readonly property real sideTop: sideDividerY - sideButtonHeight
    readonly property real sideBottom: sideDividerY + sideButtonHeight

    MouseArea {
        id: leftMouseArea

        x: mousePreview.bodyLeft
        y: mousePreview.bodyTop
        width: mousePreview.bodyWidth / 2
        height: mousePreview.dividerY - mousePreview.bodyTop
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mousePreview.keyClicked("left")
    }

    MouseArea {
        id: rightMouseArea

        x: mousePreview.centerX
        y: mousePreview.bodyTop
        width: mousePreview.bodyWidth / 2
        height: mousePreview.dividerY - mousePreview.bodyTop
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mousePreview.keyClicked("right")
    }

    MouseArea {
        id: wheelArea

        z: 2
        x: mousePreview.centerX - mousePreview.wheelWidth / 2
        y: mousePreview.wheelTop
        width: mousePreview.wheelWidth
        height: mousePreview.wheelHeight
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mousePreview.keyClicked("middle")
    }

    MouseArea {
        id: xbutton2Area

        z: 2
        x: mousePreview.bodyLeft - mousePreview.sideWidth
        y: mousePreview.sideTop
        width: mousePreview.sideWidth
        height: mousePreview.sideDividerY - mousePreview.sideTop
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mousePreview.keyClicked("xbutton2")
    }

    MouseArea {
        id: xbutton1Area

        z: 2
        x: mousePreview.bodyLeft - mousePreview.sideWidth
        y: mousePreview.sideDividerY
        width: mousePreview.sideWidth
        height: mousePreview.sideBottom - mousePreview.sideDividerY
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mousePreview.keyClicked("xbutton1")
    }

    Canvas {
        id: mouseCanvas

        anchors.fill: parent
        z: 1
        antialiasing: true

        readonly property color outlineColor: mousePreview.rootWindow.mutedTextColor
        readonly property color activeColor: AppConfig.accentColor
        readonly property bool leftActive: leftMouseArea.containsMouse
        readonly property bool rightActive: rightMouseArea.containsMouse
        readonly property bool wheelActive: wheelArea.containsMouse
        readonly property bool xbutton1Active: xbutton1Area.containsMouse
        readonly property bool xbutton2Active: xbutton2Area.containsMouse
        readonly property bool leftPressed: leftMouseArea.pressed
        readonly property bool rightPressed: rightMouseArea.pressed
        readonly property bool wheelPressed: wheelArea.pressed
        readonly property bool xbutton1Pressed: xbutton1Area.pressed
        readonly property bool xbutton2Pressed: xbutton2Area.pressed

        onOutlineColorChanged: requestPaint()
        onActiveColorChanged: requestPaint()
        onLeftActiveChanged: requestPaint()
        onRightActiveChanged: requestPaint()
        onWheelActiveChanged: requestPaint()
        onXbutton1ActiveChanged: requestPaint()
        onXbutton2ActiveChanged: requestPaint()
        onLeftPressedChanged: requestPaint()
        onRightPressedChanged: requestPaint()
        onWheelPressedChanged: requestPaint()
        onXbutton1PressedChanged: requestPaint()
        onXbutton2PressedChanged: requestPaint()

        onPaint: {
            const context = getContext("2d")
            const lineWidth = mousePreview.previewScale
            const inset = lineWidth / 2
            const left = mousePreview.bodyLeft + inset
            const right = mousePreview.bodyLeft + mousePreview.bodyWidth - inset
            const top = mousePreview.bodyTop + inset
            const bottom = mousePreview.bodyTop + mousePreview.bodyHeight - inset
            const divider = mousePreview.dividerY
            const center = mousePreview.centerX
            const radius = 44 * mousePreview.previewScale
            const leftCenter = left + radius
            const rightCenter = right - radius
            const topCenter = top + radius
            const bottomCenter = bottom - radius
            const wheelLeft = center - mousePreview.wheelWidth / 2
            const wheelRight = center + mousePreview.wheelWidth / 2
            const wheelTop = mousePreview.wheelTop
            const wheelBottom = wheelTop + mousePreview.wheelHeight
            const wheelRadius = mousePreview.wheelWidth / 2
            const sideLeft = left - mousePreview.sideWidth
            const sideTop = mousePreview.sideTop
            const sideBottom = mousePreview.sideBottom
            const sideDivider = mousePreview.sideDividerY
            const sideRadius = 3 * mousePreview.previewScale

            function traceOuterBody() {
                context.beginPath()
                context.moveTo(leftCenter, top)
                context.lineTo(rightCenter, top)
                context.arc(rightCenter, topCenter, radius, -Math.PI / 2, 0)
                context.lineTo(right, bottomCenter)
                context.arc(rightCenter, bottomCenter, radius, 0, Math.PI / 2)
                context.lineTo(leftCenter, bottom)
                context.arc(leftCenter, bottomCenter, radius, Math.PI / 2, Math.PI)
                context.lineTo(left, topCenter)
                context.arc(leftCenter, topCenter, radius, Math.PI, Math.PI * 1.5)
                context.closePath()
            }

            function traceLeftButton() {
                context.beginPath()
                context.moveTo(center, top)
                context.lineTo(leftCenter, top)
                context.arc(leftCenter, topCenter, radius,
                            -Math.PI / 2, -Math.PI, true)
                context.lineTo(left, divider)
                context.lineTo(center, divider)
                context.moveTo(center, top)
                context.lineTo(center, wheelTop)
                context.moveTo(center, wheelBottom)
                context.lineTo(center, divider)
            }

            function traceRightButton() {
                context.beginPath()
                context.moveTo(center, top)
                context.lineTo(rightCenter, top)
                context.arc(rightCenter, topCenter, radius, -Math.PI / 2, 0)
                context.lineTo(right, divider)
                context.lineTo(center, divider)
                context.moveTo(center, top)
                context.lineTo(center, wheelTop)
                context.moveTo(center, wheelBottom)
                context.lineTo(center, divider)
            }

            function traceLeftFill() {
                context.beginPath()
                context.moveTo(center, top)
                context.lineTo(leftCenter, top)
                context.arc(leftCenter, topCenter, radius,
                            -Math.PI / 2, -Math.PI, true)
                context.lineTo(left, divider)
                context.lineTo(center, divider)
                context.closePath()
            }

            function traceRightFill() {
                context.beginPath()
                context.moveTo(center, top)
                context.lineTo(rightCenter, top)
                context.arc(rightCenter, topCenter, radius, -Math.PI / 2, 0)
                context.lineTo(right, divider)
                context.lineTo(center, divider)
                context.closePath()
            }

            function traceWheel() {
                context.beginPath()
                context.moveTo(center, wheelTop)
                context.arc(wheelRight - wheelRadius, wheelTop + wheelRadius,
                            wheelRadius, -Math.PI / 2, 0)
                context.lineTo(wheelRight, wheelBottom - wheelRadius)
                context.arc(wheelRight - wheelRadius, wheelBottom - wheelRadius,
                            wheelRadius, 0, Math.PI / 2)
                context.lineTo(wheelLeft + wheelRadius, wheelBottom)
                context.arc(wheelLeft + wheelRadius, wheelBottom - wheelRadius,
                            wheelRadius, Math.PI / 2, Math.PI)
                context.lineTo(wheelLeft, wheelTop + wheelRadius)
                context.arc(wheelLeft + wheelRadius, wheelTop + wheelRadius,
                            wheelRadius, Math.PI, Math.PI * 1.5)
                context.closePath()
            }

            function traceSideButton() {
                context.beginPath()
                context.moveTo(left, sideTop)
                context.lineTo(sideLeft + sideRadius, sideTop)
                context.arc(sideLeft + sideRadius, sideTop + sideRadius,
                            sideRadius, -Math.PI / 2, -Math.PI, true)
                context.lineTo(sideLeft, sideBottom - sideRadius)
                context.arc(sideLeft + sideRadius, sideBottom - sideRadius,
                            sideRadius, Math.PI, Math.PI / 2, true)
                context.lineTo(left, sideBottom)
                context.closePath()
            }

            function traceUpperSideButton() {
                context.beginPath()
                context.moveTo(left, sideTop)
                context.lineTo(sideLeft + sideRadius, sideTop)
                context.arc(sideLeft + sideRadius, sideTop + sideRadius,
                            sideRadius, -Math.PI / 2, -Math.PI, true)
                context.lineTo(sideLeft, sideDivider)
                context.lineTo(left, sideDivider)
                context.closePath()
            }

            function traceLowerSideButton() {
                context.beginPath()
                context.moveTo(sideLeft, sideDivider)
                context.lineTo(sideLeft, sideBottom - sideRadius)
                context.arc(sideLeft + sideRadius, sideBottom - sideRadius,
                            sideRadius, Math.PI, Math.PI / 2, true)
                context.lineTo(left, sideBottom)
                context.lineTo(left, sideDivider)
                context.closePath()
            }

            context.clearRect(0, 0, width, height)
            context.lineWidth = lineWidth
            context.fillStyle = activeColor

            let clearWheelAfterFill = false
            if (xbutton2Pressed) {
                traceUpperSideButton()
                context.fill()
            } else if (xbutton1Pressed) {
                traceLowerSideButton()
                context.fill()
            } else if (wheelPressed) {
                traceWheel()
                context.fill()
            } else if (leftPressed) {
                traceLeftFill()
                context.fill()
                clearWheelAfterFill = true
            } else if (rightPressed) {
                traceRightFill()
                context.fill()
                clearWheelAfterFill = true
            }

            if (clearWheelAfterFill) {
                context.save()
                traceWheel()
                context.clip()
                context.clearRect(wheelLeft, wheelTop,
                                  mousePreview.wheelWidth, mousePreview.wheelHeight)
                context.restore()
            }

            context.strokeStyle = outlineColor

            traceOuterBody()
            context.stroke()

            context.beginPath()
            context.moveTo(left, divider)
            context.lineTo(right, divider)
            context.moveTo(center, top)
            context.lineTo(center, wheelTop)
            context.moveTo(center, wheelBottom)
            context.lineTo(center, divider)
            context.stroke()

            traceWheel()
            context.stroke()
            traceSideButton()
            context.stroke()
            context.beginPath()
            context.moveTo(sideLeft, sideDivider)
            context.lineTo(left, sideDivider)
            context.stroke()

            context.strokeStyle = activeColor
            if (xbutton2Active) {
                traceUpperSideButton()
                context.stroke()
            } else if (xbutton1Active) {
                traceLowerSideButton()
                context.stroke()
            } else if (wheelActive) {
                traceWheel()
                context.stroke()
            } else if (leftActive) {
                traceLeftButton()
                context.stroke()
            } else if (rightActive) {
                traceRightButton()
                context.stroke()
            }
        }
    }
}
