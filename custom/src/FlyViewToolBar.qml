/*---------------------------------------------------------------------------
 * pdlGCS / TZX — Custom FlyViewToolBar
 *
 * 相比官方版：
 *   1. 去掉左侧"紫色→透明"局部渐变与其它半透明覆盖层
 *   2. 整条工具栏铺一张"深空蓝 → 墨绿"的横向渐变（与品牌色一致）
 *   3. 底部加一条细分割线（墨绿），让工具栏与地图更分明
 *   4. 其它功能节点（Logo、状态、飞行模式、右侧指示器）位置保持不变
 *
 * 资源前缀：:/Custom/qml/QGroundControl/Toolbar/FlyViewToolBar.qml
 *--------------------------------------------------------------------------*/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView

Item {
    required property var guidedValueSlider

    id:     control
    width:  parent.width
    height: ScreenTools.toolbarHeight

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property bool   _communicationLost: _activeVehicle ? _activeVehicle.vehicleLinkManager.communicationLost : false
    property real   _leftRightMargin:   ScreenTools.defaultFontPixelWidth * 0.75
    property var    _guidedController:  globals.guidedControllerFlyView

    // 渐变两端色（可随 palette 调整），这里硬编码贴近品牌：深空蓝 → 墨绿
    readonly property color _gradStart: "#0B1B3B"
    readonly property color _gradEnd:   "#0E3B2E"
    readonly property color _accentLine: "#1F6B55"

    function dropMainStatusIndicatorTool() {
        mainStatusIndicator.dropMainStatusIndicator();
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    // ---- 整条工具栏的渐变背景 ----
    Rectangle {
        id: toolbarBackground
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: control._gradStart }
            GradientStop { position: 1.0; color: control._gradEnd }
        }
    }

    // 底部分割线
    Rectangle {
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        height:         1
        color:          control._accentLine
        opacity:        0.6
    }

    // ---- 工具栏内容 ----
    QGCFlickable {
        anchors.fill:       parent
        contentWidth:       toolBarLayout.width
        flickableDirection: Flickable.HorizontalFlick

        Row {
            id:         toolBarLayout
            height:     parent.height
            spacing:    0

            // 左侧：Logo + 主状态 + 飞行模式
            Item {
                id:     leftPanel
                width:  leftPanelLayout.implicitWidth
                height: parent.height

                RowLayout {
                    id:         leftPanelLayout
                    height:     parent.height
                    spacing:    ScreenTools.defaultFontPixelWidth * 2

                    RowLayout {
                        id:         mainStatusLayout
                        height:     parent.height
                        spacing:    0

                        QGCToolBarButton {
                            id:                 qgcButton
                            Layout.fillHeight:  true
                            icon.source:        "/res/QGCLogoFull.svg"  // 运行期 Interceptor 会指向 TZX Logo
                            logo:               true
                            onClicked:          mainWindow.showToolSelectDialog()
                        }

                        MainStatusIndicator {
                            id:                 mainStatusIndicator
                            Layout.fillHeight:  true
                        }
                    }

                    QGCButton {
                        id:         disconnectButton
                        text:       qsTr("Disconnect")
                        onClicked:  _activeVehicle.closeVehicle()
                        visible:    _activeVehicle && _communicationLost
                    }

                    FlightModeIndicator {
                        Layout.fillHeight:  true
                        visible:            _activeVehicle
                    }
                }
            }

            // 中间：引导动作确认条（原样保留，不再加半透明遮罩）
            Item {
                id:     centerPanel
                width:  Math.max(guidedActionConfirm.visible ? guidedActionConfirm.width : 0,
                                 control.width - (leftPanel.width + rightPanel.width))
                height: parent.height

                GuidedActionConfirm {
                    id:                         guidedActionConfirm
                    height:                     parent.height
                    anchors.horizontalCenter:   parent.horizontalCenter
                    guidedController:           control._guidedController
                    guidedValueSlider:          control.guidedValueSlider
                    messageDisplay:             guidedActionMessageDisplay
                }
            }

            // 右侧：各种指示器
            Item {
                id:     rightPanel
                width:  flyViewIndicators.width
                height: parent.height

                FlyViewToolBarIndicators {
                    id:     flyViewIndicators
                    height: parent.height
                }
            }
        }
    }

    // 引导动作的浮动消息（放在工具栏下方，不参与 Flickable）
    Rectangle {
        id:                         guidedActionMessageDisplay
        anchors.top:                control.bottom
        anchors.topMargin:          _margins
        x:                          control.mapFromItem(guidedActionConfirm.parent, guidedActionConfirm.x, 0).x
                                    + (guidedActionConfirm.width - guidedActionMessageDisplay.width) / 2
        width:                      messageLabel.contentWidth + (_margins * 2)
        height:                     messageLabel.contentHeight + (_margins * 2)
        color:                      qgcPal.window
        border.color:               control._accentLine
        border.width:               1
        radius:                     ScreenTools.defaultBorderRadius
        visible:                    guidedActionConfirm.visible

        QGCLabel {
            id:         messageLabel
            x:          _margins
            y:          _margins
            width:      ScreenTools.defaultFontPixelWidth * 30
            wrapMode:   Text.WordWrap
            text:       guidedActionConfirm.message
        }

        PropertyAnimation {
            id:         messageOpacityAnimation
            target:     guidedActionMessageDisplay
            property:   "opacity"
            from:       1
            to:         0
            duration:   500
        }

        Timer {
            id:             messageFadeTimer
            interval:       4000
            onTriggered:    messageOpacityAnimation.start()
        }
    }

    ParameterDownloadProgress {
        anchors.fill: parent
    }
}
