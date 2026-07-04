// ResizeBorder.qml — 可复用的窗口缩放边框组件
// 替代 main.qml 中 8 个重复的 MouseArea，减少代码重复
import QtQuick

MouseArea {
    id: resizeBorder

    // 缩放边缘：Qt.LeftEdge | Qt.TopEdge | Qt.RightEdge | Qt.BottomEdge
    required property int edge
    // 所属窗口
    required property var rootWindow

    // 根据边缘自动计算光标形状
    cursorShape: {
        const edges = resizeBorder.edge
        // 顶部边缘
        if (edges === Qt.TopEdge) return Qt.SizeVerCursor
        // 底部边缘
        if (edges === Qt.BottomEdge) return Qt.SizeVerCursor
        // 左侧边缘
        if (edges === Qt.LeftEdge) return Qt.SizeHorCursor
        // 右侧边缘
        if (edges === Qt.RightEdge) return Qt.SizeHorCursor
        // 左上、右下角
        if (edges === (Qt.LeftEdge | Qt.TopEdge) || edges === (Qt.RightEdge | Qt.BottomEdge))
            return Qt.SizeFDiagCursor
        // 右上、左下角
        if (edges === (Qt.RightEdge | Qt.TopEdge) || edges === (Qt.LeftEdge | Qt.BottomEdge))
            return Qt.SizeBDiagCursor
        return Qt.ArrowCursor
    }

    onPressed: rootWindow.startSystemResize(resizeBorder.edge)
}
