import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    // ── Plugin API ────────────────────────────────────────────────────────────
    property var pluginApi: null

    // ── SmartPanel integration ────────────────────────────────────────────────
    readonly property var  geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true

    property real contentPreferredWidth:  640 * Style.uiScaleRatio
    property real contentPreferredHeight: 560 * Style.uiScaleRatio

    anchors.fill: parent

    // ── State ─────────────────────────────────────────────────────────────────
    property bool   rpcActive:     false
    property string activeProfile: ""
    property bool   busy:          false   // command running
    property string errorMsg:      ""

    // Profiles list model — filled by scanProfiles()
    ListModel { id: profilesModel }

    // ── View state: "list" | "create" ─────────────────────────────────────────
    property string view: "list"

    // Create-form fields
    property string cf_name:          ""
    property string cf_appId:         ""
    property string cf_activityName:  ""
    property string cf_details:       ""
    property string cf_state:         ""
    property string cf_streamUrl:     ""

    // ── Refresh on open ───────────────────────────────────────────────────────
    Component.onCompleted: refresh()

    function refresh() {
        root.errorMsg = ""

        // systemctl status
        statusProc.running = true

        // Read active profile — fresh process each time (static Process doesn't re-run)
        var rp = Qt.createQmlObject(`
            import QtQuick; import Quickshell.Io
            Process {
                command: ["bash", "-c", "cat \\"$HOME/.local/share/discord-rpc/current\\" 2>/dev/null; true"]
                stdout: StdioCollector {}
                running: true
            }`, root, "ProfileRead")
        rp.exited.connect(function() {
            root.activeProfile = String(rp.stdout.text || "").trim()
            rp.destroy()
        })

        // Scan profiles directory — fresh process each time
        var sp = Qt.createQmlObject(`
            import QtQuick; import Quickshell.Io
            Process {
                command: ["bash", "-c",
                    "for f in \\"$HOME/.config/discord-rpc/profiles\\"/*.json; do " +
                    "[ -f \\"$f\\" ] && basename \\"$f\\" .json; done 2>/dev/null; true"]
                stdout: StdioCollector {}
                running: true
            }`, root, "ProfileScan")
        sp.exited.connect(function() {
            var text = String(sp.stdout.text || "").trim()
            profilesModel.clear()
            if (text !== "") {
                var names = text.split("\n").filter(function(n) { return n !== "" })
                for (var i = 0; i < names.length; i++)
                    profilesModel.append({ profileName: names[i].trim() })
                Logger.i("DiscordRPC", "Profiles found:", names.length)
            } else {
                Logger.i("DiscordRPC", "No profiles found")
            }
            sp.destroy()
        })
    }

    function resetCreateForm() {
        cf_name         = ""
        cf_appId        = ""
        cf_activityName = ""
        cf_details      = ""
        cf_state        = ""
        cf_streamUrl    = ""
        root.errorMsg   = ""
    }

    // ── Processes ─────────────────────────────────────────────────────────────

    // systemctl --user is-active discord-rpc.service
    Process {
        id: statusProc
        command: ["systemctl", "--user", "is-active", "--quiet", "discord-rpc.service"]
        onExited: (code) => { root.rpcActive = (code === 0) }
    }

    // drpc enable --profile <name>
    Process {
        id: enableProc
        property string targetProfile: ""
        command: ["drpc", "enable", "--profile", targetProfile]
        onExited: (code) => {
            root.busy = false
            if (code === 0) {
                ToastService.showNotice("Discord RPC enabled: " + targetProfile)
                root.refresh()
            } else {
                root.errorMsg = "Failed to enable profile '" + targetProfile + "'."
                ToastService.showError(root.errorMsg)
            }
        }
    }

    // drpc disable
    Process {
        id: disableProc
        command: ["drpc", "disable"]
        onExited: (code) => {
            root.busy = false
            if (code === 0) {
                ToastService.showNotice("Discord RPC disabled.")
                root.refresh()
            } else {
                root.errorMsg = "Failed to disable Discord RPC."
                ToastService.showError(root.errorMsg)
            }
        }
    }

    // drpc create --json '<...>'
    Process {
        id: createProc
        property string jsonArg: ""
        command: ["drpc", "create", "--json", jsonArg]
        onExited: (code) => {
            root.busy = false
            if (code === 0) {
                ToastService.showNotice("Profile created.")
                root.view = "list"
                root.resetCreateForm()
                root.refresh()
            } else {
                root.errorMsg = "Failed to create profile. Check that the name is unique and only uses letters, numbers, _ or -."
                ToastService.showError("Profile creation failed.")
            }
        }
    }

    // ── Helper actions ────────────────────────────────────────────────────────

    function activateProfile(name) {
        if (root.busy) return
        root.busy = true
        root.errorMsg = ""
        enableProc.targetProfile = name
        enableProc.running = true
    }

    function disableRpc() {
        if (root.busy) return
        root.busy = true
        root.errorMsg = ""
        disableProc.running = true
    }

    function submitCreate() {
        root.errorMsg = ""
        if (cf_name.trim() === "") { root.errorMsg = "Profile name is required."; return }
        if (cf_appId.trim() === "") { root.errorMsg = "Application ID is required."; return }
        if (cf_activityName.trim() === "") { root.errorMsg = "Activity name is required."; return }

        const obj = {
            name:          cf_name.trim(),
            application_id: cf_appId.trim(),
            activity_name: cf_activityName.trim(),
            details:       cf_details.trim(),
            state:         cf_state.trim(),
            url:           cf_streamUrl.trim()
        }
        root.busy = true
        createProc.jsonArg = JSON.stringify(obj)
        createProc.running = true
    }

    // ── UI ────────────────────────────────────────────────────────────────────

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors {
                fill: parent
                margins: Style.marginL
            }
            spacing: Style.marginL

            // ── Header ────────────────────────────────────────────────────────
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

                // Status badge
                Rectangle {
                    implicitWidth:  statusRow.implicitWidth + Style.marginS * 2
                    implicitHeight: statusRow.implicitHeight + Style.marginXS * 2
                    radius: Style.radiusS
                    color:  root.rpcActive
                                ? Qt.rgba(87/255, 242/255, 135/255, 0.15)
                                : Qt.rgba(Color.mOutline.r, Color.mOutline.g, Color.mOutline.b, 0.15)

                    RowLayout {
                        id: statusRow
                        anchors.centerIn: parent
                        spacing: Style.marginXS

                        Rectangle {
                            width:  8
                            height: 8
                            radius: 4
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

            // Active profile label when RPC is running
            Rectangle {
                Layout.fillWidth: true
                visible: root.rpcActive && root.activeProfile !== ""
                implicitHeight: activeRow.implicitHeight + Style.marginS * 2
                color:  Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.08)
                radius: Style.radiusM
                border.color: Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.3)
                border.width: 1

                RowLayout {
                    id: activeRow
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                        margins: Style.marginM
                    }
                    spacing: Style.marginS

                    NIcon { icon: "device-gamepad-2"; color: Color.mPrimary; applyUiScale: true }

                    NText {
                        text: "Currently broadcasting: " + root.activeProfile
                        color: Color.mPrimary
                        pointSize: Style.fontSizeS
                        font.weight: Font.Medium
                        Layout.fillWidth: true
                    }

                    NButton {
                        text: "Disable"
                        enabled: !root.busy
                        onClicked: root.disableRpc()
                    }
                }
            }

            // Error message
            Rectangle {
                Layout.fillWidth: true
                visible: root.errorMsg !== ""
                implicitHeight: errorText.implicitHeight + Style.marginS * 2
                color:  Qt.rgba(Color.mError.r, Color.mError.g, Color.mError.b, 0.1)
                radius: Style.radiusM

                NText {
                    id: errorText
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left; right: parent.right
                        margins: Style.marginM
                    }
                    text:      root.errorMsg
                    color:     Color.mError
                    pointSize: Style.fontSizeS
                    wrapMode:  Text.WordWrap
                }
            }

            // ── View switcher: profile list or create form ────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                NText {
                    text:       root.view === "list" ? "Profiles" : "New Profile"
                    pointSize:  Style.fontSizeM
                    font.weight: Font.DemiBold
                    color:      Color.mOnSurface
                    Layout.fillWidth: true
                }

                NButton {
                    visible: root.view === "list"
                    text:    "New Profile"
                    onClicked: {
                        root.resetCreateForm()
                        root.view = "create"
                    }
                }

                NButton {
                    visible: root.view === "create"
                    text:    "Cancel"
                    onClicked: root.view = "list"
                }
            }

            // ── Profile list ──────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.view === "list"
                color:   Color.mSurfaceVariant
                radius:  Style.radiusL

                // Empty state
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: profilesModel.count === 0
                    spacing: Style.marginM

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
                }

                // Profile cards
                NScrollView {
                    id: profileScrollView
                    anchors.fill: parent
                    visible: profilesModel.count > 0
                    horizontalPolicy: ScrollBar.AlwaysOff
                    verticalPolicy: ScrollBar.AsNeeded

                    ColumnLayout {
                        width: profileScrollView.availableWidth
                        spacing: Style.marginS

                        Item { Layout.preferredHeight: Style.marginS }

                        Repeater {
                            model: profilesModel

                            delegate: Rectangle {
                                required property string profileName
                                required property int    index

                                readonly property bool isActive:
                                    root.rpcActive && profileName === root.activeProfile

                                Layout.fillWidth: true
                                Layout.leftMargin:  Style.marginM
                                Layout.rightMargin: Style.marginM
                                implicitHeight: cardRow.implicitHeight + Style.marginM * 2

                                color:  cardMouse.containsMouse ? Color.mHover : Color.mSurface
                                radius: Style.radiusM
                                border.color: isActive ? Color.mPrimary : "transparent"
                                border.width: isActive ? 2 : 0

                                Behavior on color { ColorAnimation { duration: 120 } }

                                RowLayout {
                                    id: cardRow
                                    anchors {
                                        verticalCenter: parent.verticalCenter
                                        left: parent.left
                                        right: parent.right
                                        margins: Style.marginM
                                    }
                                    spacing: Style.marginM

                                    // Icon bubble
                                    Rectangle {
                                        width:  36
                                        height: 36
                                        radius: 18
                                        color: isActive
                                            ? Qt.rgba(Color.mPrimary.r, Color.mPrimary.g, Color.mPrimary.b, 0.2)
                                            : Color.mSurfaceVariant

                                        NIcon {
                                            anchors.centerIn: parent
                                            icon:  isActive ? "device-gamepad-2" : "brand-discord"
                                            color: isActive ? Color.mPrimary : Color.mOnSurfaceVariant
                                            applyUiScale: true
                                        }
                                    }

                                    // Name + active label
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        NText {
                                            text:        profileName
                                            color:       Color.mOnSurface
                                            pointSize:   Style.fontSizeM
                                            font.weight: Font.Medium
                                        }

                                        NText {
                                            visible:   isActive
                                            text:      "active"
                                            color:     Color.mPrimary
                                            pointSize: Style.fontSizeXS
                                        }
                                    }

                                    NIcon {
                                        visible:  isActive
                                        icon:     "circle-check-filled"
                                        color:    Color.mPrimary
                                        applyUiScale: true
                                    }

                                    NButton {
                                        visible:  !isActive
                                        text:     "Activate"
                                        enabled:  !root.busy
                                        outlined: true
                                        onClicked: root.activateProfile(profileName)
                                    }
                                }

                                MouseArea {
                                    id: cardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }
                        }

                        Item { Layout.preferredHeight: Style.marginS }
                    }
                }
            }

            // ── Create Profile form ───────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.view === "create"
                color:   Color.mSurfaceVariant
                radius:  Style.radiusL

                NScrollView {
                    anchors.fill: parent

                    ColumnLayout {
                        width: parent.width - Style.marginL * 2
                        x: Style.marginL
                        spacing: Style.marginM

                        // Required fields label
                        NText {
                            text:      "Required"
                            color:     Color.mOnSurfaceVariant
                            pointSize: Style.fontSizeXS
                            font.weight: Font.Medium
                            Layout.topMargin: Style.marginM
                        }

                        NTextInput {
                            Layout.fillWidth: true
                            label: "Profile name"
                            description: "Unique identifier, e.g. \"gaming\" (letters, numbers, _ -)"
                            text: root.cf_name
                            onTextChanged: root.cf_name = text
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

                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Color.mOutline
                            opacity: 0.4
                        }

                        // Optional fields label
                        NText {
                            text:      "Optional"
                            color:     Color.mOnSurfaceVariant
                            pointSize: Style.fontSizeXS
                            font.weight: Font.Medium
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
                            description: "Twitch / YouTube URL — sets activity type to Streaming"
                            text: root.cf_streamUrl
                            onTextChanged: root.cf_streamUrl = text
                        }

                        // Submit
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin:    Style.marginS
                            Layout.bottomMargin: Style.marginM

                            Item { Layout.fillWidth: true }

                            NButton {
                                text:      "Create Profile"
                                enabled:   !root.busy
                                onClicked: root.submitCreate()
                            }
                        }
                    }
                }
            }
        }
    }
}
