import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

// Watt Monitor: a superset of the stock DMS Battery bar widget.
//
// The pill draws exactly what the stock battery pill draws (icon or pill art,
// percent, time, low-battery color) and appends a small Watt bolt marker.
// The popout adds profile buttons plus the live Watt section. A plugin cannot
// replace the built-in widget, so remove the stock Battery widget from the bar
// and place this one where it stood.
//
// Overhead: no daemon, no python. One short-lived
// /usr/local/bin/dms-watt-status process (~10ms) every 5s per mounted
// instance. Nothing runs while the plugin stays disabled.
PluginComponent {
    id: root

    layerNamespacePlugin: "watt-monitor"

    // ---- Watt live state ----------------------------------------------------
    property bool wattAvailable: false
    property string rulesText: ""
    property string topRule: ""
    property string governor: "—"
    property string epp: "—"
    property string platform: "—"
    property string freq: "—"
    property string profile: ""
    readonly property string profileLabel: {
        if (profile === "performance")
            return I18n.tr("Performance");
        if (profile === "power-saver")
            return I18n.tr("Power Saver");
        if (profile === "balanced")
            return I18n.tr("Balanced");
        return I18n.tr("Unknown");
    }
    readonly property string profileShort: {
        if (profile === "performance")
            return I18n.tr("Perf");
        if (profile === "power-saver")
            return I18n.tr("Saver");
        if (profile === "balanced")
            return I18n.tr("Bal");
        return "—";
    }

    // Unique Proc namespace per instance so concurrent instances
    // (bar pill, Control Center tile) never steal each other's callbacks.
    readonly property string procTag: "watt_" + Math.floor(Math.random() * 1e9)

    // Bar sizing guards (this qmllint predates `?.`, so guard manually).
    readonly property var barMaxIcons: root.barConfig ? root.barConfig.maximizeWidgetIcons : undefined
    readonly property var barIconScale: root.barConfig ? root.barConfig.iconScale : undefined
    readonly property var barFontScale: root.barConfig ? root.barConfig.fontScale : undefined
    readonly property var barMaxText: root.barConfig ? root.barConfig.maximizeWidgetText : undefined

    function refresh() {
        Proc.runCommand(procTag, ["/usr/local/bin/dms-watt-status"], function (out, code) {
            if (code !== 0)
                return
            try {
                const d = JSON.parse((out || "").trim());
                wattAvailable = d.available === true;
                const names = (d.rules || "").split("|").filter(function (x) {
                    return x && x.length > 0;
                });
                rulesText = names.join(" › ");
                topRule = names.length > 0 ? names[0] : "";
                governor = d.governor || "—";
                epp = d.epp || "—";
                platform = d.platform || "—";
                freq = d.freq_mhz ? d.freq_mhz + " MHz" : "—";
                profile = d.profile || "";
            } catch (e) {
                wattAvailable = false;
            }
        });
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()

    // ---- Stock battery display logic (mirrors Battery.qml) ------------------
    readonly property bool showPercent: SettingsData.showBatteryPercent && !(SettingsData.showBatteryPercentOnlyOnBattery && BatteryService.isPluggedIn)
    readonly property bool showTime: SettingsData.showBatteryTime
    readonly property string batteryTimeText: {
        if (SettingsData.showBatteryTimeOnlyOnBattery && BatteryService.isPluggedIn)
            return "";
        const time = BatteryService.formatTimeRemaining();
        return time !== "Unknown" ? time : "";
    }
    readonly property string horizontalSideText: {
        if (!SettingsData.batteryPillStyle) {
            if (showPercent && showTime && batteryTimeText)
                return `${BatteryService.batteryLevel}% (${batteryTimeText})`;
            if (showPercent)
                return `${BatteryService.batteryLevel}%`;
            if (showTime && batteryTimeText)
                return batteryTimeText;
            return "";
        }
        return (showTime && batteryTimeText) ? batteryTimeText : "";
    }
    readonly property string verticalDisplayText: {
        if (showPercent && showTime && batteryTimeText)
            return `${BatteryService.batteryLevel}\n${batteryTimeText}`;
        if (showPercent)
            return BatteryService.batteryLevel.toString();
        if (showTime && batteryTimeText)
            return batteryTimeText;
        return "";
    }
    readonly property color batteryIconColor: {
        if (!BatteryService.batteryAvailable)
            return Theme.widgetIconColor;
        if (BatteryService.isLowBattery && !BatteryService.isCharging)
            return Theme.error;
        if (BatteryService.isCharging || BatteryService.isPluggedIn)
            return Theme.primary;
        return Theme.widgetIconColor;
    }

    // Right click is info-only: Watt owns tuning, so there is no profile to cycle.
    pillRightClickAction: function () {
        ToastService.showInfo(I18n.tr("Watt manages power profiles"));
    }

    horizontalBarPill: Component {
        Row {
            spacing: 2

            DankIcon {
                name: BatteryService.getBatteryIcon()
                visible: !SettingsData.batteryPillStyle
                size: Theme.barIconSize(root.barThickness, -4, root.barMaxIcons, root.barIconScale)
                color: root.batteryIconColor
                anchors.verticalCenter: parent.verticalCenter
            }

            WattBatteryPill {
                visible: SettingsData.batteryPillStyle
                vertical: false
                showNumber: root.showPercent
                showPercentSign: SettingsData.batteryPillPercentSign
                thickness: Theme.barIconSize(root.barThickness, -4, root.barMaxIcons, root.barIconScale)
                anchors.verticalCenter: parent.verticalCenter
            }

            WattBolt {
                visible: SettingsData.batteryPillStyle && BatteryService.batteryAvailable && BatteryService.isCharging
                fillColor: Theme.primary
                size: Math.round(Theme.barIconSize(root.barThickness, -4, root.barMaxIcons, root.barIconScale) * 0.85)
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.horizontalSideText
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barFontScale, root.barMaxText)
                color: Theme.widgetTextColor
                anchors.verticalCenter: parent.verticalCenter
                visible: BatteryService.batteryAvailable && root.horizontalSideText !== ""
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 1

            DankIcon {
                name: BatteryService.getBatteryIcon()
                visible: !SettingsData.batteryPillStyle
                size: Theme.barIconSize(root.barThickness, undefined, root.barMaxIcons, root.barIconScale)
                color: root.batteryIconColor
                anchors.horizontalCenter: parent.horizontalCenter
            }

            WattBatteryPill {
                visible: SettingsData.batteryPillStyle
                vertical: true
                showNumber: false
                thickness: Theme.barIconSize(root.barThickness, undefined, root.barMaxIcons, root.barIconScale)
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: root.verticalDisplayText
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barFontScale, root.barMaxText)
                color: Theme.widgetTextColor
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
                visible: BatteryService.batteryAvailable && root.verticalDisplayText !== ""
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            headerText: I18n.tr("Battery · Watt")
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingM

                Row {
                    width: parent.width
                    height: 48
                    spacing: Theme.spacingM

                    DankIcon {
                        name: BatteryService.getBatteryIcon()
                        size: Theme.iconSizeLarge
                        color: {
                            if (BatteryService.isLowBattery && !BatteryService.isCharging)
                                return Theme.error;
                            if (BatteryService.isCharging || BatteryService.isPluggedIn)
                                return Theme.primary;
                            return Theme.surfaceText;
                        }
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        spacing: Theme.spacingXS
                        anchors.verticalCenter: parent.verticalCenter

                        Row {
                            spacing: Theme.spacingS

                            StyledText {
                                text: BatteryService.batteryAvailable ? `${BatteryService.batteryLevel}%` : I18n.tr("Power")
                                font.pixelSize: Theme.fontSizeXLarge
                                color: {
                                    if (BatteryService.isLowBattery && !BatteryService.isCharging)
                                        return Theme.error;
                                    if (BatteryService.isCharging)
                                        return Theme.primary;
                                    return Theme.surfaceText;
                                }
                                font.weight: Font.Bold
                            }

                            StyledText {
                                text: BatteryService.batteryStatus
                                font.pixelSize: Theme.fontSizeLarge
                                color: {
                                    if (BatteryService.isLowBattery && !BatteryService.isCharging)
                                        return Theme.error;
                                    if (BatteryService.isCharging)
                                        return Theme.primary;
                                    return Theme.surfaceText;
                                }
                                font.weight: Font.Medium
                                visible: BatteryService.batteryAvailable
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        StyledText {
                            text: {
                                if (!BatteryService.batteryAvailable)
                                    return "";
                                const time = BatteryService.formatTimeRemaining();
                                if (time === "Unknown")
                                    return "";
                                return BatteryService.isCharging ? I18n.tr("Time until full: %1").arg(time) : I18n.tr("Time remaining: %1").arg(time);
                            }
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceTextMedium
                            elide: Text.ElideRight
                            width: parent.width
                            visible: text.length > 0
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingM
                    visible: BatteryService.batteryAvailable

                    StyledRect {
                        width: (parent.width - Theme.spacingM) / 2
                        height: 64
                        radius: Theme.cornerRadius
                        color: Theme.nestedSurface
                        border.width: 0

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS

                            StyledText {
                                text: I18n.tr("Health")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.primary
                                font.weight: Font.Medium
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            StyledText {
                                text: BatteryService.batteryHealth
                                font.pixelSize: Theme.fontSizeLarge
                                color: {
                                    if (BatteryService.batteryHealth === "N/A")
                                        return Theme.surfaceText;
                                    const healthNum = parseInt(BatteryService.batteryHealth);
                                    return healthNum < 80 ? Theme.error : Theme.surfaceText;
                                }
                                font.weight: Font.Bold
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    StyledRect {
                        width: (parent.width - Theme.spacingM) / 2
                        height: 64
                        radius: Theme.cornerRadius
                        color: Theme.nestedSurface
                        border.width: 0

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS

                            StyledText {
                                text: I18n.tr("Capacity")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.primary
                                font.weight: Font.Medium
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            StyledText {
                                text: BatteryService.batteryCapacity > 0 ? `${BatteryService.batteryCapacity.toFixed(1)} Wh` : I18n.tr("Unknown")
                                font.pixelSize: Theme.fontSizeLarge
                                color: Theme.surfaceText
                                font.weight: Font.Bold
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }

                WattBody {
                    width: parent.width
                    controller: root
                }
            }
        }
    }

    popoutWidth: 400
    popoutHeight: 510

    // ---- Control Center tile --------------------------------------------------
    ccWidgetIcon: BatteryService.getBatteryIcon()
    ccWidgetPrimaryText: BatteryService.batteryAvailable ? `${BatteryService.batteryLevel}%` : I18n.tr("Power")
    ccWidgetSecondaryText: root.wattAvailable ? `${root.profileLabel} · ${root.platform}` : BatteryService.batteryStatus
    ccWidgetIsActive: root.wattAvailable
    ccWidgetIsToggle: false
    ccDetailHeight: 420

    ccDetailContent: Component {
        Rectangle {
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh
            border.width: 0

            Column {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingM

                StyledText {
                    text: BatteryService.batteryAvailable ? `${BatteryService.batteryLevel}% · ${BatteryService.batteryStatus}` : I18n.tr("No battery")
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    font.weight: Font.Medium
                    width: parent.width
                }

                WattBody {
                    width: parent.width
                    controller: root
                }
            }
        }
    }
}
