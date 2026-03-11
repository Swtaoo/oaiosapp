package uni.app.UN199BD502

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import com.amap.api.location.AMapLocation
import com.amap.api.location.AMapLocationClient
import com.amap.api.location.AMapLocationClientOption
import com.amap.api.location.AMapLocationListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugins.webviewflutter.WebViewFlutterPlugin
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "oa/location"
        private const val INSTALL_CHANNEL = "oa/install"
        private const val REQUEST_LOCATION_PERMISSION = 2001
        private const val REQUEST_INSTALL_PERMISSION = 2002
        private const val LOCATION_TIMEOUT_MS = 15000L
    }

    private var permissionResult: MethodChannel.Result? = null
    private var locationResult: MethodChannel.Result? = null
    private var installPermissionResult: MethodChannel.Result? = null
    private var pendingInstallPath: String? = null
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

        if (!flutterEngine.plugins.has(WebViewFlutterPlugin::class.java)) {
            GeneratedPluginRegistrant.registerWith(flutterEngine)
        }

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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INSTALL_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installApk" -> {
                        val filePath = call.argument<String>("filePath")
                        if (filePath == null) {
                            result.error("INVALID_ARG", "filePath is required", null)
                        } else {
                            installApk(filePath, result)
                        }
                    }
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
            // Flutter 侧会调用 WebService 逆地理编码获取地址，原生定位只需返回坐标即可，减少一次地址解析耗时
            isNeedAddress = false
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

    // APK 安装流程
    private fun installApk(filePath: String, result: MethodChannel.Result) {
        val file = File(filePath)
        if (!file.exists()) {
            result.error("FILE_NOT_FOUND", "APK file not found: $filePath", null)
            return
        }

        // Android 8.0+ 需要检查"安装未知来源"权限
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !packageManager.canRequestPackageInstalls()
        ) {
            // 保存状态，等用户从设置页返回后继续安装
            installPermissionResult = result
            pendingInstallPath = filePath
            val intent = Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:$packageName"),
            )
            startActivityForResult(intent, REQUEST_INSTALL_PERMISSION)
            return
        }

        doInstallApk(file, result)
    }

    private fun doInstallApk(file: File, result: MethodChannel.Result) {
        try {
            val uri = FileProvider.getUriForFile(
                this,
                "$packageName.fileProvider.com.crazecoder.openfile",
                file,
            )
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("INSTALL_ERROR", e.message, null)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_INSTALL_PERMISSION) {
            val result = installPermissionResult ?: return
            val path = pendingInstallPath
            installPermissionResult = null
            pendingInstallPath = null

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                packageManager.canRequestPackageInstalls() &&
                path != null
            ) {
                doInstallApk(File(path), result)
            } else {
                result.error("PERMISSION_DENIED", "用户未授权安装未知来源应用", null)
            }
        }
    }
}
