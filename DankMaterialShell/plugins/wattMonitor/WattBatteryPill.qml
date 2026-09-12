import QtQuick
import QtQuick.Shapes
import qs.Common
import qs.Services
import qs.Widgets

// Copy of the Material 3 battery pill art from the stock DMS Battery widget
// (Modules/DankBar/Widgets/Battery.qml). Lets the Watt plugin draw the exact
// same pill when SettingsData.batteryPillStyle is on.
Item {
    id: pill

    property real thickness: 18
    property bool vertical: false
    property bool showNumber: true
    property bool showPercentSign: false

    readonly property int signSize: Math.max(1, Math.round(pill.glyphSize * 0.72))
    readonly property real bodyLength: Math.round(pill.thickness * 1.95)
    readonly property real level: Math.max(0, Math.min(100, BatteryService.batteryLevel))
    readonly property bool charging: BatteryService.isCharging
    readonly property bool lowState: BatteryService.isLowBattery && !BatteryService.isCharging
    readonly property color fillColor: {
        if (!BatteryService.batteryAvailable)
            return Theme.surfaceVariant;
        if (pill.lowState)
            return Theme.error;
        return Theme.primary;
    }
    readonly property color onFillColor: {
        const c = pill.fillColor;
        const lum = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
        return lum > 0.5 ? Qt.rgba(0, 0, 0, 0.9) : Qt.rgba(1, 1, 1, 0.95);
    }
    readonly property string numberText: Math.round(pill.level).toString()
    readonly property int glyphSize: Math.round(pill.thickness * 0.58)
    readonly property int boltSize: Math.round(pill.thickness * 0.72)
    readonly property real nubBreadth: Math.round(pill.thickness * 0.16)
    readonly property real nubSpan: Math.round(pill.thickness * 0.46)

    implicitWidth: pill.vertical ? pill.thickness : Math.max(pill.bodyLength, (!pill.vertical && pill.showNumber) ? numRowTrack.width + pill.thickness * 0.7 : 0) + pill.nubBreadth
    implicitHeight: pill.vertical ? pill.bodyLength + pill.nubBreadth : pill.thickness

    Rectangle {
        id: body
        x: 0
        y: pill.vertical ? pill.nubBreadth : 0
        width: pill.vertical ? parent.width : parent.width - pill.nubBreadth
        height: pill.vertical ? parent.height - pill.nubBreadth : parent.height
        radius: Math.round(Math.min(width, height) * 0.34)
        color: Theme.withAlpha(Theme.surfaceVariant, 0.9)

        Rectangle {
            id: fill
            radius: body.radius
            color: pill.fillColor
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: pill.vertical ? parent.width : Math.round(parent.width * pill.level / 100)
            height: pill.vertical ? Math.round(parent.height * pill.level / 100) : parent.height

            Behavior on width {
                enabled: !pill.vertical
                NumberAnimation {
                    duration: Theme.mediumDuration
                    easing.type: Theme.standardEasing
                }
            }

            Behavior on height {
                enabled: pill.vertical
                NumberAnimation {
                    duration: Theme.mediumDuration
                    easing.type: Theme.standardEasing
                }
            }
        }

        Item {
            id: glyphTrack
            anchors.fill: parent
            visible: BatteryService.batteryAvailable && ((pill.charging && pill.vertical) || (!pill.vertical && pill.showNumber))

            Row {
                id: numRowTrack
                visible: !pill.vertical && pill.showNumber
                anchors.centerIn: parent
                spacing: 1

                StyledText {
                    id: numTrack
                    text: pill.numberText
                    color: Theme.surfaceText
                    font.pixelSize: pill.glyphSize
                    font.weight: Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: "%"
                    visible: pill.showPercentSign
                    color: Theme.surfaceText
                    font.pixelSize: pill.signSize
                    font.weight: Font.Bold
                    anchors.baseline: numTrack.baseline
                }
            }

            DankIcon {
                name: "bolt"
                size: pill.boltSize
                color: Theme.surfaceText
                visible: pill.charging && pill.vertical
                anchors.centerIn: parent
            }
        }

        Item {
            visible: glyphTrack.visible
            x: fill.x
            y: fill.y
            width: fill.width
            height: fill.height
            clip: true

            Item {
                x: -fill.x
                y: -fill.y
                width: body.width
                height: body.height

                Row {
                    visible: !pill.vertical && pill.showNumber
                    anchors.centerIn: parent
                    spacing: 1

                    StyledText {
                        id: numFill
                        text: pill.numberText
                        color: pill.onFillColor
                        font.pixelSize: pill.glyphSize
                        font.weight: Font.Bold
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: "%"
                        visible: pill.showPercentSign
                        color: pill.onFillColor
                        font.pixelSize: pill.signSize
                        font.weight: Font.Bold
                        anchors.baseline: numFill.baseline
                    }
                }

                DankIcon {
                    name: "bolt"
                    size: pill.boltSize
                    color: pill.onFillColor
                    visible: pill.charging && pill.vertical
                    anchors.centerIn: parent
                }
            }
        }
    }

    Rectangle {
        visible: !pill.vertical
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: pill.nubBreadth
        height: pill.nubSpan
        radius: Math.round(pill.nubBreadth * 0.35)
        color: Theme.withAlpha(Theme.surfaceVariant, 0.9)
    }

    Rectangle {
        visible: pill.vertical
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: pill.nubSpan
        height: pill.nubBreadth
        radius: Math.round(pill.nubBreadth * 0.35)
        color: Theme.withAlpha(Theme.surfaceVariant, 0.9)
    }
}
