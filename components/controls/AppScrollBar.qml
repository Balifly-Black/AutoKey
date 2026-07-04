import QtQuick
import QtQuick.Templates as T

T.ScrollBar {
    id: control

    required property var rootWindow

    readonly property bool pointerHovered: barHover.hovered || handleHover.hovered
    // 常规状态使用不透明中性灰色，避免受主题文字透明度影响。
    readonly property color defaultHandleColor: rootWindow.darkMode
                                                ? AppConfig.scrollBarHandleColorDark
                                                : AppConfig.scrollBarHandleColorLight

    // 滚动条仅在内容溢出时出现，首尾不保留额外按钮或内边距。
    policy: T.ScrollBar.AsNeeded
    hoverEnabled: true
    minimumSize: 0.08
    padding: 0
    implicitWidth: orientation === Qt.Vertical ? 8 : 100
    implicitHeight: orientation === Qt.Horizontal ? 8 : 100
    visible: size < 1.0
    opacity: 1.0

    // 附着式 ScrollBar 的 hovered 状态不稳定，单独监听整个滚动条区域。
    HoverHandler {
        id: barHover
    }

    // 轨道仅在鼠标悬浮时显示，并使用主题的轻量背景色。
    background: Rectangle {
        radius: width < height ? width / 2 : height / 2
        color: control.pointerHovered
               ? control.rootWindow.menuHoverColor
               : AppConfig.transparentColor

        Behavior on color {
            ColorAnimation {
                duration: AppConfig.animDurationFast
                easing.type: Easing.OutCubic
            }
        }
    }

    // 滑块始终保持不透明，只通过颜色区分悬浮和按下状态。
    contentItem: Rectangle {
        id: handle

        implicitWidth: 6
        implicitHeight: 6
        radius: width < height ? width / 2 : height / 2
        color: control.pressed
               ? AppConfig.accentColor
               : (control.pointerHovered
                  ? AppConfig.accentHoverColor
                  : control.defaultHandleColor)
        opacity: 1.0

        Behavior on color {
            ColorAnimation {
                duration: AppConfig.animDurationFast
                easing.type: Easing.OutCubic
            }
        }

        // 直接监听滑块本身，保证指针进入滑块时立即切换悬浮色。
        HoverHandler {
            id: handleHover
        }
    }
}
