import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtLocation 5.12
import QtPositioning 5.12

Window {
    visible: true
    width: 640
    height: 480
    title: qsTr("地理院地図シンプルビューワ")

    // マップ表示用のプラグイン OpenStreetMapプラグインのカスタムマップとして地理院地図を使用
    Plugin {
        id: mapPlugin
        name: "osm"

        PluginParameter{
            name: "osm.mapping.custom.host"
            value: "https://cyberjapandata.gsi.go.jp/xyz/std/"
        }
        PluginParameter{
            name: "osm.mapping.custom.mapcopyright"
            value: "<a href=\"https://maps.gsi.go.jp/development/ichiran.html#std\">国土地理院</a> "
        }
        PluginParameter{
            name: "osm.mapping.providersrepository.disabled"
            value: true
        }
    }
    // マップ
    Map{
        id: mainMap
        anchors.fill: parent
        plugin: mapPlugin
        activeMapType: supportedMapTypes[supportedMapTypes.length - 1]
        onCopyrightLinkActivated: Qt.openUrlExternally(link)
        maximumZoomLevel: 18
        minimumZoomLevel: 2
        zoomLevel: 14
        center: QtPositioning.coordinate(35.677, 139.77) // 東京駅
    }
    // 拡大と縮小のスライダ
    Slider{
        id: zoomSlider
        width: 20
        height: 100
        orientation : Qt.Vertical
        anchors.top: mainMap.top
        anchors.left: mainMap.left
        anchors.margins: 2
        from: mainMap.minimumZoomLevel
        to: mainMap.maximumZoomLevel
        value: mainMap.zoomLevel
        handle: Rectangle {
            x: zoomSlider.leftPadding + zoomSlider.availableWidth /2 - width / 2
            y: zoomSlider.topPadding + zoomSlider.visualPosition * (zoomSlider.availableHeight - height)
            implicitWidth: zoomSlider.width
            implicitHeight: zoomSlider.width/2
            radius: zoomSlider.width/4
            color: zoomSlider.pressed ? "#f0f0f0" : "#f6f6f6"
            border.color: "#bdbebf"
        }
        onValueChanged: {
            mainMap.zoomLevel = value
            mapScale.requestPaint()
        }
    }
    // 地図のスケール
    Canvas {
        id: mapScale
        width: 150
        height: 40
        anchors.bottom: mainMap.bottom
        anchors.right: mainMap.right
        anchors.margins: 2
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            // 背景の設定
            ctx.fillStyle = Qt.rgba(1, 1, 1, 0.5);
            ctx.fillRect(0, 0, width, height);
            // スケールの実距離の計算によりスケールの大きさとラベルの取得
            var[scalelength, scalelabel] = scaleDistanse();
            // スケールの外枠の描画
            ctx.beginPath();
            ctx.lineWidth = 2;
            var linemargin = ctx.lineWidth / 2;
            ctx.strokeStyle = "black";
            ctx.moveTo(width-linemargin, height/2);
            ctx.lineTo(width-linemargin, height-linemargin);
            ctx.lineTo(width-scalelength,height-linemargin);
            ctx.lineTo(width-scalelength,height/2);
            ctx.stroke();
            // スケールの目盛りの描画
            ctx.beginPath();
            ctx.strokeStyle = "black";
            ctx.lineWidth = 1;
            var sublinehight = height/3;
            var sublinenumber = 5;
            for(var i=1; i <sublinenumber; i++){
                var subscalewidth = Math.round(scalelength/sublinenumber);
                ctx.moveTo(width-subscalewidth*i, height-sublinehight);
                ctx.lineTo(width-subscalewidth*i, height-linemargin);
            }
            ctx.stroke();
            // ラベルの描画
            ctx.strokeStyle = "black";
            ctx.lineWidth = 1;
            ctx.strokeText(scalelabel, width-scalelength, height/4);
        }
        // スケールの実距離の計算によりスケールの大きさとラベルの取得
        function scaleDistanse(){
            var coordiL, coordiR, realdist, realdiststr, realdigit, firstdigit, scaledist;
            var scalelength, scalelabel;
            // スケールの右下と左下の座標から実距離を計算
            coordiL = mainMap.toCoordinate(Qt.point(mapScale.x, mapScale.y + mapScale.height));
            coordiR = mainMap.toCoordinate(Qt.point(mapScale.x + mapScale.width, mapScale.y + mapScale.height));
            realdist = Math.round(coordiL.distanceTo(coordiR));
            // 実距離の桁数と先頭の数字からスケールの大きさを判定
            realdiststr = realdist.toString(10);
            realdigit = realdiststr.length;
            firstdigit = parseInt(realdiststr[0]);
            if( firstdigit === 1){
                scaledist = 1 * (10 ** (realdigit-1));
            }
            else if(firstdigit > 1 && firstdigit < 5){
                scaledist = 2 * (10 ** (realdigit-1));
            }
            else{
                scaledist = 5 * (10 ** (realdigit-1));
            }
            scalelength = Math.round(mapScale.width * scaledist / realdist);
            // スケールのラベルを作成
            if(scaledist >= 1000){
                scalelabel = (scaledist / 1000).toString(10) + "km";
            }
            else{
                scalelabel = scaledist.toString(10) + "m";
            }
            return[scalelength, scalelabel];
        }
    }
}
