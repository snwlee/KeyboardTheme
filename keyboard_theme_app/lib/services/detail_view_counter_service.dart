import 'package:shared_preferences/shared_preferences.dart';

class DetailViewCounterService {
  static const String _viewCountKey = 'detail_view_count';

  static Future<bool> shouldShowAd() async {
    final prefs = await SharedPreferences.getInstance();

    // 현재 조회 횟수 가져오기
    int viewCount = prefs.getInt(_viewCountKey) ?? 0;

    // 조회 횟수 증가
    viewCount++;
    await prefs.setInt(_viewCountKey, viewCount);

    // 3의 배수일 때 광고 표시
    if (viewCount > 0 && viewCount % 3 == 0) {
      return true;
    }

    return false;
  }

  // 디버깅용: 현재 상태 확인
  static Future<Map<String, int>> getCurrentState() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'viewCount': prefs.getInt(_viewCountKey) ?? 0,
      'threshold': 3, // Threshold is now fixed at 3
    };
  }

  // 디버깅용: 카운터 리셋
  static Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_viewCountKey);
  }
}
