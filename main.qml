import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "components"
import "pages"

Window {
    id: mainWindow

    // 设置页持久化的应用偏好，供全局主题和提示音音量实时绑定。
    property string themePreference: "system"
    property int notificationVolume: 50
    // systemDarkMode 保留系统真实状态，darkMode 再叠加用户手动选择。
    readonly property bool systemDarkMode: systemPalette.window.hslLightness < 0.5
    readonly property bool darkMode: themePreference === "dark"
                                     || (themePreference === "system" && systemDarkMode)

    readonly property string navIconTheme: darkMode ? "white" : "black"
    // 主题颜色统一从 AppConfig 获取
    readonly property color panelColor: darkMode ? AppConfig.darkPanelColor : AppConfig.lightPanelColor
    readonly property color acrylicPanelColor: darkMode ? AppConfig.darkAcrylicPanelColor : AppConfig.lightAcrylicPanelColor
    readonly property color titleBarColor: darkMode ? AppConfig.darkTitleBarColor : AppConfig.lightTitleBarColor
    readonly property color borderColor: darkMode ? AppConfig.darkBorderColor : AppConfig.lightBorderColor
    readonly property color textColor: darkMode ? AppConfig.darkTextColor : AppConfig.lightTextColor
    readonly property color mutedTextColor: darkMode ? AppConfig.darkMutedTextColor : AppConfig.lightMutedTextColor
    readonly property color menuHoverColor: darkMode ? AppConfig.darkMenuHoverColor : AppConfig.lightMenuHoverColor

    // 版本信息统一从 AppConfig 获取
    readonly property string authorName: AppConfig.authorName
    readonly property string releaseDate: AppConfig.releaseDate
    readonly property string appVersion: AppConfig.appVersion

    property int currentPage: 0
    property var floatingConfigs: []
    readonly property int resizeBorderWidth: AppConfig.resizeBorderWidth
    property bool authenticated: false

    // 置顶切换
    property bool pinned: false

    function togglePinned() {
        pinned = !pinned
        if (pinned) {
            flags = Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        } else {
            flags = Qt.Window | Qt.FramelessWindowHint
        }
    }
    property string currentTimeText: Qt.formatDateTime(new Date(), "HH:mm:ss")

    // 启动时从 preferences.json 读取应用级设置；配置列表仍由 ConsolePage 自己加载。
    function loadAppPreferences() {
        const jsonText = PreferencesStore.loadJson()
        if (jsonText.length <= 0)
            return

        try {
            const preferences = JSON.parse(jsonText)
            const theme = String(preferences.theme || "system")
            themePreference = ["light", "dark", "system"].includes(theme) ? theme : "system"
            const volume = Number(preferences.notificationVolume)
            notificationVolume = Number.isFinite(volume)
                               ? Math.max(0, Math.min(100, Math.round(volume)))
                               : 50
        } catch (error) {
            console.warn("preferences.json 解析失败，使用默认应用设置:", error)
        }
    }

    // 只更新应用级设置字段，并保留已有 configs，避免设置页保存时覆盖脚本配置。
    function saveAppPreferences() {
        let preferences = {
            version: 1,
            configs: []
        }
        const jsonText = PreferencesStore.loadJson()
        if (jsonText.length > 0) {
            try {
                preferences = JSON.parse(jsonText)
            } catch (error) {
                console.warn("preferences.json 解析失败，将只保存应用设置:", error)
            }
        }
        preferences.version = preferences.version || 1
        preferences.theme = themePreference
        preferences.notificationVolume = notificationVolume
        preferences.configs = Array.isArray(preferences.configs) ? preferences.configs : []
        return PreferencesStore.saveJson(JSON.stringify(preferences, null, 2))
    }

    function initializeFloatingConfigs(configs) {
        const items = []
        for (let index = 0; index < configs.length; ++index) {
            const config = configs[index]
            const isAdvanced = config.settingsMode === "advanced"
            items.push({
                configIndex: index,
                isAdvanced: isAdvanced,
                title: config.title || qsTr("未命名配置"),
                enabled: config.enabled !== false,
                mode: config.mode || "",
                switchKey: config.switchKey || "",
                toggleBindings: config.advancedToggleBindings || ({}),
                iconName: config.targetIconName
                          || (isAdvanced
                              ? "riLine-terminal-box-line.svg"
                              : "riLine-keyboard-box-line.svg"),
                active: false,
                toggles: config.toggleStates || ({})
            })
        }
        floatingConfigs = items
    }

    function updateFloatingConfig(index, changes) {
        if (index < 0 || index >= floatingConfigs.length)
            return
        const oldItem = floatingConfigs[index]
        const items = floatingConfigs.slice()
        items[index] = Object.assign({}, oldItem, changes)
        floatingConfigs = items

        // 配置运行状态切换时触发提示音
        if (changes.active !== undefined && changes.active !== oldItem.active) {
            floatingStatusWindow.notifyStateChanged(oldItem.title, changes.active)
        }
        // toggles 表中每个开关状态变化时分别触发提示音
        if (changes.toggles !== undefined) {
            const oldToggles = oldItem.toggles || ({})
            const newToggles = changes.toggles
            const names = Object.keys(newToggles)
            for (let i = 0; i < names.length; ++i) {
                const name = names[i]
                if (newToggles[name] !== oldToggles[name]) {
                    floatingStatusWindow.notifyStateChanged(
                        oldItem.title + "\n" + name, newToggles[name])
                }
            }
        }
    }

    // 窗口尺寸统一从 AppConfig 获取
    width: AppConfig.windowDefaultWidth
    height: AppConfig.windowDefaultHeight
    minimumWidth: AppConfig.windowMinWidth
    minimumHeight: AppConfig.windowMinHeight
    color: panelColor
    visible: true
    flags: Qt.Window | Qt.FramelessWindowHint
    title: qsTr("AutoKey")

    // 窗口加载完成后设置一次圆角
    Component.onCompleted: {
        loadAppPreferences()
        Qt.callLater(() => AcrylicWindow.enableBorder(mainWindow))
    }

    // 防抖定时器：避免拖拽缩放时频繁调用 DWM API（每秒数十次）
    Timer {
        id: resizeDebounceTimer
        interval: 100   // 100ms 防抖间隔
        repeat: false
        onTriggered: {
            if (mainWindow.visible)
                AcrylicWindow.enableBorder(mainWindow)
        }
    }

    onWidthChanged: { if (visible) resizeDebounceTimer.restart() }
    onHeightChanged: { if (visible) resizeDebounceTimer.restart() }

    SystemPalette {
        id: systemPalette
        colorGroup: SystemPalette.Active
    }

    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: mainWindow.currentTimeText = Qt.formatDateTime(new Date(), "HH:mm:ss")
    }

    TitleBar {
        id: titleBar
        z: 10  // 确保始终在最上层，不被页面内容覆盖
        visible: mainWindow.authenticated

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        rootWindow: mainWindow

        onLogoutRequested: {
            if (AutoKeyEngine.running)
                AutoKeyEngine.stop()
            mainWindow.authenticated = false
        }
    }

    SideMenu {
        id: sideMenu

        anchors.top: titleBar.bottom
        anchors.left: parent.left
        anchors.bottom: footerBar.top
        rootWindow: mainWindow
        currentPage: mainWindow.currentPage
        visible: mainWindow.authenticated

        onPageRequested: index => mainWindow.currentPage = index
    }

    StackLayout {
        id: pageStack

        anchors.top: titleBar.bottom
        anchors.left: sideMenu.right
        anchors.right: parent.right
        anchors.bottom: footerBar.top
        currentIndex: mainWindow.currentPage
        visible: mainWindow.authenticated

        ConsolePage {
            id: consolePage
            rootWindow: mainWindow

            onStartRequested: {
                if (AutoKeyEngine.running) {
                    AutoKeyEngine.stop()
                    return
                }
                const configs = consolePage.collectConfigs()
                mainWindow.initializeFloatingConfigs(configs)
                AutoKeyEngine.loadConfigs(configs)
                AutoKeyEngine.start()
            }

            onLogRequested: logWindow.showLog()

            onAddConfigRequested: {
            }
        }

        // 引擎状态绑定：引擎启停反映到按钮文本
        Connections {
            target: AutoKeyEngine

            function onRunningChanged(running) {
                if (running)
                    floatingStatusWindow.showStatus()
                else
                    floatingStatusWindow.finishAndHide()
            }

            function onConfigStateChanged(index, active) {
                mainWindow.updateFloatingConfig(index, { active: active })
            }

            function onConfigTogglesChanged(index, toggles) {
                mainWindow.updateFloatingConfig(index, { toggles: toggles })
            }

            function onLogMessage(message) {
                logWindow.appendLog(message)
            }
        }

        EditPage {
            rootWindow: mainWindow
        }

        SettingsPage {
            rootWindow: mainWindow
        }

        CloudPage {
            rootWindow: mainWindow
        }

        ProfilePage {
            rootWindow: mainWindow
        }

        AboutPage {
            rootWindow: mainWindow
        }
    }

    FooterBar {
        id: footerBar
        z: 10  // 确保始终在最上层，不被页面内容覆盖

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        rootWindow: mainWindow
        visible: mainWindow.authenticated
    }

    // ====== 窗口缩放边框 ======
    // 使用 ResizeBorder 组件替代 8 个重复的 MouseArea
    // 四条边（水平/垂直缩放）
    ResizeBorder {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: mainWindow.resizeBorderWidth
        edge: Qt.LeftEdge
        rootWindow: mainWindow
    }

    ResizeBorder {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: mainWindow.resizeBorderWidth
        edge: Qt.RightEdge
        rootWindow: mainWindow
    }

    ResizeBorder {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: mainWindow.resizeBorderWidth
        edge: Qt.TopEdge
        rootWindow: mainWindow
    }

    ResizeBorder {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: mainWindow.resizeBorderWidth
        edge: Qt.BottomEdge
        rootWindow: mainWindow
    }

    // 四个角（对角线缩放，必须在边之后声明以确保 z 序在上层）
    ResizeBorder {
        anchors.left: parent.left
        anchors.top: parent.top
        width: mainWindow.resizeBorderWidth
        height: mainWindow.resizeBorderWidth
        edge: Qt.LeftEdge | Qt.TopEdge
        rootWindow: mainWindow
    }

    ResizeBorder {
        anchors.right: parent.right
        anchors.top: parent.top
        width: mainWindow.resizeBorderWidth
        height: mainWindow.resizeBorderWidth
        edge: Qt.RightEdge | Qt.TopEdge
        rootWindow: mainWindow
    }

    ResizeBorder {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: mainWindow.resizeBorderWidth
        height: mainWindow.resizeBorderWidth
        edge: Qt.LeftEdge | Qt.BottomEdge
        rootWindow: mainWindow
    }

    ResizeBorder {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: mainWindow.resizeBorderWidth
        height: mainWindow.resizeBorderWidth
        edge: Qt.RightEdge | Qt.BottomEdge
        rootWindow: mainWindow
    }

    property int trackedConfigIndex: -1

    // 引擎停止时清除追踪状态
    Connections {
        target: AutoKeyEngine
        function onRunningChanged(running) {
            if (!running)
                mainWindow.trackedConfigIndex = -1
        }
        function onRecognitionResultUpdated(configIndex, result) {
            if (result && Object.keys(result).length > 0) {
                recognitionOverlay.scanResult = result
            }
        }
    }

    // 全屏识别结果叠加层，visible 由引擎追踪状态驱动。
    RecognitionOverlay {
        id: recognitionOverlay
        visible: AutoKeyEngine.recognitionOverlayActive
    }
    ScreenCaptureOverlay {
        controller: ScreenCapture
        rootWindow: mainWindow
    }

    FloatingStatusWindow {
        id: floatingStatusWindow
        rootWindow: mainWindow
        configs: mainWindow.floatingConfigs
        engineRunning: AutoKeyEngine.running
        enginePaused: AutoKeyEngine.paused

        onPauseResumeRequested: {
            if (AutoKeyEngine.paused)
                AutoKeyEngine.resume()
            else
                AutoKeyEngine.pause()
        }
        onStopRequested: AutoKeyEngine.stop()

        onRecognitionCheckRequested: function(configIndex) {
            // 点击同一图标 → 关闭；点击其他图标或在关闭态点击 → 开启追踪
            if (mainWindow.trackedConfigIndex === configIndex) {
                AutoKeyEngine.setRecognitionOverlayTracking(configIndex, false)
                mainWindow.trackedConfigIndex = -1
            } else {
                if (mainWindow.trackedConfigIndex >= 0)
                    AutoKeyEngine.setRecognitionOverlayTracking(
                        mainWindow.trackedConfigIndex, false)
                AutoKeyEngine.setRecognitionOverlayTracking(configIndex, true)
                mainWindow.trackedConfigIndex = configIndex
            }
        }
    }

    LogWindow {
        id: logWindow
        rootWindow: mainWindow
    }

    AuthPage {
        id: authPage
        anchors.fill: parent
        z: 100
        visible: !mainWindow.authenticated
        rootWindow: mainWindow

        onLoginAccepted: mainWindow.authenticated = true
    }
}
