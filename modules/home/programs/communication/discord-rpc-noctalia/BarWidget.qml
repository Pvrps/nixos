import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    // ── Plugin API (injected by PluginService) ────────────────────────────────
    property var pluginApi: null

    // ── Required bar widget properties ───────────────────────────────────────
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    // ── Per-screen bar properties ─────────────────────────────────────────────
    readonly property string screenName:   screen?.name ?? ""
    readonly property string barPosition:  Settings.getBarPositionForScreen(screenName)
    readonly property bool   isBarVertical: barPosition === "left" || barPosition === "right"
    readonly property real   capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property real   barFontSize:   Style.getBarFontSizeForScreen(screenName)

    // ── State ─────────────────────────────────────────────────────────────────
    property bool   rpcActive:      false
    property string activeProfile:  ""

    // ── Sizing ────────────────────────────────────────────────────────────────
    readonly property real contentWidth:  row.implicitWidth + Style.marginM * 2
    readonly property real contentHeight: capsuleHeight

    implicitWidth:  contentWidth
    implicitHeight: contentHeight

    // ── Status poll (every 1 s, fallback when panel isn't open) ────────
    Timer {
        interval: 1000
        running:  true
        repeat:   true
        triggeredOnStart: true
        onTriggered: {
            statusProc.running = true
            profileProc.running = true
        }
    }

    // systemctl --user is-active discord-rpc.service
    Process {
        id: statusProc
        command: ["systemctl", "--user", "is-active", "--quiet", "discord-rpc.service"]
        onExited: (code) => {
            root.rpcActive = (code === 0)
            running = false
        }
    }

    // cat ~/.local/share/discord-rpc/current
    Process {
        id: profileProc
        command: ["bash", "-c",
                  "cat \"$HOME/.local/share/discord-rpc/current\" 2>/dev/null; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.activeProfile = String(this.text || "").trim()
                profileProc.running = false
            }
        }
    }

    // ── Visual capsule ────────────────────────────────────────────────────────
    Rectangle {
        id: visualCapsule
        x: Style.pixelAlignCenter(parent.width,  width)
        y: Style.pixelAlignCenter(parent.height, height)
        width:  root.contentWidth
        height: root.contentHeight
        color:  mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
        radius: Style.radiusL
        border.color: Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: Style.marginS

            // Discord logo icon — color reflects RPC state
            NIcon {
                icon:      "brand-discord"
                color:     root.rpcActive ? Color.mPrimary : Color.mOnSurfaceVariant
                applyUiScale: true
            }

            // Active profile name or "inactive"
            NText {
                text:       root.rpcActive && root.activeProfile !== ""
                                ? root.activeProfile
                                : "inactive"
                color:      root.rpcActive ? Color.mOnSurface : Color.mOnSurfaceVariant
                pointSize:  root.barFontSize
                font.weight: Font.Medium
            }

            // Small status dot
            Rectangle {
                width:  Style.marginS
                height: Style.marginS
                radius: width / 2
                color:  root.rpcActive ? "#57f287" : Color.mOutline  // Discord green / muted
            }
        }
    }

    // ── Click → open panel ────────────────────────────────────────────────────
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked: {
            if (pluginApi)
                pluginApi.openPanel(root.screen, root)
        }
    }

    Component.onCompleted: {
        Logger.i("DiscordRPC", "Bar widget loaded")
    }
}
