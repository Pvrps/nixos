import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null

    readonly property var  geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true

    property real contentPreferredWidth:  640 * Style.uiScaleRatio
    property real contentPreferredHeight: 560 * Style.uiScaleRatio

    anchors.fill: parent

    property bool   rpcActive:     false
    property string activeProfile: ""
    property bool   busy:          false
    property string errorMsg:      ""

    ListModel { id: profilesModel }

    property string view: "list"

    property string cf_name:          ""
    property string cf_appId:         ""
    property string cf_activityName:  ""
    property string cf_details:       ""
    property string cf_state:         ""
    property string cf_streamUrl:     ""
    property string cf_largeImage:    ""
    property string cf_largeText:     ""
    property string cf_smallImage:    ""
    property string cf_smallText:     ""

    property string editingProfile:   ""
    property string confirmDeleteName: ""

    Component.onCompleted: refresh()

    function refresh() {
        root.errorMsg = ""
        // Toggle running to force restart on static Process objects
        activeReadProc.running = false
        statusProc.running = false
        scanProc.running = false
        Qt.callLater(function() {
            activeReadProc.running = true
            statusProc.running = true
            scanProc.running = true
        })
    }

    function resetCreateForm() {
        cf_name         = ""
        cf_appId        = ""
        cf_activityName = ""
        cf_details      = ""
        cf_state        = ""
        cf_streamUrl    = ""
        cf_largeImage   = ""
        cf_largeText    = ""
        cf_smallImage   = ""
        cf_smallText    = ""
        editingProfile  = ""
        root.errorMsg   = ""
    }

    // ── Read active profile ────────────────────────────────────────────
    Process {
        id: activeReadProc
        command: ["bash", "-c", "cat \"$HOME/.local/share/discord-rpc/current\" 2>/dev/null; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.activeProfile = String(this.text || "").trim()
                activeReadProc.running = false
            }
        }
    }

    // ── systemctl is-active check ──────────────────────────────────────
    Process {
        id: statusProc
        command: ["systemctl", "--user", "is-active", "--quiet", "discord-rpc.service"]
        onExited: (code) => {
            root.rpcActive = (code === 0)
            running = false
        }
    }

    // ── Scan profiles ───────────────────────────────────────────────
    Process {
        id: scanProc
        command: ["bash", "-c",
            "for f in \"$HOME/.config/discord-rpc/profiles\"/*.json; do " +
            "[ -f \"$f\" ] && basename \"$f\" .json; done; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                var text = String(this.text || "").trim()
                profilesModel.clear()
                if (text !== "") {
                    var names = text.split("\n").filter(function(l) { return l !== "" })
                    for (var i = 0; i < names.length; i++) {
                        var name = names[i].trim()
                        profilesModel.append({
                            profileName:  name,
                            activityName: name,
                            iconUrl:      ""
                        })
                        root.readProfileIcon(name)
                    }
                    Logger.i("DiscordRPC", "Profiles found:", profilesModel.count)
                } else {
                    Logger.i("DiscordRPC", "No profiles found")
                }
                scanProc.running = false
            }
        }
    }

    function readProfileIcon(name) {
        if (!name) return
        var rp = Qt.createQmlObject(`
            import QtQuick; import Quickshell.Io
            Process {
                command: ["drpc", "image", "--profile", "` + name + `"]
                stdout: StdioCollector {}
                running: true
            }`, root, "IconReader")
        rp.exited.connect(function() {
            var text = String(rp.stdout.text || "").trim()
            if (text !== "") {
                for (var i = 0; i < profilesModel.count; i++) {
                    if (profilesModel.get(i).profileName === name) {
                        profilesModel.setProperty(i, "iconUrl", text)
                        break
                    }
                }
            }
            rp.destroy()
        })
    }

    // ── Activate profile — fresh process per call ──────────────────────
    function activateProfile(name) {
        if (root.busy || !name) return
        root.busy = true
        root.errorMsg = ""

        var ep = Qt.createQmlObject(`
            import QtQuick; import Quickshell.Io
            Process {
                command: ["bash", "-c",
                    "drpc enable --profile \\"$1\\" 2>/dev/null; true", "--", "` + name + `"]
                running: true
            }`, root, "EnableProc")
        ep.exited.connect(function(code) {
            root.busy = false
            if (code === 0) {
                root.rpcActive = true
                if (pluginApi?.barWidget) {
                    pluginApi.barWidget.rpcActive = true
                    pluginApi.barWidget.activeProfile = name
                }
                ToastService.showNotice("Discord RPC enabled: " + name)
                root.refresh()
            } else {
                var msg = "Failed to enable profile '" + name + "'."
                root.errorMsg = msg
                ToastService.showError(msg)
            }
            ep.destroy()
        })
    }

    // ── Disable RPC ────────────────────────────────────────────────────
    Process {
        id: disableProc
        command: ["bash", "-c", "drpc disable 2>/dev/null"]
        onExited: (code) => {
            root.busy = false
            running = false
            if (code === 0) {
                root.rpcActive = false
                if (pluginApi?.barWidget) {
                    pluginApi.barWidget.rpcActive = false
                    pluginApi.barWidget.activeProfile = ""
                }
                ToastService.showNotice("Discord RPC disabled.")
                root.refresh()
            } else {
                root.errorMsg = "Failed to disable Discord RPC."
                ToastService.showError(root.errorMsg)
            }
        }
    }

    function disableRpc() {
        if (root.busy) return
        root.busy = true
        root.errorMsg = ""
        disableProc.running = false
        Qt.callLater(function() { disableProc.running = true })
    }

    // ── Delete profile ──────────────────────────────────────────────────
    Process {
        id: deleteProc
        command: [""]
        onExited: (code) => {
            running = false
            root.busy = false
            root.confirmDeleteName = ""
            if (code === 0) {
                ToastService.showNotice("Profile deleted.")
                root.refresh()
            } else {
                root.errorMsg = "Failed to delete profile."
                ToastService.showError(root.errorMsg)
            }
        }
    }

    function deleteProfile(name) {
        root.confirmDeleteName = name
    }

    function cancelDelete() {
        root.confirmDeleteName = ""
    }

    function executeDelete() {
        var name = root.confirmDeleteName
        if (!name) return
        root.busy = true
        root.errorMsg = ""
        deleteProc.command = ["bash", "-c",
            "rm -f \"$HOME/.config/discord-rpc/profiles/" + name + ".json\"; " +
            "rm -f \"$HOME/.local/share/discord-rpc/current\""]
        deleteProc.running = false
        Qt.callLater(function() { deleteProc.running = true })
    }

    // ── Edit profile ────────────────────────────────────────────────────
    function editProfile(name) {
        if (root.busy || !name) return
        root.busy = true
        root.errorMsg = ""

        var rp = Qt.createQmlObject(`
            import QtQuick; import Quickshell.Io
            Process {
                command: ["drpc", "show", "--profile", "` + name + `"]
                stdout: StdioCollector {}
                running: true
            }`, root, "ReadProfileProc")
        rp.exited.connect(function(code) {
            if (code === 0) {
                var text = String(rp.stdout.text || "").trim()
                try {
                    var p = JSON.parse(text)
                    var assets = p.assets || {}
                    root.cf_name = name
                    root.cf_appId = String(p.application_id || "")
                    root.cf_activityName = p.name || ""
                    root.cf_details = p.details || ""
                    root.cf_state = p.state || ""
                    root.cf_streamUrl = p.url || ""
                    root.cf_largeImage = assets.large_image || ""
                    root.cf_largeText = assets.large_text || ""
                    root.cf_smallImage = assets.small_image || ""
                    root.cf_smallText = assets.small_text || ""
                    root.editingProfile = name
                    root.view = "edit"
                } catch (e) {
                    root.errorMsg = "Failed to parse profile: " + e
                    ToastService.showError(root.errorMsg)
                }
            } else {
                root.errorMsg = "Failed to read profile."
                ToastService.showError(root.errorMsg)
            }
            root.busy = false
            rp.destroy()
        })
    }

    // ── Create / Update profile ─────────────────────────────────────
    Process {
        id: updateProc
        command: [""]
        onExited: (code) => {
            running = false
            root.busy = false
            if (code === 0) {
                ToastService.showNotice(root.editingProfile !== "" ? "Profile updated." : "Profile created.")
                root.view = "list"
                root.resetCreateForm()
                root.refresh()
            } else {
                root.errorMsg = "Failed to save profile."
                ToastService.showError(root.errorMsg)
            }
        }
    }

    function submitCreate() {
        root.errorMsg = ""
        if (cf_name.trim() === "") { root.errorMsg = "Profile name is required."; return }
        if (cf_appId.trim() === "") { root.errorMsg = "Application ID is required."; return }
        if (cf_activityName.trim() === "") { root.errorMsg = "Activity name is required."; return }

        var isUpdate = root.editingProfile !== ""
        root.busy = true

        var payload = {
            name:            isUpdate ? root.editingProfile : cf_name.trim(),
            application_id:  cf_appId.trim(),
            activity_name:   cf_activityName.trim(),
            details:         cf_details.trim(),
            state:           cf_state.trim(),
            url:             cf_streamUrl.trim(),
            large_image:     cf_largeImage.trim(),
            large_image_text: cf_largeText.trim(),
            small_image:     cf_smallImage.trim(),
            small_image_text: cf_smallText.trim()
        }

        var json = JSON.stringify(payload)

        if (isUpdate) {
            updateProc.command = ["drpc", "update", "--json", json]
        } else {
            updateProc.command = ["drpc", "create", "--json", json]
        }
        updateProc.running = false
        Qt.callLater(function() { updateProc.running = true })
    }

    // ── UI ─────────────────────────────────────────────────────────────
    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors { fill: parent; margins: Style.marginL }
            spacing: Style.marginL

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                NIcon {
                    icon:  "brand-discord"
                    color: root.rpcActive ? Color.mPrimary : Color.mOnSurfaceVariant
                    applyUiScale: true
                }

                NText {
                    text:       "Discord RPC"
                    pointSize:  Style.fontSizeL
                    font.weight: Font.Bold
                    color:      Color.mOnSurface
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitWidth:  statusRow.implicitWidth + Style.marginS * 2
                    implicitHeight: statusRow.implicitHeight + Style.marginXS * 2
                    radius: Style.radiusS
                    color: root.rpcActive
                        ? Qt.rgba(87/255, 242/255, 135/255, 0.15)
                        : Qt.rgba(Color.mOutline.r, Color.mOutline.g, Color.mOutline.b, 0.15)

                    RowLayout {
                        id: statusRow
                        anchors.centerIn: parent
                        spacing: Style.marginXS

                        Rectangle {
                            width:  8; height: 8; radius: 4
                            color:  root.rpcActive ? "#57f287" : Color.mOutline
                        }

                        NText {
                            text:      root.rpcActive ? "active" : "inactive"
                            color:     root.rpcActive ? "#57f287" : Color.mOnSurfaceVariant
                            pointSize: Style.fontSizeS
                        }
                    }
                }

                NIconButton {
                    icon: "refresh"
                    enabled: !root.busy
                    onClicked: root.refresh()
                }

                NIconButton {
                    icon: "x"
                    onClicked: pluginApi?.closePanel(pluginApi.panelOpenScreen)
                }
            }

            // Error
            Rectangle {
                Layout.fillWidth: true
                visible: root.errorMsg !== ""
                implicitHeight: errText.implicitHeight + Style.marginS * 2
                color:  Qt.rgba(Color.mError.r, Color.mError.g, Color.mError.b, 0.1)
                radius: Style.radiusM

                NText {
                    id: errText
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left; right: parent.right
                        margins: Style.marginM
                    }
                    text: root.errorMsg
                    color: Color.mError
                    pointSize: Style.fontSizeS
                    wrapMode: Text.WordWrap
                }
            }

            // View switcher
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                NText {
                    text:       root.view === "list" ? "Profiles"
                                : (root.view === "edit" ? "Edit Profile" : "New Profile")
                    pointSize:  Style.fontSizeM
                    font.weight: Font.DemiBold
                    color:      Color.mOnSurface
                    Layout.fillWidth: true
                }

                NButton {
                    visible: root.view === "list"
                    text:    "New Profile"
                    enabled: !root.busy
                    onClicked: { root.resetCreateForm(); root.view = "create" }
                }

                NButton {
                    visible: root.view !== "list"
                    text:    "Cancel"
                    enabled: !root.busy
                    onClicked: { root.resetCreateForm(); root.view = "list" }
                }
            }

            // Profile list
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.view === "list"
                color:   "transparent"

                ColumnLayout {
                    anchors.fill: parent
                    visible: profilesModel.count === 0
                    spacing: Style.marginM

                    Item { Layout.fillHeight: true }

                    NIcon {
                        Layout.alignment: Qt.AlignHCenter
                        icon:  "mood-empty"
                        color: Color.mOnSurfaceVariant
                        applyUiScale: true
                    }

                    NText {
                        Layout.alignment: Qt.AlignHCenter
                        text:      "No profiles yet"
                        color:     Color.mOnSurfaceVariant
                        pointSize: Style.fontSizeM
                    }

                    NText {
                        Layout.alignment: Qt.AlignHCenter
                        text:      "Create one with the button above."
                        color:     Color.mOnSurfaceVariant
                        pointSize: Style.fontSizeS
                    }

                    Item { Layout.fillHeight: true }
                }

                NScrollView {
                    id: scroll
                    anchors.fill: parent
                    visible: profilesModel.count > 0
                    horizontalPolicy: ScrollBar.AlwaysOff
                    verticalPolicy: ScrollBar.AsNeeded

                    ColumnLayout {
                        width: scroll.availableWidth
                        spacing: Style.marginS

                        Item { Layout.preferredHeight: Style.marginS }

                        Repeater {
                            model: profilesModel

                            delegate: Item {
                                id: cardItem
                                required property string profileName
                                required property string activityName
                                required property string iconUrl
                                required property int    index

                                readonly property bool isActive:
                                    root.rpcActive && profileName === root.activeProfile

                                readonly property bool isConfirmingDelete:
                                    root.confirmDeleteName === profileName

                                Layout.fillWidth: true
                                Layout.preferredHeight: 64

                                NBox {
                                    anchors.fill: parent
                                    color: isActive
                                        ? Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.08)
                                        : Color.mSurface

                                    // Active left bar
                                    Rectangle {
                                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                                        width: isActive ? 3 : 0
                                        color: Color.mPrimary
                                        radius: 1.5

                                        Behavior on width { NumberAnimation { duration: 150 } }
                                    }

                                    // Delete confirmation row
                                    RowLayout {
                                        anchors {
                                            verticalCenter: parent.verticalCenter
                                            left: parent.left; right: parent.right
                                            margins: Style.marginM
                                        }
                                        visible: isConfirmingDelete
                                        spacing: Style.marginM

                                        NIcon {
                                            icon:  "trash"
                                            color: Color.mError
                                            applyUiScale: true
                                        }

                                        NText {
                                            text: "Delete \"" + cardItem.profileName + "\"?"
                                            color: Color.mOnSurface
                                            font.weight: Font.Medium
                                            pointSize: Style.fontSizeS
                                            Layout.fillWidth: true
                                        }

                                        NButton {
                                            text: "Cancel"
                                            onClicked: root.cancelDelete()
                                        }

                                        NButton {
                                            text: "Delete"
                                            outlined: true
                                            onClicked: root.executeDelete()
                                        }
                                    }

                                    RowLayout {
                                        anchors {
                                            verticalCenter: parent.verticalCenter
                                            left: parent.left; right: parent.right
                                            margins: Style.marginM
                                        }
                                        visible: !isConfirmingDelete
                                        spacing: Style.marginM

                                        NImageRounded {
                                            Layout.preferredWidth:  40
                                            Layout.preferredHeight: 40
                                            radius: 8
                                            imagePath: cardItem.iconUrl
                                            fallbackIcon: "brand-discord"
                                            fallbackIconSize: Style.fontSizeL
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.minimumWidth: 0
                                            spacing: 2

                                            NText {
                                                Layout.fillWidth: true
                                                Layout.minimumWidth: 0
                                                text:        cardItem.profileName
                                                color:       Color.mOnSurface
                                                pointSize:   Style.fontSizeM
                                                font.weight: Font.Medium
                                                elide:       Text.ElideRight
                                            }

                                            NText {
                                                Layout.fillWidth: true
                                                Layout.minimumWidth: 0
                                                text:        isActive ? "active" : (activityName || cardItem.profileName)
                                                color:       isActive ? Color.mPrimary : Color.mOnSurfaceVariant
                                                pointSize:   Style.fontSizeS
                                                elide:       Text.ElideRight
                                            }
                                        }

                                        NIconButton {
                                            icon:    "edit"
                                            enabled: !root.busy && !isActive && !cardItem.isConfirmingDelete
                                            onClicked: root.editProfile(cardItem.profileName)
                                        }

                                        NIconButton {
                                            icon:    "trash"
                                            enabled: !root.busy && !cardItem.isConfirmingDelete
                                            onClicked: root.deleteProfile(cardItem.profileName)
                                        }

                                        NIcon {
                                            visible:  isActive
                                            icon:     "circle-check-filled"
                                            color:    Color.mPrimary
                                            applyUiScale: true
                                        }

                                        NButton {
                                            visible:  isActive
                                            text:     "Disable"
                                            enabled:  !root.busy
                                            outlined: true
                                            onClicked: root.disableRpc()
                                        }

                                        NButton {
                                            visible:  !isActive
                                            text:     "Activate"
                                            enabled:  !root.busy && (!root.rpcActive || root.activeProfile === "")
                                            outlined: true
                                            onClicked: root.activateProfile(cardItem.profileName)
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.preferredHeight: Style.marginS }
                    }
                }
            }

            // Create / Edit form
            NBox {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.view === "create" || root.view === "edit"
                color: Color.mSurface

                ColumnLayout {
                    anchors { fill: parent; margins: Style.marginL }
                    spacing: Style.marginM

                    // Form header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginM

                        NIcon {
                            icon:  root.editingProfile !== "" ? "edit" : "plus"
                            color: Color.mPrimary
                            applyUiScale: true
                        }

                        NText {
                            text:       root.editingProfile !== "" ? "Edit Profile" : "New Profile"
                            pointSize:  Style.fontSizeM
                            font.weight: Font.DemiBold
                            color:      Color.mOnSurface
                            Layout.fillWidth: true
                        }

                        NText {
                            text:       root.editingProfile !== "" ? root.editingProfile : ""
                            color:      Color.mOnSurfaceVariant
                            pointSize:  Style.fontSizeS
                            visible:    root.editingProfile !== ""
                        }
                    }

                    NScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        horizontalPolicy: ScrollBar.AlwaysOff
                        verticalPolicy: ScrollBar.AsNeeded

                        ColumnLayout {
                            width: parent.availableWidth
                            spacing: Style.marginM

                            NText {
                                text:       "Required"
                                color:      Color.mOnSurfaceVariant
                                pointSize:  Style.fontSizeXS
                                font.weight: Font.Medium
                                Layout.topMargin: Style.marginS
                            }

                            NTextInput {
                                Layout.fillWidth: true
                                visible: root.editingProfile === ""
                                label: "Profile name"
                                description: "Unique identifier, e.g. \"gaming\""
                                text: root.cf_name
                                onTextChanged: root.cf_name = text
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                visible: root.editingProfile !== ""
                                spacing: Style.marginS

                                NText {
                                    text:       "Profile"
                                    color:      Color.mOnSurfaceVariant
                                    pointSize:  Style.fontSizeXS
                                    font.weight: Font.Medium
                                }

                                Item { Layout.fillWidth: true }

                                NText {
                                    text:       root.cf_name
                                    color:      Color.mOnSurface
                                    pointSize:  Style.fontSizeM
                                    font.weight: Font.Medium
                                }
                            }

                            NTextInput {
                                Layout.fillWidth: true
                                label: "Discord Application ID"
                                description: "From discord.com/developers/applications"
                                text: root.cf_appId
                                onTextChanged: root.cf_appId = text
                            }

                            NTextInput {
                                Layout.fillWidth: true
                                label: "Activity name"
                                description: "Shown as the game / app title in Discord"
                                text: root.cf_activityName
                                onTextChanged: root.cf_activityName = text
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Color.mOutline
                                opacity: 0.3
                                Layout.topMargin: Style.marginS
                            }

                            NText {
                                text:       "Optional"
                                color:      Color.mOnSurfaceVariant
                                pointSize:  Style.fontSizeXS
                                font.weight: Font.Medium
                                Layout.topMargin: Style.marginS
                            }

                            NTextInput {
                                Layout.fillWidth: true
                                label: "Details"
                                description: "First line under the activity title"
                                text: root.cf_details
                                onTextChanged: root.cf_details = text
                            }

                            NTextInput {
                                Layout.fillWidth: true
                                label: "State"
                                description: "Second line under the activity title"
                                text: root.cf_state
                                onTextChanged: root.cf_state = text
                            }

                            NTextInput {
                                Layout.fillWidth: true
                                label: "Stream URL"
                                description: "Twitch / YouTube — sets activity type to Streaming"
                                text: root.cf_streamUrl
                                onTextChanged: root.cf_streamUrl = text
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Color.mOutline
                                opacity: 0.3
                                Layout.topMargin: Style.marginS
                            }

                            NText {
                                text:       "Images"
                                color:      Color.mOnSurfaceVariant
                                pointSize:  Style.fontSizeXS
                                font.weight: Font.Medium
                                Layout.topMargin: Style.marginS
                            }

                            NTextInput {
                                Layout.fillWidth: true
                                label: "Large Image Key"
                                description: "Image key from your Discord app's rich presence art assets"
                                text: root.cf_largeImage
                                onTextChanged: root.cf_largeImage = text
                            }

                            NTextInput {
                                Layout.fillWidth: true
                                label: "Large Image Hover Text"
                                description: "Tooltip shown when hovering the large image"
                                text: root.cf_largeText
                                onTextChanged: root.cf_largeText = text
                            }

                            NTextInput {
                                Layout.fillWidth: true
                                label: "Small Image Key"
                                description: "Small corner image key"
                                text: root.cf_smallImage
                                onTextChanged: root.cf_smallImage = text
                            }

                            NTextInput {
                                Layout.fillWidth: true
                                label: "Small Image Hover Text"
                                description: "Tooltip shown when hovering the small image"
                                text: root.cf_smallText
                                onTextChanged: root.cf_smallText = text
                            }

                            Item { Layout.preferredHeight: Style.marginS }
                        }
                    }

                    // Bottom buttons
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginM

                        NButton {
                            text:     "Cancel"
                            enabled:  !root.busy
                            onClicked: { root.resetCreateForm(); root.view = "list" }
                        }

                        Item { Layout.fillWidth: true }

                        NButton {
                            text:      root.editingProfile !== "" ? "Update Profile" : "Create Profile"
                            enabled:   !root.busy
                            onClicked: root.submitCreate()
                        }
                    }
                }
            }
        }
    }
}
