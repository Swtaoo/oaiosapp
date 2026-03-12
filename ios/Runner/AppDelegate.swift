import CoreLocation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, CLLocationManagerDelegate {
  private let locationChannelName = "oa/location"
  private var locationChannel: FlutterMethodChannel?
  private var locationManager: CLLocationManager?

  private var permissionResult: FlutterResult?
  private var locationResult: FlutterResult?
  private var shouldStartLocationAfterPermission = false
  private var timeoutWorkItem: DispatchWorkItem?

  /// 精度过滤：收集定位结果，选取最优
  private var bestLocation: CLLocation?
  /// 精度达标阈值（米），低于此值立即返回
  private let acceptableAccuracy: CLLocationDistance = 50
  /// 最大等待时间（秒），超时后返回已收集到的最优结果
  private let locationCollectTimeout: TimeInterval = 10
  /// 位置有效期（秒），超过此时间的缓存位置视为过期
  private let maxLocationAge: TimeInterval = 30

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "oa_location_channel")
    guard let registrar else { return }
    let channel = FlutterMethodChannel(
      name: locationChannelName,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleLocationMethodCall(call, result: result)
    }
    locationChannel = channel
  }

  private func handleLocationMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isLocationServiceEnabled":
      result(CLLocationManager.locationServicesEnabled())
    case "checkPermission":
      result(permissionStatusString(currentAuthorizationStatus()))
    case "requestPermission":
      requestPermission(result: result)
    case "getCurrentPosition":
      requestCurrentLocation(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func ensureLocationManager() -> CLLocationManager {
    if let manager = locationManager {
      return manager
    }
    let manager = CLLocationManager()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager = manager
    return manager
  }

  private func currentAuthorizationStatus() -> CLAuthorizationStatus {
    if #available(iOS 14.0, *) {
      return ensureLocationManager().authorizationStatus
    }
    return CLLocationManager.authorizationStatus()
  }

  private func permissionStatusString(_ status: CLAuthorizationStatus) -> String {
    switch status {
    case .authorizedAlways, .authorizedWhenInUse:
      return "granted"
    default:
      return "denied"
    }
  }

  private func requestPermission(result: @escaping FlutterResult) {
    if !CLLocationManager.locationServicesEnabled() {
      result(FlutterError(code: "SERVICE_DISABLED", message: "定位服务未开启", details: nil))
      return
    }

    let status = currentAuthorizationStatus()
    if status == .authorizedAlways || status == .authorizedWhenInUse {
      result("granted")
      return
    }

    permissionResult = result
    ensureLocationManager().requestWhenInUseAuthorization()
  }

  private func requestCurrentLocation(result: @escaping FlutterResult) {
    if locationResult != nil {
      result(FlutterError(code: "REQUEST_IN_PROGRESS", message: "定位请求进行中", details: nil))
      return
    }

    if !CLLocationManager.locationServicesEnabled() {
      result(FlutterError(code: "SERVICE_DISABLED", message: "定位服务未开启", details: nil))
      return
    }

    let status = currentAuthorizationStatus()
    switch status {
    case .authorizedAlways, .authorizedWhenInUse:
      locationResult = result
      startSingleLocationRequest()
    case .notDetermined:
      locationResult = result
      shouldStartLocationAfterPermission = true
      ensureLocationManager().requestWhenInUseAuthorization()
    case .denied, .restricted:
      result(FlutterError(code: "PERMISSION_DENIED", message: "定位权限不足", details: nil))
    @unknown default:
      result(FlutterError(code: "LOCATION_UNAVAILABLE", message: "定位服务不可用", details: nil))
    }
  }

  private func startSingleLocationRequest() {
    let manager = ensureLocationManager()
    stopTimeout()
    bestLocation = nil

    // 超时后返回已收集到的最优位置（而非直接报错）
    let workItem = DispatchWorkItem { [weak self] in
      guard let self = self else { return }
      if let best = self.bestLocation {
        manager.stopUpdatingLocation()
        self.finishLocationSuccess(
          lat: best.coordinate.latitude,
          lng: best.coordinate.longitude
        )
      } else {
        manager.stopUpdatingLocation()
        self.finishLocationError(code: "LOCATION_TIMEOUT", message: "定位超时")
      }
    }
    timeoutWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + locationCollectTimeout, execute: workItem)

    // 使用 startUpdatingLocation 持续获取定位，直到精度达标或超时
    manager.startUpdatingLocation()
  }

  private func stopTimeout() {
    timeoutWorkItem?.cancel()
    timeoutWorkItem = nil
  }

  private func finishLocationSuccess(lat: Double, lng: Double) {
    stopTimeout()
    locationManager?.stopUpdatingLocation()
    bestLocation = nil
    let callback = locationResult
    locationResult = nil
    guard let callback else { return }

    let payload: [String: Any] = [
      "lat": lat,
      "lng": lng,
    ]
    callback(payload)
  }

  private func finishLocationError(code: String, message: String) {
    stopTimeout()
    locationManager?.stopUpdatingLocation()
    bestLocation = nil
    let callback = locationResult
    locationResult = nil
    callback?(FlutterError(code: code, message: message, details: nil))
  }

  private func finishPermissionResult(granted: Bool) {
    permissionResult?(granted ? "granted" : "denied")
    permissionResult = nil
  }

  @available(iOS 14.0, *)
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    handleAuthorizationChange(manager.authorizationStatus)
  }

  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    if #available(iOS 14.0, *) {
      return
    }
    handleAuthorizationChange(status)
  }

  private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
    switch status {
    case .authorizedAlways, .authorizedWhenInUse:
      finishPermissionResult(granted: true)
      if shouldStartLocationAfterPermission && locationResult != nil {
        shouldStartLocationAfterPermission = false
        startSingleLocationRequest()
      }
    case .denied, .restricted:
      finishPermissionResult(granted: false)
      shouldStartLocationAfterPermission = false
      if locationResult != nil {
        finishLocationError(code: "PERMISSION_DENIED", message: "定位权限不足")
      }
    case .notDetermined:
      break
    @unknown default:
      finishPermissionResult(granted: false)
      shouldStartLocationAfterPermission = false
      if locationResult != nil {
        finishLocationError(code: "LOCATION_UNAVAILABLE", message: "定位服务不可用")
      }
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard locationResult != nil else {
      // 没有待处理的请求，停止定位
      manager.stopUpdatingLocation()
      return
    }

    for location in locations {
      // 过滤无效定位（horizontalAccuracy < 0 表示无效）
      guard location.horizontalAccuracy >= 0 else { continue }

      // 过滤过期缓存位置
      let age = -location.timestamp.timeIntervalSinceNow
      guard age <= maxLocationAge else { continue }

      // 记录精度更好的位置
      if bestLocation == nil || location.horizontalAccuracy < bestLocation!.horizontalAccuracy {
        bestLocation = location
      }

      // 精度达标，立即返回
      if location.horizontalAccuracy <= acceptableAccuracy {
        manager.stopUpdatingLocation()
        finishLocationSuccess(
          lat: location.coordinate.latitude,
          lng: location.coordinate.longitude
        )
        return
      }
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    // 如果已经收集到了位置，忽略错误，等超时返回最优结果
    if bestLocation != nil { return }
    manager.stopUpdatingLocation()
    finishLocationError(code: "LOCATION_UNAVAILABLE", message: error.localizedDescription)
  }
}
