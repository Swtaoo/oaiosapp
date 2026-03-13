import 'dart:math' as math;

/// WGS84 ↔ GCJ02 坐标转换
///
/// iOS CLLocationManager 返回 WGS84 坐标，而高德地图及后端围栏坐标使用 GCJ02。
/// 在中国境内两种坐标系之间存在 300-500 米的偏移，必须转换后才能进行围栏距离判断。

const double _a = 6378245.0; // Krasovsky 椭球体长半轴
const double _ee = 0.00669342162296594323; // Krasovsky 椭球体偏心率平方

/// 判断坐标是否在中国境外（境外无需转换）
bool _outOfChina(double lat, double lng) {
  return lng < 72.004 || lng > 137.8347 || lat < 0.8293 || lat > 55.8271;
}

double _transformLat(double x, double y) {
  var ret = -100.0 +
      2.0 * x +
      3.0 * y +
      0.2 * y * y +
      0.1 * x * y +
      0.2 * math.sqrt(x.abs());
  ret += (20.0 * math.sin(6.0 * x * math.pi) +
          20.0 * math.sin(2.0 * x * math.pi)) *
      2.0 /
      3.0;
  ret += (20.0 * math.sin(y * math.pi) +
          40.0 * math.sin(y / 3.0 * math.pi)) *
      2.0 /
      3.0;
  ret += (160.0 * math.sin(y / 12.0 * math.pi) +
          320.0 * math.sin(y * math.pi / 30.0)) *
      2.0 /
      3.0;
  return ret;
}

double _transformLng(double x, double y) {
  var ret = 300.0 +
      x +
      2.0 * y +
      0.1 * x * x +
      0.1 * x * y +
      0.1 * math.sqrt(x.abs());
  ret += (20.0 * math.sin(6.0 * x * math.pi) +
          20.0 * math.sin(2.0 * x * math.pi)) *
      2.0 /
      3.0;
  ret += (20.0 * math.sin(x * math.pi) +
          40.0 * math.sin(x / 3.0 * math.pi)) *
      2.0 /
      3.0;
  ret += (150.0 * math.sin(x / 12.0 * math.pi) +
          300.0 * math.sin(x / 30.0 * math.pi)) *
      2.0 /
      3.0;
  return ret;
}

/// WGS84 → GCJ02 坐标转换
///
/// 返回 `(gcjLat, gcjLng)` 记录。中国境外坐标原样返回。
({double lat, double lng}) wgs84ToGcj02(double wgsLat, double wgsLng) {
  if (_outOfChina(wgsLat, wgsLng)) {
    return (lat: wgsLat, lng: wgsLng);
  }

  var dLat = _transformLat(wgsLng - 105.0, wgsLat - 35.0);
  var dLng = _transformLng(wgsLng - 105.0, wgsLat - 35.0);
  final radLat = wgsLat / 180.0 * math.pi;
  var magic = math.sin(radLat);
  magic = 1 - _ee * magic * magic;
  final sqrtMagic = math.sqrt(magic);
  dLat = (dLat * 180.0) / ((_a * (1 - _ee)) / (magic * sqrtMagic) * math.pi);
  dLng = (dLng * 180.0) / (_a / sqrtMagic * math.cos(radLat) * math.pi);
  return (lat: wgsLat + dLat, lng: wgsLng + dLng);
}
