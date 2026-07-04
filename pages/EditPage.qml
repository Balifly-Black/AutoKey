import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import "../components/controls"

Item {
    id: editPage

    required property var rootWindow

    property string scriptPath: ""
    property string scriptText: ""
    property string savedScriptText: ""
    readonly property bool scriptDirty: scriptText !== savedScriptText

    function localPathFromUrl(fileUrl) {
        const text = decodeURIComponent(String(fileUrl))
        if (text.indexOf("file:///") === 0)
            return text.substring(8).replace(/\//g, "\\")
        if (text.indexOf("file://") === 0)
            return text.substring(7).replace(/\//g, "\\")
        return text
    }

    function createScript(path) {
        const localPath = String(path || "").trim()
        if (localPath.length === 0)
            return

        if (!PreferencesStore.saveTextFile(localPath, "")) {
            editorMessage.showMessage(qsTr("新建失败"), qsTr("无法创建所选 Lua 文件。"))
            return
        }

        scriptPath = localPath
        scriptText = ""
        savedScriptText = ""
    }

    function loadScript(path) {
        const localPath = String(path || "").trim()
        if (localPath.length === 0)
            return

        scriptPath = localPath
        scriptText = PreferencesStore.loadTextFile(localPath)
        savedScriptText = scriptText
    }

    function saveScript() {
        if (scriptPath.trim().length === 0) {
            editorMessage.showMessage(
                qsTr("未设置文件路径"),
                qsTr("请先新建或加载一个 Lua 文件。"))
            return false
        }

        const syntaxError = PreferencesStore.luaSyntaxError(scriptText)
        if (syntaxError.length > 0) {
            editorMessage.showMessage(
                qsTr("Lua 语法错误"),
                qsTr("请修正后再保存：\n%1").arg(syntaxError))
            return false
        }

        if (!PreferencesStore.saveTextFile(scriptPath.trim(), scriptText)) {
            editorMessage.showMessage(qsTr("保存失败"), qsTr("无法写入当前 Lua 文件。"))
            return false
        }

        savedScriptText = scriptText
        return true
    }

    FileDialog {
        id: newScriptDialog

        title: qsTr("新建 Lua 脚本")
        fileMode: FileDialog.SaveFile
        defaultSuffix: "lua"
        nameFilters: [qsTr("Lua 脚本 (*.lua)")]
        onAccepted: editPage.createScript(editPage.localPathFromUrl(selectedFile))
    }

    FileDialog {
        id: loadScriptDialog

        title: qsTr("加载 Lua 脚本")
        fileMode: FileDialog.OpenFile
        nameFilters: [
            qsTr("Lua 脚本 (*.lua)"),
            qsTr("所有文件 (*.*)")
        ]
        onAccepted: editPage.loadScript(editPage.localPathFromUrl(selectedFile))
    }

    MessageWindow {
        id: editorMessage
        rootWindow: editPage.rootWindow
    }

    Item {
        id: editHeader

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.rightMargin: 20
        height: 42

        Label {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("编辑器")
            color: editPage.rootWindow.textColor
            font.pixelSize: 34
            font.bold: true
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Repeater {
                model: [
                    { text: qsTr("新建"), action: "new", primary: false },
                    { text: qsTr("加载"), action: "load", primary: false },
                    { text: qsTr("保存"), action: "save", primary: true }
                ]

                Rectangle {
                    required property var modelData

                    width: 100
                    height: 34
                    radius: 4
                    color: modelData.primary
                           ? (headerButtonArea.containsMouse
                              ? AppConfig.accentHoverColor
                              : AppConfig.accentColor)
                           : AppConfig.transparentColor
                    border.color: headerButtonArea.containsMouse
                                  ? AppConfig.accentHoverColor
                                  : AppConfig.accentColor
                    border.width: 1

                    Label {
                        anchors.centerIn: parent
                        text: parent.modelData.text
                        color: parent.modelData.primary
                               ? AppConfig.whiteTextColor
                               : (headerButtonArea.containsMouse
                                  ? AppConfig.accentHoverColor
                                  : AppConfig.accentColor)
                        font.pixelSize: 16
                        font.bold: true
                    }

                    MouseArea {
                        id: headerButtonArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (parent.modelData.action === "new") {
                                newScriptDialog.currentFolder = PreferencesStore.scriptDirUrl("advanced")
                                newScriptDialog.open()
                            } else if (parent.modelData.action === "load") {
                                loadScriptDialog.currentFolder = PreferencesStore.scriptDirUrl("advanced")
                                loadScriptDialog.open()
                            } else {
                                editPage.saveScript()
                            }
                        }
                    }
                }
            }
        }
    }

    ConsoleAdvancedPage {
        id: scriptEditor

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: editHeader.bottom
        anchors.bottom: parent.bottom
        anchors.topMargin: 14
        anchors.rightMargin: 20
        anchors.bottomMargin: 10
        rootWindow: editPage.rootWindow
        currentTab: 0
        scriptText: editPage.scriptText
        scriptPath: editPage.scriptPath
        scriptDirty: editPage.scriptDirty
        keyBindings: ({})
        toggleBindings: ({})
        waitingForSwitchKey: false
        onScriptTextEdited: text => editPage.scriptText = text
        onSaveRequested: editPage.saveScript()
    }
}
