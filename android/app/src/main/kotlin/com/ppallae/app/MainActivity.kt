package com.ppallae.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 위젯 우선 앱의 네이티브 다리:
 *  - 배터리 최적화 예외 상태 조회 + 시스템 설정 화면 열기 (WorkManager 갱신이 죽지 않게)
 *  - 홈에 위젯 고정(requestPinAppWidget) — 위젯 발견성
 *
 * Dart 측 진입점: PpallaeNative (lib/core/ppallae_native.dart).
 */
class MainActivity : FlutterActivity() {
    private val channelName = "ppallae/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isIgnoringBatteryOptimizations" ->
                    result.success(isIgnoringBatteryOptimizations())
                "openBatteryOptimizationSettings" ->
                    result.success(openBatteryOptimizationSettings())
                "requestPinWidget" ->
                    result.success(requestPinWidget(call.argument<String>("size")))
                "isPinWidgetSupported" ->
                    result.success(isPinWidgetSupported())
                else -> result.notImplemented()
            }
        }
    }

    /** 이 앱이 배터리 최적화 예외 목록에 있는지. 예외면 백그라운드 갱신이 잘 돎. */
    private fun isIgnoringBatteryOptimizations(): Boolean {
        val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return true
        return pm.isIgnoringBatteryOptimizations(packageName)
    }

    /**
     * 배터리 최적화 설정 화면을 연다. 특수 권한 요청(Play 심사 마찰) 대신
     * 표준 설정 목록을 열어 사용자가 직접 "제한 없음"으로 바꾸도록 유도.
     * 실패 시 앱 상세 설정으로 폴백.
     */
    private fun openBatteryOptimizationSettings(): Boolean {
        return try {
            startActivity(
                Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            true
        } catch (e: Exception) {
            try {
                startActivity(
                    Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.parse("package:$packageName"),
                    ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
                true
            } catch (e2: Exception) {
                false
            }
        }
    }

    /** requestPinAppWidget 지원 여부 (API 26+ & 런처 지원). */
    private fun isPinWidgetSupported(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        val awm = getSystemService(AppWidgetManager::class.java) ?: return false
        return awm.isRequestPinAppWidgetSupported
    }

    /**
     * 홈 화면에 위젯 고정 요청. size="1x1" | "2x1" (기본 2x1).
     * 지원 안 하면 false 반환 → Dart 가 "홈 길게 눌러 추가" 안내로 폴백.
     */
    private fun requestPinWidget(size: String?): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        val awm = getSystemService(AppWidgetManager::class.java) ?: return false
        if (!awm.isRequestPinAppWidgetSupported) return false
        val providerClass = if (size == "1x1") {
            PpallaeWidget1x1Provider::class.java
        } else {
            PpallaeWidget3x1Provider::class.java
        }
        val provider = ComponentName(this, providerClass)
        return try {
            awm.requestPinAppWidget(provider, null, null)
        } catch (e: Exception) {
            false
        }
    }
}
