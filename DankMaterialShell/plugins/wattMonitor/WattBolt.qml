import QtQuick
import QtQuick.Shapes
import qs.Common

// Copy of the AOSP battery bolt glyph from the stock DMS Battery widget.
// Shown beside the pill when pill style is on and the battery charges.
Shape {
    id: officialBolt
    property color fillColor: Theme.surfaceText
    property real size: 16
    implicitWidth: Math.round(officialBolt.size * (6 / 13))
    implicitHeight: Math.round(officialBolt.size)
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: officialBolt.fillColor
        strokeColor: "transparent"

        startX: officialBolt.width * (1 / 3)
        startY: officialBolt.height
        PathLine {
            x: officialBolt.width * (1 / 3)
            y: officialBolt.height * (7.5 / 13)
        }
        PathLine {
            x: 0
            y: officialBolt.height * (7.5 / 13)
        }
        PathLine {
            x: officialBolt.width * (2 / 3)
            y: 0
        }
        PathLine {
            x: officialBolt.width * (2 / 3)
            y: officialBolt.height * (5.5 / 13)
        }
        PathLine {
            x: officialBolt.width
            y: officialBolt.height * (5.5 / 13)
        }
        PathLine {
            x: officialBolt.width * (1 / 3)
            y: officialBolt.height
        }
    }
}
