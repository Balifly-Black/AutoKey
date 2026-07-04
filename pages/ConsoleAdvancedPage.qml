import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Effects
import QtQuick.Layouts
import "../components/controls"

Item {
    id: advancedPage

    required property var rootWindow
    required property int currentTab
    required property string scriptText
    required property string scriptPath
    required property bool scriptDirty
    required property var keyBindings
    required property var toggleBindings
    required property bool waitingForSwitchKey
    readonly property real editorLineHeight: 20
    // 编辑器统一使用字体管理器注册的代码字体。
    readonly property string editorFontFamily: Fonts.codeFamily
    // Lua keys 表只定义可配置槽位，实际键位由 keyBindings 单独保存。
    readonly property var scriptKeys: PreferencesStore.luaScriptKeys(scriptText)
    readonly property var scriptToggles: Object.keys(PreferencesStore.luaScriptToggles(scriptText))
    // 取色页的截图和取点槽位分别来自 image、pixel 表。
    readonly property var scriptImages: PreferencesStore.luaScriptTableItems(scriptText, "image")
    readonly property var scriptPixels: PreferencesStore.luaScriptTableItems(scriptText, "pixel")
    property string pendingKeySlot: ""
    property string pendingBindingKind: ""
    property bool searchVisible: false
    property bool replaceVisible: false
    property var searchMatches: []
    property int currentSearchIndex: -1
    property int searchAnchorPosition: 0
    property string pendingCaptureMode: ""
    property string pendingCaptureSlot: ""
    property int capturePreviewRevision: 0

    signal keyClicked(string keyName)
    signal keyBindingChanged(string slotName, string keyName)
    signal toggleBindingChanged(string slotName, string keyName)
    signal scriptTextEdited(string text)
    signal saveRequested()
    signal capturePathRequired()
    signal recognitionRegionSelected(var region)

    function beginScreenCapture(mode, slotName) {
        if (scriptPath.trim().length === 0) {
            capturePathRequired()
            return
        }

        // 先隐藏主窗口，短暂等待桌面完成重绘后再缓存干净屏幕画面。
        pendingCaptureMode = mode
        pendingCaptureSlot = slotName
        rootWindow.hide()
        captureDelay.restart()
    }

    Timer {
        id: captureDelay

        interval: 160
        repeat: false
        onTriggered: {
            if (!ScreenCapture.begin(advancedPage.pendingCaptureMode,
                                     advancedPage.scriptPath,
                                     advancedPage.pendingCaptureSlot)) {
                // 启动失败时立即恢复主窗口，避免应用留在隐藏状态。
                advancedPage.rootWindow.show()
                advancedPage.rootWindow.requestActivate()
            }
        }
    }

    Connections {
        target: ScreenCapture

        function onCaptureFinished(success, mode, slotName) {
            if (success && (mode === "image" || mode === "pixel")) {
                // 文件保存完成后改变修订号，强制所有截图和颜色预览重新读取磁盘。
                advancedPage.capturePreviewRevision += 1
            }
        }

        function onRegionSelected(x, y, width, height) {
            // 识别区域由父页面写入当前配置草稿，取消编辑时不会污染已保存配置。
            advancedPage.recognitionRegionSelected({
                x: x, y: y, width: width, height: height
            })
        }
    }

    function captureImageSource(slotName) {
        // 查询修订号参与绑定依赖，覆盖同名 PNG 后也会生成新的加载 URL。
        const revision = capturePreviewRevision
        const source = PreferencesStore.capturePngUrl(scriptPath, slotName)
        return source.length > 0 ? source + "?revision=" + revision : ""
    }

    function capturePointColor(slotName) {
        // 取点颜色从 JSON 读取，空字符串表示槽位尚未采集。
        capturePreviewRevision
        return PreferencesStore.capturePixelColor(scriptPath, slotName)
    }

    function iconPath(iconName) {
        // 编辑器工具图标跟随当前明暗主题选择已经转为十六进制颜色的资源。
        return Qt.resolvedUrl("../icons/common/" + rootWindow.navIconTheme + "/" + iconName)
    }

    function refreshSearchMatches() {
        // 使用纯文本匹配生成全部命中位置，空查询不会保留旧结果。
        const term = searchInput.text
        const matches = []
        if (term.length > 0) {
            let offset = 0
            while (offset <= scriptEditor.text.length - term.length) {
                const position = scriptEditor.text.indexOf(term, offset)
                if (position < 0)
                    break
                matches.push(position)
                offset = position + Math.max(1, term.length)
            }
        }
        searchMatches = matches
        if (matches.length === 0) {
            currentSearchIndex = -1
            return
        }
        if (currentSearchIndex < 0 || currentSearchIndex >= matches.length)
            currentSearchIndex = 0
    }

    function selectSearchMatch(index, focusEditor) {
        // 选择当前匹配项，并由正文的光标跟随逻辑滚动到可视区域。
        if (searchMatches.length === 0)
            return
        currentSearchIndex = (index + searchMatches.length) % searchMatches.length
        const position = searchMatches[currentSearchIndex]
        scriptEditor.select(position, position + searchInput.text.length)
        if (focusEditor === undefined || focusEditor)
            scriptEditor.forceActiveFocus()
    }

    function findNext(direction) {
        refreshSearchMatches()
        if (searchMatches.length > 0)
            // 上下项导航保持查找框焦点，便于连续按 Enter 或继续修改查找词。
            selectSearchMatch(currentSearchIndex + direction, false)
    }

    function selectNearestMatch(anchorPosition, focusEditor) {
        // 优先选择光标或选区下方最近的匹配项，文档末尾没有结果时回绕。
        if (searchMatches.length === 0)
            return false
        let nearestIndex = 0
        for (let index = 0; index < searchMatches.length; ++index) {
            if (searchMatches[index] >= anchorPosition) {
                nearestIndex = index
                break
            }
        }
        selectSearchMatch(nearestIndex, focusEditor)
        return true
    }

    function openSearch(openReplaceMode) {
        // Ctrl+F 打开查找，Ctrl+H 打开替换；选区内容会直接成为查找词。
        const selectedTerm = scriptEditor.selectedText
        // 有选区时优先保留并高亮当前选中文本；无选区时才从光标向下查找。
        searchAnchorPosition = selectedTerm.length > 0
                             ? scriptEditor.selectionStart
                             : scriptEditor.cursorPosition
        replaceVisible = Boolean(openReplaceMode)
        searchVisible = true
        if (selectedTerm.length > 0)
            searchInput.text = selectedTerm

        Qt.callLater(() => {
            refreshSearchMatches()
            // 正文高亮匹配项，但输入焦点始终留在查找框供用户继续编辑。
            selectNearestMatch(searchAnchorPosition, false)
            searchInput.forceActiveFocus()
            searchInput.selectAll()
        })
    }

    function replaceCurrentMatch() {
        refreshSearchMatches()
        if (searchMatches.length === 0)
            return
        const position = searchMatches[Math.max(0, currentSearchIndex)]
        scriptEditor.remove(position, position + searchInput.text.length)
        scriptEditor.insert(position, replaceInput.text)
        refreshSearchMatches()
        if (searchMatches.length > 0)
            selectSearchMatch(Math.min(currentSearchIndex, searchMatches.length - 1))
    }

    function replaceAllMatches() {
        refreshSearchMatches()
        // 从后向前替换，避免前面的文本长度变化影响后续位置。
        for (let index = searchMatches.length - 1; index >= 0; --index) {
            const position = searchMatches[index]
            scriptEditor.remove(position, position + searchInput.text.length)
            scriptEditor.insert(position, replaceInput.text)
        }
        refreshSearchMatches()
    }

    // ── Tab 缩进 ──────────────────────────────────────────────
    // 选中多行时整块缩进（4 空格），否则在光标处插入 4 空格。
    function insertTabIndent() {
        var selStart = scriptEditor.selectionStart
        var selEnd = scriptEditor.selectionEnd
        var fullText = scriptEditor.text
        var indent = "    "  // 4 空格缩进，与等宽字体对齐

        if (selStart !== selEnd) {
            // 有选区：缩进选区涉及的所有行
            var lineStart = fullText.lastIndexOf("\n", selStart - 1) + 1
            var lineEnd = fullText.indexOf("\n", selEnd)
            if (lineEnd < 0) lineEnd = fullText.length

            var block = fullText.substring(lineStart, lineEnd)
            var lines = block.split("\n")
            var indented = lines.map(function(l) { return indent + l }).join("\n")

            // 单次撤销操作：通过 C++ beginEditBlock 合并 remove + insert
            PreferencesStore.replaceTextBlock(scriptEditor.textDocument,
                                              lineStart, lineEnd, indented)
            scriptEditor.select(lineStart, lineStart + indented.length)
        } else {
            // 无选区：在光标处直接插入 4 空格（本身就是单次撤销）
            scriptEditor.insert(selStart, indent)
        }
    }

    // ── Shift+Tab 取消缩进 ────────────────────────────────────
    // 选中多行时整块取消缩进，否则取消当前行的前导缩进。
    function unindentSelection() {
        var selStart = scriptEditor.selectionStart
        var selEnd = scriptEditor.selectionEnd
        var fullText = scriptEditor.text

        // 去掉行首一级缩进（4空格 > 制表符 > 1空格）
        function stripOneLevel(str) {
            if (str.substring(0, 4) === "    ") return str.substring(4)
            if (str.charAt(0) === "\t") return str.substring(1)
            if (str.charAt(0) === " ") return str.substring(1)
            return str
        }

        if (selStart !== selEnd) {
            // 有选区：取消选区涉及所有行的缩进
            var lineStart = fullText.lastIndexOf("\n", selStart - 1) + 1
            var lineEnd = fullText.indexOf("\n", selEnd)
            if (lineEnd < 0) lineEnd = fullText.length

            var block = fullText.substring(lineStart, lineEnd)
            var unindented = block.split("\n").map(stripOneLevel).join("\n")

            PreferencesStore.replaceTextBlock(scriptEditor.textDocument,
                                              lineStart, lineEnd, unindented)
            scriptEditor.select(lineStart, lineStart + unindented.length)
        } else {
            // 无选区：取消当前行的缩进
            var lineStart = fullText.lastIndexOf("\n", selStart - 1) + 1
            var lineEnd = fullText.indexOf("\n", selStart)
            if (lineEnd < 0) lineEnd = fullText.length

            var currentLine = fullText.substring(lineStart, lineEnd)
            var unindentedLine = stripOneLevel(currentLine)
            if (unindentedLine === currentLine) return  // 无缩进可取消

            PreferencesStore.replaceTextBlock(scriptEditor.textDocument,
                                              lineStart, lineEnd, unindentedLine)
            var removed = currentLine.length - unindentedLine.length
            scriptEditor.cursorPosition = Math.max(lineStart, selStart - removed)
        }
    }

    // ── Ctrl+/ 注释切换 ───────────────────────────────────────
    // 对选中行或当前行添加/移除 Lua 注释前缀 "--"。
    function toggleComment() {
        var selStart = scriptEditor.selectionStart
        var selEnd = scriptEditor.selectionEnd
        var fullText = scriptEditor.text

        // 确定操作范围：选区涉及的行，或当前光标所在行
        var lineStart = fullText.lastIndexOf("\n", selStart - 1) + 1
        var searchFrom = (selStart !== selEnd) ? selEnd : selStart
        var lineEnd = fullText.indexOf("\n", searchFrom)
        if (lineEnd < 0) lineEnd = fullText.length

        var block = fullText.substring(lineStart, lineEnd)
        var lines = block.split("\n")

        // 判断是否所有非空行都已注释
        var allCommented = lines.every(function(l) {
            var t = l.trim()
            return t.length === 0 || t.substring(0, 2) === "--"
        })

        var toggledLines
        if (allCommented) {
            // 取消注释：移除每行第一个 "--"
            toggledLines = lines.map(function(l) {
                var idx = l.indexOf("--")
                return idx >= 0 ? l.substring(0, idx) + l.substring(idx + 2) : l
            })
        } else {
            // 添加注释：在每行行首插入 "--"
            toggledLines = lines.map(function(l) { return "--" + l })
        }

        var result = toggledLines.join("\n")

        // 单次撤销操作：通过 C++ beginEditBlock 合并 remove + insert
        PreferencesStore.replaceTextBlock(scriptEditor.textDocument,
                                          lineStart, lineEnd, result)

        // 恢复选区或调整光标位置
        if (selStart !== selEnd) {
            scriptEditor.select(lineStart, lineStart + result.length)
        } else {
            var delta = allCommented ? -2 : 2
            scriptEditor.cursorPosition = Math.max(lineStart, selStart + delta)
        }
    }

    function handlePreviewKey(keyName) {
        // 设置开关键时优先交给父页面；否则写入当前等待绑定的脚本槽位。
        if (waitingForSwitchKey) {
            pendingKeySlot = ""
            pendingBindingKind = ""
            keyClicked(keyName)
        } else if (pendingKeySlot.length > 0) {
            if (pendingBindingKind === "toggle")
                toggleBindingChanged(pendingKeySlot, keyName)
            else
                keyBindingChanged(pendingKeySlot, keyName)
            pendingKeySlot = ""
            pendingBindingKind = ""
        }
    }

    onWaitingForSwitchKeyChanged: {
        // 进入开关键捕获状态时取消尚未完成的技能键位绑定。
        if (waitingForSwitchKey) {
            pendingKeySlot = ""
            pendingBindingKind = ""
        }
    }

    function lineNumberText(lineCount) {
        // 行号使用连续文本交给 TextArea 排版，确保与正文基线一致。
        const numbers = []
        for (let line = 1; line <= lineCount; ++line)
            numbers.push(String(line))
        return numbers.join("\n")
    }

    // 高级模式的三个子页面由底部页签统一切换。
    StackLayout {
        anchors.fill: parent
        currentIndex: advancedPage.currentTab

        Item {
            id: scriptPage

            // 脚本编辑区保留固定行号栏，正文区域支持滚动和多行编辑。
            Rectangle {
                id: editorFrame

                anchors.fill: parent
                color: AppConfig.transparentColor

                Rectangle {
                    id: editorToolbar

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 24
                    // 顶部工具条使用统一的轻量背景，不再额外绘制底部分割线。
                    color: advancedPage.rootWindow.menuHoverColor

                    Label {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.right: editorToolButtons.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        // 文件修改后在路径末尾增加星号，未设置路径时显示统一提示。
                        text: (advancedPage.scriptPath.length > 0
                               ? advancedPage.scriptPath : qsTr("未设置路径"))
                              + (advancedPage.scriptDirty ? "*" : "")
                        color: advancedPage.rootWindow.textColor
                        font.pixelSize: 10
                        elide: Text.ElideMiddle
                    }

                    Row {
                        id: editorToolButtons

                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Repeater {
                            model: [
                                {
                                    icon: "riLine-find-replace-line.svg",
                                    action: "find"
                                },
                                {
                                    icon: "riLine-arrow-go-back-line.svg",
                                    action: "undo"
                                },
                                {
                                    icon: "riLine-arrow-go-forward-line.svg",
                                    action: "redo"
                                },
                                {
                                    icon: "riLine-save-line 1.svg",
                                    action: "save"
                                }
                            ]

                            Item {
                                width: 20
                                height: 20

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 3
                                    color: editorToolArea.containsMouse
                                           ? advancedPage.rootWindow.menuHoverColor
                                           : AppConfig.transparentColor
                                }

                                Image {
                                    anchors.centerIn: parent
                                    width: 14
                                    height: 14
                                    source: advancedPage.iconPath(modelData.icon)
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }

                                MouseArea {
                                    id: editorToolArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        // 工具栏操作与编辑器快捷键调用同一组原生编辑能力。
                                        if (modelData.action === "find")
                                            advancedPage.openSearch(false)
                                        else if (modelData.action === "undo")
                                            scriptEditor.undo()
                                        else if (modelData.action === "redo")
                                            scriptEditor.redo()
                                        else
                                            advancedPage.saveRequested()
                                    }
                                }

                            }
                        }
                    }

                }

                Rectangle {
                    id: lineNumberGutter

                    readonly property real horizontalPadding: 10
                    // TextEdit 的空文档仍报告一行；没有内容时行号应为空。
                    readonly property int displayedLineCount: scriptEditor.text.length === 0
                                                              ? 0
                                                              : scriptEditor.lineCount

                    anchors.left: parent.left
                    anchors.top: editorToolbar.bottom
                    anchors.bottom: parent.bottom
                    // 行号栏宽度随最大行号字符宽度增长，左右内边距保持一致。
                    width: Math.ceil(lineNumberMetrics.advanceWidth)
                           + horizontalPadding * 2
                    // 行号栏使用极淡的主题背景，轻微区分正文但不形成明显色块。
                    color: advancedPage.rootWindow.darkMode
                           ? AppConfig.editorGutterDark
                           : AppConfig.editorGutterLight
                    clip: true

                    TextMetrics {
                        id: lineNumberMetrics

                        font: lineNumberEditor.font
                        text: lineNumberGutter.displayedLineCount > 0
                              ? String(lineNumberGutter.displayedLineCount)
                              : ""
                    }

                    TextEdit {
                        id: lineNumberEditor

                        // 与正文使用同一 TextEdit 排版引擎和固定起点，消除控件样式偏移。
                        x: lineNumberGutter.horizontalPadding
                        y: 4 - scriptFlick.contentY
                        width: parent.width - lineNumberGutter.horizontalPadding * 2
                        height: contentHeight
                        text: advancedPage.lineNumberText(lineNumberGutter.displayedLineCount)
                        color: advancedPage.rootWindow.textColor
                        font.family: advancedPage.editorFontFamily
                        // 行号与正文保持相同字体样式，确保视觉基线一致。
                        font.pixelSize: scriptEditor.font.pixelSize
                        horizontalAlignment: Text.AlignRight
                        wrapMode: TextEdit.NoWrap
                        readOnly: true
                        // 行号仅用于展示，不允许鼠标、键盘或焦点产生文本选择。
                        selectByMouse: false
                        selectByKeyboard: false
                        activeFocusOnPress: false
                        cursorVisible: false
                        // 行号文档与正文使用完全相同的固定行高。
                        onTextChanged: Qt.callLater(() => PreferencesStore.setTextDocumentLineHeight(
                                                       textDocument,
                                                       advancedPage.editorLineHeight))
                        Component.onCompleted: PreferencesStore.setTextDocumentLineHeight(
                                                   textDocument,
                                                   advancedPage.editorLineHeight)
                    }
                }

                Flickable {
                    id: scriptFlick

                    anchors.left: lineNumberGutter.right
                    anchors.right: parent.right
                    anchors.top: editorToolbar.bottom
                    anchors.bottom: parent.bottom
                    // 向边框内缩，避免横纵滚动条覆盖编辑器外框。
                    anchors.topMargin: 1
                    anchors.rightMargin: 1
                    anchors.bottomMargin: 1
                    contentWidth: Math.max(width, scriptEditor.contentWidth + 12)
                    contentHeight: Math.max(height, scriptEditor.contentHeight + 8)
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    // 代码编辑器横纵方向共用应用主题滚动条。
                    ScrollBar.vertical: AppScrollBar {
                        rootWindow: advancedPage.rootWindow
                    }
                    ScrollBar.horizontal: AppScrollBar {
                        rootWindow: advancedPage.rootWindow
                    }

                    TextEdit {
                        id: scriptEditor

                        x: 6
                        y: 4
                        width: Math.max(scriptFlick.width - 12, contentWidth)
                        height: Math.max(scriptFlick.height - 8, contentHeight)
                        color: advancedPage.rootWindow.textColor
                        selectionColor: AppConfig.accentColor
                        selectedTextColor: AppConfig.whiteTextColor
                        // 正文统一使用覆盖中英文的等宽字体，使字符在固定行高中稳定居中。
                        font.family: advancedPage.editorFontFamily
                        font.pixelSize: 13
                        textFormat: TextEdit.PlainText
                        wrapMode: TextEdit.NoWrap
                        selectByMouse: true
                        // 查找框获得焦点后仍持续显示正文中的当前匹配选区。
                        persistentSelection: true
                        text: advancedPage.scriptText
                        // 正文编辑器快捷键：Tab 缩进、Ctrl+/ 注释、查找/撤销/恢复/保存。
                        Keys.onPressed: event => {
                            // ── Tab / Shift+Tab 缩进与取消缩进 ──
                            // Qt 将 Shift+Tab 转换为 Key_Backtab，需同时处理两个键码。
                            if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                                if (event.key === Qt.Key_Backtab
                                    || (event.modifiers & Qt.ShiftModifier)) {
                                    advancedPage.unindentSelection()
                                } else {
                                    advancedPage.insertTabIndent()
                                }
                                event.accepted = true
                                return
                            }
                            // ── Ctrl 组合键 ──
                            if (event.modifiers & Qt.ControlModifier) {
                                if (event.key === Qt.Key_Slash) {
                                    // Ctrl+/ 切换 Lua 注释
                                    advancedPage.toggleComment()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_F) {
                                    advancedPage.openSearch(false)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_H) {
                                    advancedPage.openSearch(true)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Z
                                           && !(event.modifiers & Qt.ShiftModifier)) {
                                    scriptEditor.undo()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Y
                                           || (event.key === Qt.Key_Z
                                               && (event.modifiers & Qt.ShiftModifier))) {
                                    scriptEditor.redo()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_S) {
                                    advancedPage.saveRequested()
                                    event.accepted = true
                                }
                            }
                        }
                        // 将用户编辑实时同步给 ConsolePage，供两个保存入口复用。
                        onTextChanged: {
                            if (text !== advancedPage.scriptText)
                                advancedPage.scriptTextEdited(text)
                            if (advancedPage.searchVisible)
                                advancedPage.refreshSearchMatches()
                            Qt.callLater(() => PreferencesStore.setTextDocumentLineHeight(
                                             textDocument,
                                             advancedPage.editorLineHeight))
                        }
                        Component.onCompleted: {
                            PreferencesStore.setTextDocumentLineHeight(
                                textDocument, advancedPage.editorLineHeight)
                            // Lua 高亮器会跟随文档内容变化自动重新着色。
                            PreferencesStore.enableLuaSyntaxHighlighting(
                                textDocument,
                                AppConfig.luaSyntaxColors(advancedPage.rootWindow.darkMode))
                        }

                        Connections {
                            target: advancedPage.rootWindow
                            function onDarkModeChanged() {
                                // 系统主题变化时立即切换高亮配色。
                                PreferencesStore.enableLuaSyntaxHighlighting(
                                    scriptEditor.textDocument,
                                    AppConfig.luaSyntaxColors(advancedPage.rootWindow.darkMode))
                            }
                        }
                        // 输入超出可视区域时，自动滚动到当前光标。
                        onCursorRectangleChanged: {
                            const cursorBottom = y + cursorRectangle.y + cursorRectangle.height
                            if (cursorBottom - scriptFlick.contentY > scriptFlick.height)
                                scriptFlick.contentY = cursorBottom - scriptFlick.height
                            else if (y + cursorRectangle.y < scriptFlick.contentY)
                                scriptFlick.contentY = Math.max(0, y + cursorRectangle.y)
                        }
                        // 右键弹出编辑菜单
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton
                            cursorShape: Qt.IBeamCursor
                            onClicked: function(mouse) {
                                var globalPos = mapToItem(null, mouse.x, mouse.y)
                                editorContextMenu.x = globalPos.x
                                editorContextMenu.y = globalPos.y
                                editorContextMenu.open()
                            }
                        }
                    }
                }

                MultiEffect {
                    anchors.fill: searchPanel
                    z: 9
                    visible: searchPanel.visible
                    source: searchPanel
                    // 查找面板使用轻量阴影，在编辑区背景上保持清晰层级。
                    shadowEnabled: true
                    shadowColor: AppConfig.shadowColor
                    shadowOpacity: advancedPage.rootWindow.darkMode ? 0.42 : 0.18
                    shadowBlur: 0.65
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 2
                    autoPaddingEnabled: true
                }

                Rectangle {
                    id: searchPanel

                    visible: advancedPage.searchVisible
                    z: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 15
                    anchors.top: editorToolbar.bottom
                    anchors.topMargin: 8
                    width: 300
                    // 展开状态增加 2px，为上下两个输入框保留明确间隙。
                    height: advancedPage.replaceVisible ? 50 : 28
                    radius: 5
                    clip: true
                    color: advancedPage.rootWindow.darkMode
                           ? AppConfig.editorToolPanelDark
                           : AppConfig.editorToolPanelLight
                    border.color: searchPanel.subtleBorderColor
                    border.width: 1
                    // 查找面板和输入框只保留轻微轮廓，不抢占正文视觉层级。
                    readonly property color subtleBorderColor:
                        advancedPage.rootWindow.darkMode
                        ? AppConfig.editorBorderDark
                        : AppConfig.editorBorderLight
                    readonly property real rightControlWidth: 132

                    Behavior on height {
                        NumberAnimation { duration: AppConfig.animDurationFast }
                    }

                    Item {
                        id: searchModeButton

                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        // 切换按钮始终相对整个查找面板垂直居中。
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        // 替换模式下按钮高度覆盖上下两行，与展开后的内容区域匹配。
                        height: advancedPage.replaceVisible ? 42 : 20

                        Behavior on height {
                            NumberAnimation { duration: AppConfig.animDurationFast }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 3
                            color: searchModeArea.containsMouse
                                   ? advancedPage.rootWindow.menuHoverColor
                                   : searchPanel.color

                            Behavior on color {
                                ColorAnimation { duration: AppConfig.animDurationFast }
                            }
                        }

                        Image {
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            source: advancedPage.iconPath("riLine-arrow-up-down-line.svg")
                            fillMode: Image.PreserveAspectFit
                        }

                        MouseArea {
                            id: searchModeArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // 最左侧按钮在查找和查找替换两种面板状态之间切换。
                                advancedPage.replaceVisible = !advancedPage.replaceVisible
                            }
                        }

                    }

                    Basic.TextField {
                        id: searchInput

                        anchors.left: parent.left
                        anchors.leftMargin: 28
                        // 两个输入框共用相同右侧控制区，因此宽度始终一致。
                        anchors.right: parent.right
                        anchors.rightMargin: searchPanel.rightControlWidth
                        anchors.top: parent.top
                        anchors.topMargin: 4
                        height: 20
                        placeholderText: qsTr("查找")
                        color: advancedPage.rootWindow.textColor
                        placeholderTextColor: advancedPage.rootWindow.mutedTextColor
                        font.pixelSize: 11
                        selectByMouse: true
                        background: Rectangle {
                            radius: 4
                            color: advancedPage.rootWindow.darkMode
                                   ? AppConfig.editorInputDark
                                   : AppConfig.editorInputLight
                            border.color: searchInput.activeFocus
                                          ? AppConfig.accentColor
                                          : searchPanel.subtleBorderColor
                        }
                        onTextChanged: {
                            // 查询变化后从第一项重新计算，保证计数与当前内容一致。
                            advancedPage.currentSearchIndex = -1
                            advancedPage.refreshSearchMatches()
                            // 输入过程中自动高亮光标下方最近匹配，但不抢走输入焦点。
                            Qt.callLater(() => advancedPage.selectNearestMatch(
                                             advancedPage.searchAnchorPosition, false))
                        }
                        Keys.onReturnPressed: function(event) {
                            // Enter 查找下一项，Shift+Enter 查找上一项。
                            advancedPage.findNext(
                                event.modifiers & Qt.ShiftModifier ? -1 : 1)
                        }
                        Keys.onEscapePressed: advancedPage.searchVisible = false
                    }

                    Label {
                        id: matchStatus

                        anchors.left: searchInput.right
                        anchors.leftMargin: 4
                        anchors.verticalCenter: searchInput.verticalCenter
                        width: 60
                        text: advancedPage.searchMatches.length > 0
                              ? qsTr("第%1项，共%2项")
                                  .arg(advancedPage.currentSearchIndex + 1)
                                  .arg(advancedPage.searchMatches.length)
                              : qsTr("无结果")
                        color: advancedPage.rootWindow.textColor
                        font.pixelSize: 10
                        font.bold: false
                        // 状态文字紧贴输入框左对齐，避免“无结果”漂在右侧。
                        horizontalAlignment: Text.AlignLeft
                    }

                    Repeater {
                        model: [
                            {
                                idName: "previous",
                                icon: "riLine-arrow-up-s-line.svg",
                                direction: -1
                            },
                            {
                                idName: "next",
                                icon: "riLine-arrow-down-s-line.svg",
                                direction: 1
                            }
                        ]

                        Item {
                            id: searchDirectionButton

                            x: modelData.idName === "previous"
                               ? searchPanel.width - 64 : searchPanel.width - 44
                            y: 4
                            width: 20
                            height: 20

                            Rectangle {
                                anchors.fill: parent
                                radius: 3
                                color: searchDirectionArea.containsMouse
                                       ? advancedPage.rootWindow.menuHoverColor
                                       : searchPanel.color

                                Behavior on color {
                                    ColorAnimation { duration: AppConfig.animDurationFast }
                                }
                            }

                            Image {
                                anchors.centerIn: parent
                                width: 14
                                height: 14
                                source: advancedPage.iconPath(modelData.icon)
                            }

                            MouseArea {
                                id: searchDirectionArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: advancedPage.findNext(modelData.direction)
                            }
                        }
                    }

                    // 为状态文字锚点提供稳定目标，实际上一项按钮由上方 Repeater 绘制。
                    Item {
                        id: previousMatchButton
                        x: searchPanel.width - 64
                        y: 4
                        width: 20
                        height: 20
                    }

                    Item {
                        id: closeSearchButton

                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.top: parent.top
                        anchors.topMargin: 4
                        width: 20
                        height: 20

                        Rectangle {
                            anchors.fill: parent
                            radius: 3
                            color: closeSearchArea.containsMouse
                                   ? advancedPage.rootWindow.menuHoverColor
                                   : searchPanel.color

                            Behavior on color {
                                ColorAnimation { duration: AppConfig.animDurationFast }
                            }
                        }

                        Image {
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            // 最右侧按钮固定使用关闭图标，不再承担状态切换。
                            source: advancedPage.iconPath("riLine-close-line 1.svg")
                        }

                        MouseArea {
                            id: closeSearchArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // 关闭面板时恢复为默认查找状态。
                                advancedPage.searchVisible = false
                                advancedPage.replaceVisible = false
                            }
                        }
                    }

                    Basic.TextField {
                        id: replaceInput

                        // 替换行在面板展开时向下滑入并淡入，收起时执行反向动画。
                        enabled: advancedPage.replaceVisible
                        opacity: advancedPage.replaceVisible ? 1 : 0
                        anchors.left: searchInput.left
                        // 与查找输入框使用完全相同的左右边界。
                        anchors.right: parent.right
                        anchors.rightMargin: searchPanel.rightControlWidth
                        anchors.top: searchInput.bottom
                        anchors.topMargin: advancedPage.replaceVisible ? 2 : -4
                        height: 20
                        placeholderText: qsTr("替换")
                        color: advancedPage.rootWindow.textColor
                        placeholderTextColor: advancedPage.rootWindow.mutedTextColor
                        font.pixelSize: 11
                        selectByMouse: true
                        background: Rectangle {
                            radius: 4
                            color: advancedPage.rootWindow.darkMode
                                   ? AppConfig.editorInputDark
                                   : AppConfig.editorInputLight
                            border.color: replaceInput.activeFocus
                                          ? AppConfig.accentColor
                                          : searchPanel.subtleBorderColor
                        }
                        Keys.onReturnPressed: advancedPage.replaceCurrentMatch()
                        Keys.onEscapePressed: advancedPage.searchVisible = false

                        Behavior on opacity {
                            NumberAnimation { duration: AppConfig.animDurationFast }
                        }
                        Behavior on anchors.topMargin {
                            NumberAnimation { duration: AppConfig.animDurationFast }
                        }
                    }

                    Item {
                        id: replaceCurrentButton

                        enabled: advancedPage.replaceVisible
                        opacity: advancedPage.replaceVisible ? 1 : 0
                        // 操作区占据输入框右侧空间：“替换”居中，“全部替换”贴右。
                        anchors.left: replaceInput.right
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: replaceInput.verticalCenter
                        height: 20

                        Repeater {
                            model: [
                                {
                                    icon: "riLine-check-line.svg",
                                    text: qsTr("替换"),
                                    buttonWidth: 48,
                                    replaceAll: false
                                },
                                {
                                    icon: "riLine-check-double-line.svg",
                                    text: qsTr("全部替换"),
                                    buttonWidth: 68,
                                    replaceAll: true
                                }
                            ]

                            Item {
                                // 单项替换在剩余间隙中居中，全部替换固定贴紧操作区右侧。
                                x: modelData.replaceAll
                                   ? replaceCurrentButton.width - width
                                   : (replaceCurrentButton.width - 68 - width) / 2
                                width: modelData.buttonWidth
                                height: 20

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 3
                                    color: replaceActionArea.containsMouse
                                           ? advancedPage.rootWindow.menuHoverColor
                                           : searchPanel.color

                                    Behavior on color {
                                        ColorAnimation { duration: AppConfig.animDurationFast }
                                    }
                                }

                                Row {
                                    id: replaceActionContent

                                    anchors.centerIn: parent
                                    spacing: 2

                                    Image {
                                        anchors.verticalCenter: parent.verticalCenter
                                        // 与查找面板内其他图标统一为 14px。
                                        width: 14
                                        height: 14
                                        source: advancedPage.iconPath(modelData.icon)
                                    }

                                    Label {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.text
                                        color: advancedPage.rootWindow.textColor
                                        // 与上方“无结果/计数”文字保持相同字号。
                                        font.pixelSize: 10
                                        font.bold: false
                                    }
                                }

                                MouseArea {
                                    id: replaceActionArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        // 单次和全部替换分别复用页面级文本替换函数。
                                        if (modelData.replaceAll)
                                            advancedPage.replaceAllMatches()
                                        else
                                            advancedPage.replaceCurrentMatch()
                                    }
                                }
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation { duration: AppConfig.animDurationFast }
                        }
                    }
                }

                Rectangle {
                    // 父 Rectangle 的 border 会被贴边子元素覆盖，单独用最上层透明框绘制外轮廓。
                    anchors.fill: parent
                    z: 20
                    color: AppConfig.transparentColor
                    border.color: advancedPage.rootWindow.mutedTextColor
                    border.width: 1
                    visible: editorFrame.visible
                }
            }

            // ── 编辑器右键菜单 ──────────────────────────────
            Popup {
                id: editorContextMenu

                parent: Overlay.overlay
                padding: 4
                width: 180
                closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                focus: true
                // 菜单随 Overlay 坐标定位，在 MouseArea 中设置 x/y 后 open。
                x: 0
                y: 0
                // 防止菜单超出窗口右/下边界
                onOpened: {
                    if (Overlay.overlay) {
                        if (x + width > Overlay.overlay.width)
                            x = Overlay.overlay.width - width - 8
                        if (y + height > Overlay.overlay.height)
                            y = Overlay.overlay.height - height - 8
                    }
                }

                readonly property bool hasSelection:
                    scriptEditor.selectionStart !== scriptEditor.selectionEnd
                readonly property color menuSurfaceColor: advancedPage.rootWindow.darkMode
                                                         ? AppConfig.editorToolPanelDark
                                                         : AppConfig.editorToolPanelLight

                function execute(action) {
                    close()
                    switch (action) {
                    case "cut":
                        scriptEditor.cut()
                        break
                    case "copy":
                        scriptEditor.copy()
                        break
                    case "paste":
                        scriptEditor.paste()
                        break
                    case "comment":
                        advancedPage.toggleComment()
                        break
                    case "find":
                        advancedPage.openSearch(false)
                        break
                    case "replace":
                        advancedPage.openSearch(true)
                        break
                    }
                }

                background: Rectangle {
                    radius: 6
                    color: editorContextMenu.menuSurfaceColor
                    border.color: advancedPage.rootWindow.darkMode
                                  ? AppConfig.editorBorderDark
                                  : AppConfig.editorBorderLight
                    border.width: 1

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: AppConfig.shadowColor
                        shadowOpacity: advancedPage.rootWindow.darkMode ? 0.45 : 0.22
                        shadowBlur: 0.7
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 3
                        autoPaddingEnabled: true
                    }
                }

                contentItem: Column {
                    Repeater {
                        model: [
                            { label: qsTr("剪切"), shortcut: "Ctrl+X", action: "cut", needsSel: true },
                            { label: qsTr("复制"), shortcut: "Ctrl+C", action: "copy", needsSel: true },
                            { label: qsTr("粘贴"), shortcut: "Ctrl+V", action: "paste", needsSel: false },
                            { type: "sep" },
                            { label: qsTr("注释"), shortcut: "Ctrl+/", action: "comment", needsSel: false },
                            { type: "sep" },
                            { label: qsTr("查找"), shortcut: "Ctrl+F", action: "find", needsSel: false },
                            { label: qsTr("替换"), shortcut: "Ctrl+H", action: "replace", needsSel: false }
                        ]

                        delegate: Rectangle {
                            readonly property bool isSep: modelData.type === "sep"
                            readonly property bool itemEnabled:
                                !isSep && (!modelData.needsSel
                                           || editorContextMenu.hasSelection)

                            width: editorContextMenu.width - 8
                            height: isSep ? 1 : 28
                            radius: isSep ? 0 : 4
                            anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined

                            color: {
                                if (isSep)
                                    return advancedPage.rootWindow.darkMode
                                           ? AppConfig.editorBorderDark
                                           : AppConfig.editorBorderLight
                                if (!itemEnabled)
                                    return editorContextMenu.menuSurfaceColor
                                return itemArea.containsMouse
                                       ? advancedPage.rootWindow.menuHoverColor
                                       : editorContextMenu.menuSurfaceColor
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: AppConfig.animDurationFast
                                }
                            }

                            Label {
                                anchors {
                                    left: parent.left; leftMargin: 12
                                    verticalCenter: parent.verticalCenter
                                }
                                visible: !isSep
                                text: modelData.label || ""
                                color: parent.itemEnabled
                                       ? advancedPage.rootWindow.textColor
                                       : advancedPage.rootWindow.mutedTextColor
                                font.pixelSize: 13
                            }

                            Label {
                                anchors {
                                    right: parent.right; rightMargin: 12
                                    verticalCenter: parent.verticalCenter
                                }
                                visible: !isSep
                                text: modelData.shortcut || ""
                                color: advancedPage.rootWindow.mutedTextColor
                                font.pixelSize: 12
                            }

                            MouseArea {
                                id: itemArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: parent.itemEnabled
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (modelData.action)
                                        editorContextMenu.execute(modelData.action)
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: keyPage

            Column {
                anchors.left: parent.left
                anchors.top: parent.top
                spacing: 18

                Repeater {
                    model: [
                        { title: qsTr("键位"), kind: "key", items: advancedPage.scriptKeys },
                        { title: qsTr("触发器"), kind: "toggle", items: advancedPage.scriptToggles }
                    ]

                    Column {
                        id: bindingGroup

                        readonly property string bindingKind: modelData.kind
                        readonly property var slotItems: modelData.items
                        spacing: 6

                        Label {
                            text: modelData.title
                            color: advancedPage.rootWindow.textColor
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Row {
                            spacing: 12

                            Repeater {
                                model: bindingGroup.slotItems

                                Column {
                                    spacing: 5

                                    Rectangle {
                                        readonly property bool waitingForBinding:
                                            advancedPage.pendingBindingKind === bindingGroup.bindingKind
                                            && advancedPage.pendingKeySlot === modelData
                                        width: Math.max(34, bindingText.implicitWidth + 12)
                                        height: 34
                                        radius: 3
                                        color: waitingForBinding || keySlotArea.pressed
                                               ? AppConfig.accentColor
                                               : AppConfig.transparentColor
                                        border.color: waitingForBinding
                                                      ? AppConfig.accentColor
                                                      : (keySlotArea.containsMouse
                                                         ? AppConfig.accentHoverColor
                                                         : advancedPage.rootWindow.mutedTextColor)
                                        border.width: 1

                                        Label {
                                            id: bindingText

                                            anchors.centerIn: parent
                                            text: (bindingGroup.bindingKind === "toggle"
                                                   ? advancedPage.toggleBindings[modelData]
                                                   : advancedPage.keyBindings[modelData]) || "+"
                                            color: parent.waitingForBinding || keySlotArea.pressed
                                                   ? AppConfig.whiteTextColor
                                                   : (keySlotArea.containsMouse
                                                      ? AppConfig.accentHoverColor
                                                      : advancedPage.rootWindow.textColor)
                                            font.pixelSize: 16
                                        }

                                        MouseArea {
                                            id: keySlotArea

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                advancedPage.pendingBindingKind = bindingGroup.bindingKind
                                                advancedPage.pendingKeySlot = modelData
                                            }
                                        }
                                    }

                                    Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData
                                        color: advancedPage.rootWindow.textColor
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 键盘和鼠标保持固定组合，不随窗口宽度分离。
            KeyboardPreview {
                id: advancedKeyboard

                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: 570
                height: 200
                rootWindow: advancedPage.rootWindow
                onKeyClicked: keyName => advancedPage.handlePreviewKey(keyName)
            }

            MousePreview {
                anchors.left: advancedKeyboard.right
                anchors.bottom: parent.bottom
                // 与基础页保持相同的键盘、鼠标水平间隔。
                anchors.leftMargin: 40
                width: 150
                height: 200
                rootWindow: advancedPage.rootWindow
                onKeyClicked: keyName => advancedPage.handlePreviewKey(keyName)
            }
        }

        Item {
            id: colorPage

            // 截图与取点分别按 Lua image、pixel 表动态生成槽位。
            Column {
                anchors.left: parent.left
                anchors.top: parent.top
                spacing: 24

                Repeater {
                    model: [
                        { title: qsTr("截图"), kind: "image", items: advancedPage.scriptImages },
                        { title: qsTr("取点"), kind: "pixel", items: advancedPage.scriptPixels }
                    ]

                    Column {
                        id: colorGroup

                        readonly property var slotItems: modelData.items
                        readonly property string captureKind: modelData.kind

                        spacing: 6

                        Label {
                            text: modelData.title
                            color: advancedPage.rootWindow.textColor
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Row {
                            spacing: 12

                            Repeater {
                                model: colorGroup.slotItems

                                Column {
                                    spacing: 3

                                    Rectangle {
                                        readonly property string storedImage:
                                            colorGroup.captureKind === "image"
                                            ? advancedPage.captureImageSource(modelData) : ""
                                        readonly property string storedColor:
                                            colorGroup.captureKind === "pixel"
                                            ? advancedPage.capturePointColor(modelData) : ""
                                        readonly property bool hasStoredContent:
                                            storedImage.length > 0 || storedColor.length > 0

                                        width: 34
                                        height: 34
                                        radius: 3
                                        clip: true
                                        // 取点槽位直接以采集到的十六进制颜色填充。
                                        color: storedColor.length > 0
                                               ? storedColor
                                               : (colorSlotArea.pressed
                                                  ? AppConfig.accentColor
                                                  : AppConfig.transparentColor)
                                        border.color: colorSlotArea.containsMouse
                                                      ? AppConfig.accentHoverColor
                                                      : advancedPage.rootWindow.mutedTextColor
                                        border.width: 1

                                        Image {
                                            anchors.fill: parent
                                            anchors.margins: 1
                                            visible: parent.storedImage.length > 0
                                            source: parent.storedImage
                                            fillMode: Image.PreserveAspectCrop
                                            cache: false
                                            smooth: false
                                        }

                                        Label {
                                            anchors.centerIn: parent
                                            visible: !parent.hasStoredContent
                                            text: "+"
                                            color: colorSlotArea.pressed
                                                   ? AppConfig.whiteTextColor
                                                   : (colorSlotArea.containsMouse
                                                      ? AppConfig.accentHoverColor
                                                      : advancedPage.rootWindow.textColor)
                                            font.pixelSize: 18
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            // 已有预览时仍保留轻微按下反馈，不遮住截图或取点颜色。
                                            color: colorSlotArea.pressed
                                                   ? AppConfig.screenCaptureSelectionColor
                                                   : AppConfig.transparentColor
                                        }

                                        MouseArea {
                                            id: colorSlotArea

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                // 截图槽位进入区域框选，取点槽位进入单点颜色采集。
                                                advancedPage.beginScreenCapture(
                                                    colorGroup.captureKind, modelData)
                                            }
                                        }
                                    }

                                    Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        // 槽位标题使用脚本表中声明的截图或取点名称。
                                        text: modelData
                                        color: advancedPage.rootWindow.textColor
                                        // 取色页按钮名称统一使用 12px 字号。
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

}
