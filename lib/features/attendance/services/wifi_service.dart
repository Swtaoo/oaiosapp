import 'package:flutter_riverpod/flutter_riverpod.dart';

/// WiFi 信息
class WiFiInfo {
  final String ssid;
  final String? bssid;
  final int? signalStrength;

  const WiFiInfo({
    required this.ssid,
    this.bssid,
    this.signalStrength,
  });
}

/// WiFi 检测状态
class WiFiState {
  final WiFiInfo? currentWiFi;
  final bool isConnected;
  final bool isInWhitelist;
  final bool isLoading;
  final String? error;

  const WiFiState({
    this.currentWiFi,
    this.isConnected = false,
    this.isInWhitelist = false,
    this.isLoading = false,
    this.error,
  });

  WiFiState copyWith({
    WiFiInfo? currentWiFi,
    bool? isConnected,
    bool? isInWhitelist,
    bool? isLoading,
    String? error,
  }) =>
      WiFiState(
        currentWiFi: currentWiFi ?? this.currentWiFi,
        isConnected: isConnected ?? this.isConnected,
        isInWhitelist: isInWhitelist ?? this.isInWhitelist,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

/// WiFi 服务 - 对应 src/composables/useWiFi.ts
/// 使用 network_info_plus 获取 WiFi 信息
class WiFiNotifier extends StateNotifier<WiFiState> {
  WiFiNotifier() : super(const WiFiState());

  /// 获取当前 WiFi 信息
  Future<WiFiInfo?> getWiFiInfo() async {
    state = state.copyWith(isLoading: true);
    try {
      // TODO: 使用 network_info_plus 获取 WiFi SSID
      // 当前返回 null 表示无法获取
      state = state.copyWith(
        currentWiFi: null,
        isConnected: false,
        isLoading: false,
      );
      return null;
    } catch (e) {
      state = state.copyWith(
        currentWiFi: null,
        isConnected: false,
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// 检查是否在 WiFi 白名单内
  bool checkWhitelist(List<String> whitelist) {
    if (state.currentWiFi == null || whitelist.isEmpty) {
      state = state.copyWith(isInWhitelist: false);
      return false;
    }
    final ssid = state.currentWiFi!.ssid;
    final result = whitelist.contains(ssid);
    state = state.copyWith(isInWhitelist: result);
    return result;
  }
}

/// WiFi 服务 Provider
final wifiProvider =
    StateNotifierProvider<WiFiNotifier, WiFiState>((ref) {
  return WiFiNotifier();
});
