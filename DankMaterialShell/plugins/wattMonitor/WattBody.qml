import QtQuick
import qs.Common
import qs.Widgets

// Shared Watt status body, used by the bar popout and the Control Center detail.
// The host passes itself as `controller` (expects wattAvailable, rulesText,
// governor, epp, platform, freq, refresh()).
Item {
    id: root

    property var controller: null

    width: parent.width
    implicitHeight: bodyCol.implicitHeight

    readonly property bool live: controller && controller.wattAvailable

    Column {
        id: bodyCol
        width: parent.width
        spacing: Theme.spacingM

        Row {
            width: parent.width
            spacing: Theme.spacingM

            Rectangle {
                width: 10
                height: 10
                radius: 5
                color: root.live ? Theme.primary : Theme.surfaceTextMedium
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                spacing: 1
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 10 - Theme.spacingM

                StyledText {
                    text: root.live ? controller.profileLabel : I18n.tr("Not running")
                    font.pixelSize: Theme.fontSizeXLarge
                    color: root.live ? Theme.primary : Theme.surfaceText
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    width: parent.width
                }

                StyledText {
                    text: root.live ? (controller.topRule.length > 0 ? controller.topRule : I18n.tr("Managing CPU power")) : I18n.tr("Start watt.service to manage CPU power.")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceTextMedium
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
        }

        StyledText {
            text: root.live ? (controller.rulesText.length > 0 ? controller.rulesText : I18n.tr("No active rules")) : I18n.tr("Start watt.service to manage CPU power.")
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceText
            wrapMode: Text.WordWrap
            width: parent.width
        }

        Grid {
            width: parent.width
            columns: 2
            columnSpacing: Theme.spacingM
            rowSpacing: Theme.spacingS

            Column {
                width: (parent.width - Theme.spacingM) / 2
                spacing: Theme.spacingXXS

                StyledText {
                    text: I18n.tr("Governor · EPP")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceTextMedium
                    font.weight: Font.Medium
                }

                StyledText {
                    text: root.live ? controller.governor + " · " + controller.epp : "—"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceText
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            Column {
                width: (parent.width - Theme.spacingM) / 2
                spacing: Theme.spacingXXS

                StyledText {
                    text: I18n.tr("Platform · Freq")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceTextMedium
                    font.weight: Font.Medium
                }

                StyledText {
                    text: root.live ? controller.platform + " · " + controller.freq : "—"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceText
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
        }

        StyledText {
            text: I18n.tr("Updates every 5s · watt.service")
            font.pixelSize: Theme.fontSizeSmall - 1
            color: Theme.surfaceTextMedium
            width: parent.width
        }
    }
}
