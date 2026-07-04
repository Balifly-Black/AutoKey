import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import "../components/controls"

Item {
    id: consolePage

    required property var rootWindow

    // 颜色统一从 AppConfig 获取
    readonly property color accentColor: AppConfig.accentColor
    readonly property color cardBorderColor: rootWindow.darkMode
                                                ? AppConfig.cardBorderColorDark
                                                : AppConfig.cardBorderColorLight
    readonly property color chipColor: rootWindow.darkMode ? AppConfig.chipColorDark : AppConfig.chipColorLight
    readonly property color chipTextColor: rootWindow.darkMode ? AppConfig.chipTextColorDark : AppConfig.chipTextColorLight
    readonly property color selectedTabColor: rootWindow.darkMode ? AppConfig.selectedTabColorDark : AppConfig.selectedTabColorLight
    readonly property color selectedTabTextColor: rootWindow.darkMode ? AppConfig.selectedTabTextColorDark : AppConfig.selectedTabTextColorLight

    property int selectedConfigIndex: -1
    property int settingsTabIndex: 0
    // 高级模式子页：0=脚本，1=键位，2=取色。
    property int advancedTabIndex: 0
    property bool editEnabled: true
    property string editTitle: "配置"
    property string editMode: "开关模式"
    property string editDelay: "10"
    property var editKeys: []
    property int editKeysRevision: 0
    property string editSwitchKey: ""
    // 基础与高级模式使用不同文件格式，路径必须独立保存。
    property string editBasicPath: ""
    property string editAdvancedPath: ""
    // 高级脚本正文独立于基础模式按键序列保存。
    property string advancedScriptText: ""
    property string advancedScriptSavedText: ""
    // 高级按键绑定独立保存为“脚本槽位名 -> 用户键位”。
    property var editAdvancedKeyBindings: ({})
    property var editAdvancedToggleBindings: ({})
    // 图片识别区域使用全局屏幕坐标，随高级配置独立保存。
    property var editRecognitionRegion: ({})
    readonly property bool advancedScriptDirty: advancedScriptText !== advancedScriptSavedText
    property bool waitingForSwitchKey: false
    property bool editTitleEditing: false
    property bool editDelayEditing: false

    signal startRequested()
    signal logRequested()
    signal addConfigRequested()

    Component.onCompleted: loadPreferences()

    function localPathFromUrl(fileUrl) {
        const text = decodeURIComponent(String(fileUrl))
        if (text.indexOf("file:///") === 0)
            return text.substring(8).replace(/\//g, "\\")
        if (text.indexOf("file://") === 0)
            return text.substring(7).replace(/\//g, "\\")
        return text
    }

    function scriptModeName() {
        return settingsTabIndex === 0 ? "basic" : "advanced"
    }

    function currentTargetPath() {
        return settingsTabIndex === 0 ? editBasicPath : editAdvancedPath
    }

    function recognitionRegionText() {
        const region = editRecognitionRegion || ({})
        const x = Number(region.x)
        const y = Number(region.y)
        const width = Number(region.width)
        const height = Number(region.height)
        // 空对象会产生 NaN，必须先验证四个字段都是有限数字。
        if (!Number.isFinite(x) || !Number.isFinite(y)
                || !Number.isFinite(width) || !Number.isFinite(height)
                || width <= 0 || height <= 0) {
            return qsTr("点击设置识别区域")
        }
        // 按钮直接展示全局起点和区域尺寸，便于确认当前识别范围。
        return qsTr("%1, %2  %3×%4")
            .arg(x).arg(y).arg(width).arg(height)
    }

    function normalizedScriptPath(path) {
        // Windows 路径比较忽略大小写，并统一正反斜杠。
        return String(path || "").trim().replace(/\//g, "\\").toLowerCase()
    }

    function configIndexUsingPath(path, excludedIndex) {
        const normalizedPath = normalizedScriptPath(path)
        if (normalizedPath.length === 0)
            return -1

        // 基础和高级路径都参与全局唯一性检查。
        for (let index = 0; index < configModel.count; ++index) {
            if (index === excludedIndex)
                continue

            const config = configModel.get(index)
            if (normalizedScriptPath(config.basicPath) === normalizedPath
                    || normalizedScriptPath(config.advancedPath) === normalizedPath) {
                return index
            }
        }
        return -1
    }

    function showDuplicatePathMessage(configIndex) {
        const ownerTitle = configIndex >= 0 && configIndex < configModel.count
                         ? configModel.get(configIndex).title
                         : qsTr("其他配置")
        pathRequiredMessage.showMessage(
            qsTr("Lua 文件已被使用"),
            qsTr("该 Lua 文件已绑定到“%1”，一个文件不能同时用于两个配置。").arg(ownerTitle))
    }

    function showPathRequiredMessage() {
        const modeName = settingsTabIndex === 0 ? qsTr("基础模式") : qsTr("高级模式")
        pathRequiredMessage.showMessage(
            qsTr("未设置文件路径"),
            qsTr("请先为%1设置 Lua 文件路径，再保存配置。").arg(modeName))
    }

    function hasValidRecognitionRegion() {
        const region = editRecognitionRegion || ({})
        return Number.isFinite(Number(region.x))
                && Number.isFinite(Number(region.y))
                && Number.isFinite(Number(region.width))
                && Number.isFinite(Number(region.height))
                && Number(region.width) > 0
                && Number(region.height) > 0
    }

    function incompleteSettings() {
        const missing = []
        const normalizedDelay = Number(editDelay)

        if (editTitle.trim().length === 0)
            missing.push(qsTr("配置名称"))
        if (!Number.isInteger(normalizedDelay) || normalizedDelay <= 0)
            missing.push(qsTr("有效的延迟时间"))
        if (editSwitchKey.trim().length === 0)
            missing.push(qsTr("开关按键"))

        if (settingsTabIndex === 0) {
            if (editBasicPath.trim().length === 0)
                missing.push(qsTr("基础模式 Lua 文件"))
            if (editKeys.length === 0)
                missing.push(qsTr("基础模式按键"))
            return missing
        }

        const scriptPath = editAdvancedPath.trim()
        const scriptText = advancedScriptText.trim()
        if (scriptPath.length === 0)
            missing.push(qsTr("高级模式 Lua 文件"))
        if (scriptText.length === 0) {
            missing.push(qsTr("Lua 脚本内容"))
            return missing
        }
        if (PreferencesStore.luaScriptName(advancedScriptText).trim().length === 0)
            missing.push(qsTr("Lua 脚本名称 name"))

        const scriptSlots = PreferencesStore.luaScriptKeys(advancedScriptText)
        const unboundSlots = []
        for (let keyIndex = 0; keyIndex < scriptSlots.length; ++keyIndex) {
            const slotName = scriptSlots[keyIndex]
            if (!editAdvancedKeyBindings[slotName])
                unboundSlots.push(slotName)
        }
        if (unboundSlots.length > 0)
            missing.push(qsTr("按键绑定（%1）").arg(unboundSlots.join("、")))

        const toggleSlots = Object.keys(PreferencesStore.luaScriptToggles(advancedScriptText))
        const unboundToggles = []
        for (let toggleIndex = 0; toggleIndex < toggleSlots.length; ++toggleIndex) {
            const toggleName = toggleSlots[toggleIndex]
            if (!editAdvancedToggleBindings[toggleName])
                unboundToggles.push(toggleName)
        }
        if (unboundToggles.length > 0)
            missing.push(qsTr("触发器绑定（%1）").arg(unboundToggles.join("、")))

        if (scriptPath.length > 0) {
            const imageSlots = PreferencesStore.luaScriptTableItems(advancedScriptText, "image")
            const missingImages = []
            for (let imageIndex = 0; imageIndex < imageSlots.length; ++imageIndex) {
                const slotName = imageSlots[imageIndex]
                if (PreferencesStore.capturePngUrl(scriptPath, slotName).length === 0)
                    missingImages.push(slotName)
            }
            if (missingImages.length > 0)
                missing.push(qsTr("截图（%1）").arg(missingImages.join("、")))
            if (imageSlots.length > 0 && !hasValidRecognitionRegion())
                missing.push(qsTr("图片识别区域"))

            const pixelSlots = PreferencesStore.luaScriptTableItems(advancedScriptText, "pixel")
            const missingPixels = []
            for (let pixelIndex = 0; pixelIndex < pixelSlots.length; ++pixelIndex) {
                const slotName = pixelSlots[pixelIndex]
                if (PreferencesStore.capturePixelColor(scriptPath, slotName).length === 0)
                    missingPixels.push(slotName)
            }
            if (missingPixels.length > 0)
                missing.push(qsTr("取点（%1）").arg(missingPixels.join("、")))
        }

        return missing
    }

    function validateCompleteSettings() {
        const missing = incompleteSettings()
        if (missing.length === 0)
            return true

        pathRequiredMessage.showMessage(
            qsTr("配置未完成"),
            qsTr("请先完成以下设置：\n%1").arg(missing.join("、")))
        return false
    }

    function openNewScriptDialog() {
        // 新建脚本选择目标文件名，确认后写入空白高级脚本或基础模板。
        newScriptDialog.currentFolder = PreferencesStore.scriptDirUrl(scriptModeName())
        newScriptDialog.open()
    }

    function openLoadScriptDialog() {
        // 加载脚本只允许选择已有 Lua 文件。
        loadScriptDialog.currentFolder = PreferencesStore.scriptDirUrl(scriptModeName())
        loadScriptDialog.open()
    }

    function applyScriptPath(path, createNew) {
        const duplicateConfigIndex = configIndexUsingPath(path, selectedConfigIndex)
        if (duplicateConfigIndex >= 0) {
            showDuplicatePathMessage(duplicateConfigIndex)
            return
        }

        if (settingsTabIndex === 0) {
            editBasicPath = path
            if (createNew) {
                // 基础模式新建文件时立即生成当前按键对应的模板。
                PreferencesStore.saveBasicScript(path, editKeys, 1)
            } else {
                editKeys = PreferencesStore.loadScriptKeys(path)
                editKeysRevision += 1
            }
        } else {
            editAdvancedPath = path
            advancedScriptText = createNew ? "" : PreferencesStore.loadTextFile(path)
            if (createNew)
                PreferencesStore.saveTextFile(path, advancedScriptText)
            advancedScriptSavedText = advancedScriptText
        }
    }

    function saveAdvancedScriptText() {
        // 未设置高级路径时通过应用内消息窗口提示。
        if (editAdvancedPath.trim().length === 0) {
            showPathRequiredMessage()
            return false
        }

        if (!validateAdvancedScriptSyntax())
            return false

        // Ctrl+S 和工具栏保存按钮执行相同的路径唯一性校验。
        const duplicateConfigIndex = configIndexUsingPath(editAdvancedPath, selectedConfigIndex)
        if (duplicateConfigIndex >= 0) {
            showDuplicatePathMessage(duplicateConfigIndex)
            return false
        }

        const saved = PreferencesStore.saveTextFile(editAdvancedPath.trim(), advancedScriptText)
        if (saved) {
            advancedScriptSavedText = advancedScriptText
        }
        return saved
    }

    function validateAdvancedScriptSyntax() {
        const syntaxError = PreferencesStore.luaSyntaxError(advancedScriptText)
        if (syntaxError.length === 0)
            return true

        pathRequiredMessage.showMessage(
            qsTr("Lua 语法错误"),
            qsTr("请修正后再保存：\n%1").arg(syntaxError))
        return false
    }

    function normalizeConfig(config, index) {
        const keys = Array.isArray(config.keys) ? config.keys : String(config.keys || "").split(",")
        const legacyKind = config.detailKind || "keyboard"
        const settingsMode = config.settingsMode
                          || (legacyKind === "code" || legacyKind === "color" ? "advanced" : "basic")
        const advancedTab = config.advancedTab === undefined
                          ? (legacyKind === "color" ? 2 : (legacyKind === "keyboard" && settingsMode === "advanced" ? 1 : 0))
                          : Number(config.advancedTab)
        const basicKeys = Array.isArray(config.basicKeys)
                        ? config.basicKeys
                        : (settingsMode === "basic" ? keys : [])
        const advancedScriptName = config.advancedScriptName
                                || (settingsMode === "advanced" && keys.length > 0 ? String(keys[0]) : "")
        const basicPath = config.basicPath
                       || (settingsMode === "basic" ? (config.targetPath || config.path || "") : "")
        const advancedPath = config.advancedPath
                          || (settingsMode === "advanced" ? (config.targetPath || config.path || "") : "")
        const cardTags = settingsMode === "basic" ? basicKeys : (advancedScriptName ? [advancedScriptName] : [])

        return {
            title: config.title || ("配置" + String(index + 1)),
            configEnabled: config.enabled === undefined ? true : Boolean(config.enabled),
            mode: config.mode || "开关模式",
            targetIconName: config.targetIconName || "riLine-keyboard-box-line.svg",
            settingsMode: settingsMode,
            advancedTab: advancedTab,
            basicKeysText: basicKeys.filter(key => String(key).length > 0).join(","),
            advancedScriptName: advancedScriptName,
            advancedKeyBindings: config.advancedKeyBindings || ({}),
            advancedToggleBindings: config.advancedToggleBindings || ({}),
            recognitionRegion: config.recognitionRegion || ({}),
            basicPath: basicPath,
            advancedPath: advancedPath,
            keysText: cardTags.join(","),
            switchKey: config.switchKey || "",
            // 旧配置未提供循环延迟时统一使用 10ms。
            delay: String(config.delay === undefined ? 10 : config.delay),
            detailKind: settingsMode === "basic" ? "keyboard" : ["code", "keyboard", "color"][advancedTab]
        }
    }

    function loadPreferences() {
        let preferences = null
        const jsonText = PreferencesStore.loadJson()

        if (jsonText.length > 0) {
            try {
                preferences = JSON.parse(jsonText)
            } catch (error) {
                console.warn("preferences.json 解析失败，使用默认配置:", error)
            }
        }

        const configs = preferences && Array.isArray(preferences.configs)
                      ? preferences.configs
                      : []

        configModel.clear()
        for (let i = 0; i < configs.length; ++i)
            configModel.append(normalizeConfig(configs[i], i))
    }

    function configToJsonObject(index) {
        const config = configModel.get(index)
        const isBasic = config.settingsMode === "basic"
        const activeKeys = isBasic
                         ? String(config.basicKeysText).split(",").filter(key => key.length > 0)
                         : (config.advancedScriptName ? [config.advancedScriptName] : [])
        const activePath = isBasic ? config.basicPath : config.advancedPath
        const advancedSource = !isBasic && config.advancedPath
                             ? PreferencesStore.loadTextFile(config.advancedPath)
                             : ""
        return {
            title: config.title,
            enabled: config.configEnabled,
            mode: config.mode,
            targetIconName: config.targetIconName,
            settingsMode: config.settingsMode,
            advancedTab: config.advancedTab,
            basicKeys: String(config.basicKeysText).split(",").filter(key => key.length > 0),
            advancedScriptName: config.advancedScriptName || "",
            advancedKeyBindings: config.advancedKeyBindings || ({}),
            advancedToggleBindings: config.advancedToggleBindings || ({}),
            toggleStates: isBasic ? ({}) : PreferencesStore.luaScriptToggles(advancedSource),
            recognitionRegion: config.recognitionRegion || ({}),
            basicPath: config.basicPath || "",
            advancedPath: config.advancedPath || "",
            // 保留当前模式的扁平字段，供运行引擎直接读取。
            keys: activeKeys,
            switchKey: config.switchKey || "",
            targetPath: activePath || "",
            delay: Number(config.delay),
            detailKind: config.detailKind
        }
    }

    // 收集所有配置（供引擎加载）
    function collectConfigs() {
        const configs = []
        for (let i = 0; i < configModel.count; ++i)
            configs.push(configToJsonObject(i))
        return configs
    }

    function savePreferences() {
        const configs = collectConfigs()

        return PreferencesStore.saveJson(JSON.stringify({
            version: 1,
            theme: rootWindow.themePreference,
            notificationVolume: rootWindow.notificationVolume,
            configs: configs
        }, null, 2))
    }

    function openConfig(index) {
        const config = configModel.get(index)
        selectedConfigIndex = index
        settingsTabIndex = config.settingsMode === "advanced" ? 1 : 0
        advancedTabIndex = Number(config.advancedTab || 0)
        editTitle = config.title
        editEnabled = config.configEnabled
        editMode = config.mode
        editDelay = config.delay
        editKeys = String(config.basicKeysText).split(",").filter(key => key.length > 0)
        editSwitchKey = config.switchKey
        editBasicPath = config.basicPath || ""
        editAdvancedPath = config.advancedPath || ""
        advancedScriptText = editAdvancedPath.length > 0
                           ? PreferencesStore.loadTextFile(editAdvancedPath)
                           : ""
        // 打开配置时以磁盘正文作为未修改基线。
        advancedScriptSavedText = advancedScriptText
        // 克隆 ListModel 中的绑定对象，编辑期间不直接修改已保存配置。
        editAdvancedKeyBindings = Object.assign({}, config.advancedKeyBindings || {})
        editAdvancedToggleBindings = Object.assign({}, config.advancedToggleBindings || {})
        editRecognitionRegion = Object.assign({}, config.recognitionRegion || {})
        waitingForSwitchKey = false
        editKeysRevision += 1
        detailEnabledSwitch.checked = editEnabled
    }

    function handleBasicKeyClicked(keyName) {
        if (waitingForSwitchKey) {
            editSwitchKey = keyName
            waitingForSwitchKey = false
            return
        }

        addKeyTag(keyName)
    }

    function handleAdvancedKeyClicked(keyName) {
        // 高级按键输入只用于脚本逻辑和开关键捕获，不写入基础模式 Tag。
        if (waitingForSwitchKey) {
            editSwitchKey = keyName
            waitingForSwitchKey = false
        }
    }

    function addKeyTag(keyName) {
        if (editKeys.indexOf(keyName) >= 0)
            return

        const nextKeys = editKeys.slice()
        nextKeys.push(keyName)
        editKeys = nextKeys
        editKeysRevision += 1
    }

    function removeKeyTag(tagIndex) {
        const nextKeys = editKeys.slice()
        nextKeys.splice(tagIndex, 1)
        editKeys = nextKeys
        editKeysRevision += 1
    }

    // 删除指定索引的配置
    function removeConfig(index) {
        if (index < 0 || index >= configModel.count)
            return

        // 如果正在编辑被删除的配置，先退出编辑
        if (selectedConfigIndex === index)
            cancelEdit()

        configModel.remove(index)
        savePreferences()
    }

    function saveCurrentConfig() {
        if (selectedConfigIndex < 0 || selectedConfigIndex >= configModel.count)
            return

        // 有脚本内容时优先报告准确的 Lua 行号，避免被字段完整性提示掩盖。
        if (settingsTabIndex === 1
                && advancedScriptText.trim().length > 0
                && !validateAdvancedScriptSyntax())
            return

        // 保存前一次性检查当前模式所需的全部配置，避免写入无法运行的配置。
        if (!validateCompleteSettings())
            return

        const duplicateConfigIndex = configIndexUsingPath(currentTargetPath(), selectedConfigIndex)
        if (duplicateConfigIndex >= 0) {
            showDuplicatePathMessage(duplicateConfigIndex)
            return
        }

        const normalizedDelay = Number(editDelay)
        const normalizedTitle = editTitle.trim()

        configModel.setProperty(selectedConfigIndex, "title", normalizedTitle)
        configModel.setProperty(selectedConfigIndex, "configEnabled", editEnabled)
        configModel.setProperty(selectedConfigIndex, "mode", editMode)
        configModel.setProperty(selectedConfigIndex, "delay", String(normalizedDelay))
        configModel.setProperty(selectedConfigIndex, "switchKey", editSwitchKey)
        configModel.setProperty(selectedConfigIndex, "settingsMode",
                                consolePage.settingsTabIndex === 0 ? "basic" : "advanced")
        configModel.setProperty(selectedConfigIndex, "advancedTab", consolePage.advancedTabIndex)
        configModel.setProperty(selectedConfigIndex, "basicPath", editBasicPath.trim())
        configModel.setProperty(selectedConfigIndex, "advancedPath", editAdvancedPath.trim())
        configModel.setProperty(selectedConfigIndex, "basicKeysText", editKeys.join(","))

        // 只保存当前脚本仍声明的槽位，脚本删掉槽位后同步移除旧绑定。
        const scriptSlots = PreferencesStore.luaScriptKeys(advancedScriptText)
        const savedBindings = {}
        for (let slotIndex = 0; slotIndex < scriptSlots.length; ++slotIndex) {
            const slotName = scriptSlots[slotIndex]
            if (editAdvancedKeyBindings[slotName])
                savedBindings[slotName] = editAdvancedKeyBindings[slotName]
        }
        editAdvancedKeyBindings = savedBindings
        configModel.setProperty(selectedConfigIndex, "advancedKeyBindings", savedBindings)

        const toggleSlots = Object.keys(PreferencesStore.luaScriptToggles(advancedScriptText))
        const savedToggleBindings = {}
        for (let toggleIndex = 0; toggleIndex < toggleSlots.length; ++toggleIndex) {
            const toggleName = toggleSlots[toggleIndex]
            if (editAdvancedToggleBindings[toggleName])
                savedToggleBindings[toggleName] = editAdvancedToggleBindings[toggleName]
        }
        editAdvancedToggleBindings = savedToggleBindings
        configModel.setProperty(selectedConfigIndex, "advancedToggleBindings", savedToggleBindings)
        configModel.setProperty(selectedConfigIndex, "recognitionRegion",
                                Object.assign({}, editRecognitionRegion))

        if (consolePage.settingsTabIndex === 0 && editBasicPath.trim().length > 0) {
            if (!PreferencesStore.saveBasicScript(editBasicPath.trim(), editKeys, 1))
                return
        } else if (consolePage.settingsTabIndex === 1
                   && consolePage.advancedTabIndex === 0) {
            // 右侧“保存”同时持久化当前高级脚本文本。
            if (!PreferencesStore.saveTextFile(editAdvancedPath.trim(), advancedScriptText))
                return
            advancedScriptSavedText = advancedScriptText
        }

        // 高级模式根据当前子页保存对应的数据类型。
        const advancedKinds = ["code", "keyboard", "color"]
        const detailKind = consolePage.settingsTabIndex === 0
                         ? "keyboard"
                         : advancedKinds[consolePage.advancedTabIndex]
        configModel.setProperty(selectedConfigIndex, "detailKind", detailKind)
        // 脚本卡片显示 Lua name 变量；键盘配置仍显示按键 Tag。
        const advancedScriptName = PreferencesStore.luaScriptName(advancedScriptText)
        configModel.setProperty(selectedConfigIndex, "advancedScriptName", advancedScriptName)
        configModel.setProperty(selectedConfigIndex, "keysText",
            consolePage.settingsTabIndex === 0 ? editKeys.join(",") : advancedScriptName)
        // 图标跟随 detailKind 切换
        configModel.setProperty(selectedConfigIndex, "targetIconName",
            consolePage.settingsTabIndex === 0
                ? "riLine-keyboard-box-line.svg"
                : "riLine-terminal-box-line.svg")

        if (savePreferences())
            selectedConfigIndex = -1
    }

    function cancelEdit() {
        waitingForSwitchKey = false
        editTitleEditing = false
        editDelayEditing = false
        selectedConfigIndex = -1
    }

    function modeIconName(modeName) {
        return modeName === "按压模式" ? "riLine-fingerprint-line.svg" : "riLine-compass-2-line.svg"
    }

    ListModel {
        id: configModel
    }

    FileDialog {
        id: newScriptDialog

        title: qsTr("新建 Lua 脚本")
        fileMode: FileDialog.SaveFile
        defaultSuffix: "lua"
        nameFilters: [qsTr("Lua 脚本 (*.lua)")]
        onAccepted: consolePage.applyScriptPath(
                        consolePage.localPathFromUrl(selectedFile), true)
    }

    FileDialog {
        id: loadScriptDialog

        title: qsTr("加载 Lua 脚本")
        fileMode: FileDialog.OpenFile
        nameFilters: [
            qsTr("Lua 脚本 (*.lua)"),
            qsTr("所有文件 (*.*)")
        ]
        onAccepted: consolePage.applyScriptPath(
                        consolePage.localPathFromUrl(selectedFile), false)
    }

    function handleAdvancedKeyBinding(slotName, keyName) {
        // 替换整个对象以触发按键页的绑定刷新。
        const updatedBindings = Object.assign({}, editAdvancedKeyBindings)
        updatedBindings[slotName] = keyName
        editAdvancedKeyBindings = updatedBindings
    }

    function handleAdvancedToggleBinding(slotName, keyName) {
        const updatedBindings = Object.assign({}, editAdvancedToggleBindings)
        updatedBindings[slotName] = keyName
        editAdvancedToggleBindings = updatedBindings
    }

    // 可复用的应用内消息窗口，用于保存校验等提示场景。
    MessageWindow {
        id: pathRequiredMessage
        rootWindow: consolePage.rootWindow
    }

    // 卡片列表滚动容器
    Flickable {
        id: cardListFlickable
        visible: consolePage.selectedConfigIndex < 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        contentWidth: parent.width
        contentHeight: cardListColumn.implicitHeight + 20
        boundsBehavior: Flickable.StopAtBounds

        // 全局统一滚动条样式。
        ScrollBar.vertical: AppScrollBar {
            rootWindow: consolePage.rootWindow
        }

        Column {
            id: cardListColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 10
            anchors.rightMargin: 10
            spacing: 26

        Label {
            text: qsTr("操作台")
            color: rootWindow.textColor
            font.pixelSize: 34
            font.bold: true
        }

        Row {
            spacing: 20

            // 启动按钮 — 带悬浮外发光
            Item {
                width: 120
                height: 46
                readonly property color actionColor: AutoKeyEngine.running
                                                     ? AppConfig.dangerColor
                                                     : consolePage.accentColor

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -6
                    radius: 7 + 6
                    color: parent.actionColor
                    opacity: startArea.containsMouse ? 0.08 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    radius: 7 + 4
                    color: parent.actionColor
                    opacity: startArea.containsMouse ? 0.15 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    radius: 7 + 2
                    color: parent.actionColor
                    opacity: startArea.containsMouse ? 0.25 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 7
                    color: parent.actionColor

                    Label {
                        anchors.centerIn: parent
                        text: AutoKeyEngine.running ? qsTr("停止") : qsTr("启动")
                        color: AppConfig.whiteTextColor
                        font.pixelSize: 20
                        font.bold: true
                    }

                    MouseArea {
                        id: startArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: consolePage.startRequested()
                    }
                }
            }

            // 日志按钮 — 带悬浮外发光
            Item {
                width: 120
                height: 46

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -6
                    radius: 7 + 6
                    color: AppConfig.accentColor
                    opacity: logArea.containsMouse ? 0.08 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    radius: 7 + 4
                    color: AppConfig.accentColor
                    opacity: logArea.containsMouse ? 0.15 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    radius: 7 + 2
                    color: AppConfig.accentColor
                    opacity: logArea.containsMouse ? 0.25 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 7
                    // 直接用窗口面板背景色
                    color: rootWindow.panelColor
                    border.color: consolePage.accentColor
                    border.width: 2

                    Label {
                        anchors.centerIn: parent
                        text: qsTr("日志")
                        color: consolePage.accentColor
                        font.pixelSize: 20
                        font.bold: true
                    }

                    MouseArea {
                        id: logArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: consolePage.logRequested()
                    }
                }
            }
        }

        Flow {
            width: consolePage.width - 20
            spacing: 14

            Repeater {
                model: configModel

                delegate: Item {
                    width: 180
                    height: 100

                    // 外发光效果 — 在卡片后面渲染，不影响卡片内部颜色
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -6
                        radius: configCard.radius + 6
                        color: AppConfig.accentColor
                        opacity: cardArea.containsMouse ? 0.08 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -4
                        radius: configCard.radius + 4
                        color: AppConfig.accentColor
                        opacity: cardArea.containsMouse ? 0.15 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -2
                        radius: configCard.radius + 2
                        color: AppConfig.accentColor
                        opacity: cardArea.containsMouse ? 0.25 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    // 卡片主体 — 渲染在发光层上方
                    Rectangle {
                        id: configCard

                        anchors.fill: parent
                        radius: 6
                        color: rootWindow.darkMode
                               ? AppConfig.configCardColorDark
                               : AppConfig.configCardColorLight
                        border.color: cardArea.containsMouse ? consolePage.accentColor : consolePage.cardBorderColor
                        border.width: 1

                        // cardArea 放在 Column 之前，这样 Column 内的交互元素（开关、删除按钮）
                        // 事件层级高于 cardArea，不会被 cardArea 拦截点击
                        MouseArea {
                            id: cardArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: consolePage.openConfig(index)
                        }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Row {
                            width: parent.width
                            height: 22
                            spacing: 6

                            ToggleSwitch {
                                width: 32
                                height: 18
                                anchors.verticalCenter: parent.verticalCenter
                                checked: configEnabled
                                accentColor: consolePage.accentColor
                                onToggled: {
                                    configModel.setProperty(index, "configEnabled", checked)
                                    consolePage.savePreferences()
                                }
                            }

                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                text: title.length > 5 ? title.substring(0, 5) + "..." : title
                                color: rootWindow.textColor
                                font.pixelSize: 15
                                font.bold: true
                            }

                            Item {
                                width: Math.max(0, parent.width - 120)
                                height: 1
                            }
                        }

                        Row {
                            width: parent.width
                            height: 20
                            spacing: 5

                            Image {
                                width: 14
                                height: 14
                                anchors.verticalCenter: parent.verticalCenter
                                source: Qt.resolvedUrl("../icons/common/" + rootWindow.navIconTheme + "/" + consolePage.modeIconName(mode))
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                cache: false
                            }

                            Label {
                                id: modeText

                                anchors.verticalCenter: parent.verticalCenter
                                text: mode
                                color: rootWindow.mutedTextColor
                                font.pixelSize: 13
                            }

                            Rectangle {
                                id: switchKeyBadge

                                visible: switchKey.length > 0
                                anchors.verticalCenter: parent.verticalCenter
                                // 尺寸、圆角和内边距与第三行 Tag 完全一致。
                                width: visible ? switchKeyBadgeText.implicitWidth + 12 : 0
                                height: 18
                                radius: 4
                                color: AppConfig.transparentColor
                                border.color: rootWindow.mutedTextColor
                                border.width: 1

                                Label {
                                    id: switchKeyBadgeText

                                    anchors.centerIn: parent
                                    // 键帽显示当前配置的开关按键名称。
                                    text: switchKey
                                    color: rootWindow.mutedTextColor
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }
                        }

                        Item {
                            id: chipsRowContainer
                            width: parent.width
                            height: 20

                            // 芯片区域：不裁剪像素，改为隐藏溢出芯片（避免显示半个 tag）
                            Item {
                                id: chipsArea
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                // 可用宽度 = 整行宽 - 删除图标宽 - 省略号空间
                                readonly property real availableWidth: parent.width - deleteIcon.width - 22
                                width: Math.min(chipsRow.implicitWidth, availableWidth)
                                height: 20

                                Row {
                                    id: chipsRow
                                    spacing: 4

                                    Repeater {
                                        model: keysText ? keysText.split(",").filter(k => k.length > 0) : []

                                        delegate: Rectangle {
                                            // 超出可用宽度的芯片变透明（保持布局占位，避免绑定循环）
                                            opacity: x + width <= chipsArea.availableWidth ? 1.0 : 0.0
                                            width: keyText.implicitWidth + 12
                                            height: 20
                                            radius: 4
                                            color: consolePage.chipColor

                                            Label {
                                                id: keyText

                                                anchors.centerIn: parent
                                                text: modelData
                                                color: consolePage.chipTextColor
                                                font.pixelSize: 13
                                                font.bold: true
                                            }
                                        }
                                    }
                                }
                            }

                            // 溢出省略号（有芯片被隐藏时显示）
                            Label {
                                id: overflowLabel
                                anchors.left: chipsArea.right
                                anchors.leftMargin: 2
                                anchors.verticalCenter: parent.verticalCenter
                                visible: chipsRow.implicitWidth > chipsArea.availableWidth
                                text: "..."
                                color: rootWindow.mutedTextColor
                                font.pixelSize: 13
                            }

                            // 删除图标 — 第三行最右侧，悬浮切换红色图标
                            Image {
                                id: deleteIcon
                                width: 18
                                height: 18
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                source: deleteIconArea.containsMouse
                                    ? Qt.resolvedUrl("../icons/common/red/riLine-delete-bin-line.svg")
                                    : Qt.resolvedUrl("../icons/common/" + rootWindow.navIconTheme
                                                     + "/riLine-delete-bin-line.svg")
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                cache: false
                                // 常规态灰色（低透明度），悬浮态红色（完全不透明）
                                opacity: deleteIconArea.containsMouse ? 1.0 : 0.35

                                MouseArea {
                                    id: deleteIconArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: mouse => {
                                        mouse.accepted = true  // 阻止冒泡到 cardArea
                                        consolePage.removeConfig(index)
                                    }
                                }
                            }
                        }
                    }

                    // 类型图标（右上角，锚定卡片边框，不受 Column 布局影响）
                    Image {
                        width: 18
                        height: 18
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 10
                        source: Qt.resolvedUrl("../icons/common/" + rootWindow.navIconTheme + "/" + targetIconName)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        cache: false
                    }
                }
            }
            }

            Item {
                width: 180
                height: 100

                // 外发光效果 — 与配置卡片一致
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -6
                    radius: addCard.radius + 6
                    color: AppConfig.accentColor
                    opacity: addConfigArea.containsMouse ? 0.08 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    radius: addCard.radius + 4
                    color: AppConfig.accentColor
                    opacity: addConfigArea.containsMouse ? 0.15 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    radius: addCard.radius + 2
                    color: AppConfig.accentColor
                    opacity: addConfigArea.containsMouse ? 0.25 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                Rectangle {
                    id: addCard

                    anchors.fill: parent
                    radius: 7
                    color: rootWindow.darkMode
                           ? AppConfig.configCardColorDark
                           : AppConfig.configCardColorLight
                    border.color: addConfigArea.containsMouse ? consolePage.accentColor : consolePage.cardBorderColor
                    border.width: 1

                    Label {
                        anchors.centerIn: parent
                        text: "+"
                        color: rootWindow.textColor
                        font.pixelSize: 28
                        opacity: addConfigArea.containsMouse ? 0.9 : 0.65
                    }
                }

                MouseArea {
                    id: addConfigArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        configModel.append(normalizeConfig({
                            title: "配置" + String(configModel.count + 1),
                            enabled: true,
                            mode: "开关模式",
                            targetIconName: "riLine-keyboard-box-line.svg",
                            keys: [],
                            switchKey: "",
                            targetPath: "",
                            delay: 10,
                            detailKind: "keyboard"
                        }, configModel.count))
                        savePreferences()
                        consolePage.addConfigRequested()
                    }
                }
            }
        }
    }
    }  // Flickable

    Item {
        visible: consolePage.selectedConfigIndex >= 0
        anchors.fill: parent
        anchors.topMargin: 10
        anchors.rightMargin: 20
        anchors.bottomMargin: 10

        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            onClicked: {
                if (!titleInput.contains(mapToItem(titleInput, mouse.x, mouse.y)) &&
                    !delayInput.contains(mapToItem(delayInput, mouse.x, mouse.y))) {
                    titleInput.focus = false
                    delayInput.focus = false
                    consolePage.editTitleEditing = false
                    consolePage.editDelayEditing = false
                }
                mouse.accepted = false
            }
        }

        Row {
            id: editHeader

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 34
            spacing: 18

            Row {
                id: titleEditor

                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                TextInput {
                    id: titleInput

                    width: Math.max(76, contentWidth + 4)
                    text: consolePage.editTitle
                    color: rootWindow.textColor
                    selectedTextColor: AppConfig.whiteTextColor
                    selectionColor: consolePage.accentColor
                    font.pixelSize: 30
                    font.bold: true
                    selectByMouse: true
                    clip: true
                    readOnly: !consolePage.editTitleEditing
                    cursorVisible: consolePage.editTitleEditing
                    onTextEdited: consolePage.editTitle = text
                    onEditingFinished: {
                        consolePage.editTitle = text
                        consolePage.editTitleEditing = false
                    }
                    Keys.onReturnPressed: {
                        consolePage.editTitle = text
                        consolePage.editTitleEditing = false
                        focus = false
                    }
                    Keys.onEscapePressed: {
                        consolePage.editTitleEditing = false
                        focus = false
                    }
                }

                Image {
                    width: 16
                    height: 16
                    anchors.verticalCenter: parent.verticalCenter
                    source: Qt.resolvedUrl("../icons/common/" + rootWindow.navIconTheme + "/riLine-edit-line.svg")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    cache: false

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            consolePage.editTitleEditing = true
                            titleInput.forceActiveFocus()
                        }
                    }
                }
            }

            ToggleSwitch {
                id: detailEnabledSwitch

                width: 42
                height: 22
                anchors.verticalCenter: parent.verticalCenter
                checked: consolePage.editEnabled
                accentColor: consolePage.accentColor
                onToggled: checked => consolePage.editEnabled = checked
            }

            Row {
                id: modeSelector

                anchors.verticalCenter: parent.verticalCenter
                spacing: 14

                Repeater {
                    model: ["开关模式", "按压模式"]

                    delegate: Item {
                        width: modeRow.implicitWidth
                        height: 18

                        Row {
                            id: modeRow

                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 5

                            Rectangle {
                                width: 12
                                height: 12
                                radius: width / 2
                                anchors.verticalCenter: parent.verticalCenter
                                color: AppConfig.transparentColor
                                border.width: 1
                                border.color: consolePage.accentColor

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 6
                                    height: 6
                                    radius: width / 2
                                    color: consolePage.editMode === modelData
                                           ? consolePage.accentColor
                                           : AppConfig.transparentColor
                                }
                            }

                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData
                                color: rootWindow.textColor
                                font.pixelSize: 13
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: consolePage.editMode = modelData
                        }
                    }
                }
            }

            Row {
                id: delayEditor

                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("延迟：")
                    color: rootWindow.textColor
                    font.pixelSize: 13
                }

                Item {
                    id: delayInputBox

                    width: 24
                    height: 20
                    anchors.verticalCenter: parent.verticalCenter

                    TextInput {
                        id: delayInput

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: delayUnderline.top
                        text: consolePage.editDelay
                        color: consolePage.accentColor
                        selectedTextColor: AppConfig.whiteTextColor
                        selectionColor: consolePage.accentColor
                        font.pixelSize: 13
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        selectByMouse: true
                        readOnly: !consolePage.editDelayEditing
                        cursorVisible: consolePage.editDelayEditing
                        maximumLength: 2
                        validator: IntValidator {
                            bottom: 1
                            top: 99
                        }
                        onTextEdited: consolePage.editDelay = text
                        onEditingFinished: {
                            if (Number(text) <= 0 || text.length === 0)
                                text = "1"
                            consolePage.editDelay = text
                            consolePage.editDelayEditing = false
                        }
                        Keys.onReturnPressed: {
                            if (Number(text) <= 0 || text.length === 0)
                                text = "1"
                            consolePage.editDelay = text
                            consolePage.editDelayEditing = false
                            focus = false
                        }
                        Keys.onEscapePressed: {
                            consolePage.editDelayEditing = false
                            focus = false
                        }
                    }

                    Rectangle {
                        id: delayUnderline

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: consolePage.accentColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.IBeamCursor
                        onClicked: {
                            if (!consolePage.editDelayEditing) {
                                consolePage.editDelayEditing = true
                                delayInput.forceActiveFocus()
                            }
                        }
                    }
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("ms")
                    color: rootWindow.textColor
                    font.pixelSize: 13
                }
            }

            Label {
                id: scriptPathButton

                anchors.verticalCenter: parent.verticalCenter
                width: 160
                // 顶部路径仅用于展示，文件选择统一由底部“新建/加载”入口完成。
                text: consolePage.currentTargetPath().length > 0
                      ? consolePage.currentTargetPath()
                      : qsTr(" 未设置路径 ")
                color: consolePage.accentColor
                font.pixelSize: 13
                font.underline: true
                elide: Text.ElideMiddle
                opacity: 0.9
            }

            Item {
                width: Math.max(0,
                                editHeader.width
                                - titleEditor.width
                                - detailEnabledSwitch.width
                                - modeSelector.width
                                - delayEditor.width
                                - scriptPathButton.width
                                - settingsSwitch.width
                                - editHeader.spacing * 6)
                height: 1
            }

            Rectangle {
                id: settingsSwitch

                width: 116
                height: 25
                anchors.verticalCenter: parent.verticalCenter
                radius: height / 2
                color: AppConfig.transparentColor
                border.color: consolePage.selectedTabColor
                border.width: 1
                clip: true

                Repeater {
                    model: [
                        {
                            title: "基础",
                            iconName: "riLine-keyboard-box-line.svg"
                        },
                        {
                            title: "高级",
                            iconName: "riLine-terminal-box-line.svg"
                        }
                    ]

                    delegate: Item {
                        x: index * (settingsSwitch.width / 2)
                        width: settingsSwitch.width / 2
                        height: settingsSwitch.height

                        Rectangle {
                            anchors.fill: parent
                            radius: settingsSwitch.radius
                            color: consolePage.settingsTabIndex === index
                                   ? consolePage.selectedTabColor
                                   : AppConfig.transparentColor
                        }

                        Rectangle {
                            visible: consolePage.settingsTabIndex === index
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.left: index === 0 ? undefined : parent.left
                            anchors.right: index === 0 ? parent.right : undefined
                            width: settingsSwitch.radius
                            color: consolePage.selectedTabColor
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 3

                            Image {
                                width: 15
                                height: 15
                                anchors.verticalCenter: parent.verticalCenter
                                source: Qt.resolvedUrl("../icons/common/"
                                                       + (consolePage.settingsTabIndex === index ? (rootWindow.darkMode ? "black" : "white") : rootWindow.navIconTheme)
                                                       + "/" + modelData.iconName)
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                cache: false
                            }

                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.title
                                color: consolePage.settingsTabIndex === index ? consolePage.selectedTabTextColor : rootWindow.textColor
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // 切换基础/高级模式时清理临时输入状态。
                                consolePage.waitingForSwitchKey = false
                                consolePage.settingsTabIndex = index
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: consolePage.selectedTabColor
                }
            }
        }

        StackLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: editHeader.bottom
            anchors.bottom: footerActions.top
            anchors.topMargin: 22
            anchors.bottomMargin: 14
            clip: true
            currentIndex: consolePage.settingsTabIndex

            ConsoleBasicPage {
                rootWindow: consolePage.rootWindow
                chipColor: consolePage.chipColor
                chipTextColor: consolePage.chipTextColor
                keyTags: consolePage.editKeys
                keyTagsRevision: consolePage.editKeysRevision
                onKeyClicked: keyName => consolePage.handleBasicKeyClicked(keyName)
                onKeyRemoved: index => consolePage.removeKeyTag(index)
            }

            ConsoleAdvancedPage {
                id: advancedSettingsPage

                rootWindow: consolePage.rootWindow
                currentTab: consolePage.advancedTabIndex
                scriptText: consolePage.advancedScriptText
                scriptPath: consolePage.editAdvancedPath
                scriptDirty: consolePage.advancedScriptDirty
                keyBindings: consolePage.editAdvancedKeyBindings
                toggleBindings: consolePage.editAdvancedToggleBindings
                waitingForSwitchKey: consolePage.waitingForSwitchKey
                onKeyClicked: keyName => consolePage.handleAdvancedKeyClicked(keyName)
                onKeyBindingChanged: (slotName, keyName) =>
                    consolePage.handleAdvancedKeyBinding(slotName, keyName)
                onToggleBindingChanged: (slotName, keyName) =>
                    consolePage.handleAdvancedToggleBinding(slotName, keyName)
                onScriptTextEdited: text => consolePage.advancedScriptText = text
                onSaveRequested: consolePage.saveAdvancedScriptText()
                onCapturePathRequired: consolePage.showPathRequiredMessage()
                onRecognitionRegionSelected: region => {
                    // 替换对象以触发底部按钮坐标文本立即刷新。
                    consolePage.editRecognitionRegion = Object.assign({}, region)
                }
            }
        }

        Item {
            id: footerActions

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            height: 34

            // 高级模式内部的三段页签与底部操作按钮保持在同一行。
            Rectangle {
                id: advancedTabSwitch

                visible: consolePage.settingsTabIndex === 1
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: 292
                height: 34
                radius: 4
                color: AppConfig.transparentColor
                border.color: rootWindow.textColor
                border.width: 1
                clip: true

                Repeater {
                    model: [qsTr("脚本"), qsTr("键位"), qsTr("取色")]

                    Item {
                        x: index * advancedTabSwitch.width / 3
                        width: advancedTabSwitch.width / 3
                        height: advancedTabSwitch.height

                        Canvas {
                            id: selectedTabBackground

                            anchors.fill: parent
                            visible: consolePage.advancedTabIndex === index
                            antialiasing: true

                            readonly property color fillColor: consolePage.selectedTabColor

                            onFillColorChanged: requestPaint()
                            onVisibleChanged: if (visible) requestPaint()
                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()

                            onPaint: {
                                const context = getContext("2d")
                                const radius = advancedTabSwitch.radius

                                context.clearRect(0, 0, width, height)
                                context.fillStyle = fillColor
                                context.beginPath()

                                if (index === 0) {
                                    // “脚本”仅左上、左下为圆角，靠中间的右侧保持直角。
                                    context.moveTo(radius, 0)
                                    context.lineTo(width, 0)
                                    context.lineTo(width, height)
                                    context.lineTo(radius, height)
                                    context.quadraticCurveTo(0, height, 0, height - radius)
                                    context.lineTo(0, radius)
                                    context.quadraticCurveTo(0, 0, radius, 0)
                                } else if (index === 2) {
                                    // “取色”仅右上、右下为圆角，靠中间的左侧保持直角。
                                    context.moveTo(0, 0)
                                    context.lineTo(width - radius, 0)
                                    context.quadraticCurveTo(width, 0, width, radius)
                                    context.lineTo(width, height - radius)
                                    context.quadraticCurveTo(width, height, width - radius, height)
                                    context.lineTo(0, height)
                                } else {
                                    // 中间“键位”选中项四角均为直角。
                                    context.rect(0, 0, width, height)
                                }

                                context.closePath()
                                context.fill()
                            }
                        }

                        Label {
                            anchors.centerIn: parent
                            text: modelData
                            color: consolePage.advancedTabIndex === index
                                   ? consolePage.selectedTabTextColor
                                   : rootWindow.textColor
                            font.pixelSize: 16
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // 切换高级子页时结束尚未完成的按键捕获。
                                consolePage.waitingForSwitchKey = false
                                consolePage.advancedTabIndex = index
                            }
                        }
                    }
                }

                // 三段按钮之间始终显示分割线，并覆盖在选中背景之上。
                Repeater {
                    model: 2

                    Rectangle {
                        x: (index + 1) * advancedTabSwitch.width / 3 - width / 2
                        width: 1
                        height: advancedTabSwitch.height
                        color: rootWindow.textColor
                    }
                }
            }

            Rectangle {
                id: switchKeyButton

                // 脚本页保存入口已移动到编辑器工具栏，底部不再显示“保存文本”。
                visible: !(consolePage.settingsTabIndex === 1
                           && consolePage.advancedTabIndex === 0)
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(148, switchKeyText.implicitWidth + 20)
                height: 34
                radius: 4
                color: consolePage.waitingForSwitchKey
                       ? (switchKeyArea.containsMouse ? AppConfig.accentHoverColor : consolePage.accentColor)
                       : AppConfig.transparentColor

                Canvas {
                    id: switchKeyOutline

                    anchors.fill: parent

                    readonly property color outlineColor: switchKeyArea.containsMouse
                                                                   ? AppConfig.accentHoverColor
                                                                   : consolePage.accentColor
                    readonly property bool waiting: consolePage.waitingForSwitchKey

                    onOutlineColorChanged: requestPaint()
                    onWaitingChanged: requestPaint()

                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        ctx.strokeStyle = outlineColor
                        ctx.lineWidth = 1
                        if (ctx.setLineDash)
                            ctx.setLineDash(waiting ? [] : [5, 4])
                        ctx.beginPath()
                        const radius = switchKeyButton.radius
                        const left = 0.5
                        const top = 0.5
                        const right = width - 0.5
                        const bottom = height - 0.5
                        ctx.moveTo(left + radius, top)
                        ctx.lineTo(right - radius, top)
                        ctx.quadraticCurveTo(right, top, right, top + radius)
                        ctx.lineTo(right, bottom - radius)
                        ctx.quadraticCurveTo(right, bottom, right - radius, bottom)
                        ctx.lineTo(left + radius, bottom)
                        ctx.quadraticCurveTo(left, bottom, left, bottom - radius)
                        ctx.lineTo(left, top + radius)
                        ctx.quadraticCurveTo(left, top, left + radius, top)
                        ctx.stroke()
                    }
                }

                Label {
                    id: switchKeyText

                    anchors.centerIn: parent
                    // 左侧动作按钮根据高级子页切换文案。
                    text: consolePage.settingsTabIndex === 1 && consolePage.advancedTabIndex === 2
                             ? consolePage.recognitionRegionText()
                             : (consolePage.waitingForSwitchKey
                                ? qsTr("点击键盘或鼠标")
                                : (consolePage.editSwitchKey.length > 0
                                   ? consolePage.editSwitchKey
                                   : qsTr("点击设置开关按键")))
                    color: consolePage.waitingForSwitchKey
                           ? AppConfig.whiteTextColor
                           : (switchKeyArea.containsMouse ? AppConfig.accentHoverColor : consolePage.accentColor)
                    font.pixelSize: 16
                    font.bold: true
                }

                MouseArea {
                    id: switchKeyArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        // 只有基础页和高级按键页需要进入开关按键捕获状态。
                        if (consolePage.settingsTabIndex === 0 || consolePage.advancedTabIndex === 1)
                            consolePage.waitingForSwitchKey = true
                        else if (consolePage.advancedTabIndex === 2)
                            // 识别区域复用截图框选交互，但只保存坐标而不生成图片。
                            advancedSettingsPage.beginScreenCapture("region", "recognition")
                    }
                }
            }

            Row {
                id: pathActionButtons

                // 基础模式和高级脚本页通过底部按钮新建或加载各自格式的 Lua 文件。
                visible: consolePage.settingsTabIndex === 0
                         || consolePage.advancedTabIndex === 0
                // Repeater 不提供稳定隐式宽度，显式设置后再紧贴右侧保存操作区。
                width: 210
                x: consolePage.settingsTabIndex === 0
                   ? footerSaveButtons.x - width - 10
                   : 0
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Repeater {
                    model: [
                        { text: qsTr("新建"), createNew: true },
                        { text: qsTr("加载"), createNew: false }
                    ]

                    Rectangle {
                        // 与右侧“取消 / 保存”按钮保持相同宽度。
                        width: 100
                        height: 34
                        radius: 4
                        color: AppConfig.transparentColor
                        border.color: pathActionArea.containsMouse
                                      ? AppConfig.accentHoverColor
                                      : consolePage.accentColor
                        border.width: 1

                        Label {
                            anchors.centerIn: parent
                            text: modelData.text
                            color: pathActionArea.containsMouse
                                   ? AppConfig.accentHoverColor
                                   : consolePage.accentColor
                            font.pixelSize: 16
                            font.bold: true
                        }

                        MouseArea {
                            id: pathActionArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // 两个按钮分别打开保存文件和打开文件对话框。
                                if (modelData.createNew)
                                    consolePage.openNewScriptDialog()
                                else
                                    consolePage.openLoadScriptDialog()
                            }
                        }
                    }
                }
            }

            Row {
                id: footerSaveButtons

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Rectangle {
                    id: cancelButton

                    width: 100
                    height: 34
                    radius: 4
                    color: AppConfig.transparentColor
                    border.color: cancelArea.containsMouse ? AppConfig.accentHoverColor : consolePage.accentColor
                    border.width: 1

                    Label {
                        anchors.centerIn: parent
                        text: qsTr("取消")
                        color: cancelArea.containsMouse ? AppConfig.accentHoverColor : consolePage.accentColor
                        font.pixelSize: 16
                        font.bold: true
                    }

                    MouseArea {
                        id: cancelArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: consolePage.cancelEdit()
                    }
                }

                Rectangle {
                    width: 100
                    height: 34
                    radius: 4
                    color: saveArea.containsMouse ? AppConfig.accentHoverColor : consolePage.accentColor

                    Label {
                        anchors.centerIn: parent
                        text: qsTr("保存")
                        color: AppConfig.whiteTextColor
                        font.pixelSize: 16
                        font.bold: true
                    }

                    MouseArea {
                        id: saveArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: consolePage.saveCurrentConfig()
                    }
                }
            }
        }
    }
}
