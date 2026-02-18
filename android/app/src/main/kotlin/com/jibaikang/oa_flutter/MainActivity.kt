package com.jibaikang.oa_flutter

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.amap.api.location.AMapLocation
import com.amap.api.location.AMapLocationClient
import com.amap.api.location.AMapLocationClientOption
import com.amap.api.location.AMapLocationListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "oa/location"
        private const val REQUEST_LOCATION_PERMISSION = 2001
        private const val LOCATION_TIMEOUT_MS = 15000L
    }

    private var permissionResult: MethodChannel.Result? = null
    private var locationResult: MethodChannel.Result? = null
    private var locationClient: AMapLocationClient? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var locationTimeoutTask: Runnable? = null

    private val amapLocationListener = AMapLocationListener { location ->
        if (location == null) {
            deliverLocationError("LOCATION_UNAVAILABLE", "无法获取当前位置")
            return@AMapLocationListener
        }
        if (location.errorCode != 0) {
            deliverLocationError(
                "LOCATION_UNAVAILABLE",
                "定位失败(${location.errorCode}): ${location.errorInfo}",
            )
            return@AMapLocationListener
        }
        deliverLocation(location)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 按高德要求，在使用 SDK 前完成隐私合规接口调用。
        AMapLocationClient.updatePrivacyShow(this, true, true)
        AMapLocationClient.updatePrivacyAgree(this, true)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isLocationServiceEnabled" -> result.success(isLocationServiceEnabled())
                    "checkPermission" -> result.success(checkPermissionStatus())
                    "requestPermission" -> requestLocationPermission(result)
                    "getCurrentPosition" -> getCurrentPosition(result)
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopTimeout()
        locationClient?.stopLocation()
        locationClient?.onDestroy()
        locationClient = null
    }

    private fun ensureLocationClient(): AMapLocationClient {
        val existing = locationClient
        if (existing != null) return existing

        val created = AMapLocationClient(applicationContext)
        created.setLocationListener(amapLocationListener)
        locationClient = created
        return created
    }

    private fun isLocationServiceEnabled(): Boolean {
        val locationManager =
            getSystemService(Context.LOCATION_SERVICE) as? android.location.LocationManager
                ?: return false
        return locationManager.isProviderEnabled(android.location.LocationManager.GPS_PROVIDER) ||
            locationManager.isProviderEnabled(android.location.LocationManager.NETWORK_PROVIDER)
    }

    private fun hasLocationPermission(): Boolean {
        val fineGranted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        val coarseGranted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        return fineGranted || coarseGranted
    }

    private fun checkPermissionStatus(): String {
        return if (hasLocationPermission()) "granted" else "denied"
    }

    private fun requestLocationPermission(result: MethodChannel.Result) {
        if (hasLocationPermission()) {
            result.success("granted")
            return
        }
        if (permissionResult != null) {
            result.error("REQUEST_IN_PROGRESS", "定位权限请求进行中", null)
            return
        }

        permissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION,
            ),
            REQUEST_LOCATION_PERMISSION,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_LOCATION_PERMISSION) return

        val granted = grantResults.any { it == PackageManager.PERMISSION_GRANTED }
        permissionResult?.success(if (granted) "granted" else "denied")
        permissionResult = null
    }

    private fun getCurrentPosition(result: MethodChannel.Result) {
        if (locationResult != null) {
            result.error("REQUEST_IN_PROGRESS", "定位请求进行中", null)
            return
        }
        if (!isLocationServiceEnabled()) {
            result.error("SERVICE_DISABLED", "定位服务未开启", null)
            return
        }
        if (!hasLocationPermission()) {
            result.error("PERMISSION_DENIED", "定位权限不足", null)
            return
        }

        val client = ensureLocationClient()
        val option = AMapLocationClientOption().apply {
            locationMode = AMapLocationClientOption.AMapLocationMode.Hight_Accuracy
            isNeedAddress = true
            isOnceLocation = true
            isOnceLocationLatest = true
            httpTimeOut = LOCATION_TIMEOUT_MS
        }

        locationResult = result
        startTimeout()
        client.stopLocation()
        client.setLocationOption(option)
        client.startLocation()
    }

    private fun startTimeout() {
        stopTimeout()
        locationTimeoutTask = Runnable {
            deliverLocationError("LOCATION_TIMEOUT", "定位超时")
        }
        mainHandler.postDelayed(locationTimeoutTask!!, LOCATION_TIMEOUT_MS)
    }

    private fun stopTimeout() {
        locationTimeoutTask?.let { mainHandler.removeCallbacks(it) }
        locationTimeoutTask = null
    }

    private fun deliverLocation(location: AMapLocation) {
        stopTimeout()
        locationClient?.stopLocation()

        val result = locationResult ?: return
        locationResult = null

        result.success(
            mapOf(
                "lat" to location.latitude,
                "lng" to location.longitude,
            ),
        )
    }

    private fun deliverLocationError(code: String, message: String) {
        stopTimeout()
        locationClient?.stopLocation()

        val result = locationResult ?: return
        locationResult = null
        result.error(code, message, null)
    }
}
