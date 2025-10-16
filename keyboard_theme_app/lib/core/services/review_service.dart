import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';

class ReviewService {
  static const String _keyDownloadCount = 'download_count';
  static const String _keyAppLaunchCount = 'app_launch_count';
  static const String _keyReviewRequested = 'review_requested';
  static const String _keyLastReviewRequestTime = 'last_review_request_time';

  // Review trigger thresholds
  static const int _downloadThreshold = 10; // 10번째 다운로드
  static const int _appLaunchThreshold = 5; // 5회 이상 실행

  // Minimum time between review requests (7 days in milliseconds)
  static const int _minTimeBetweenRequests = 7 * 24 * 60 * 60 * 1000;

  final InAppReview _inAppReview = InAppReview.instance;

  /// 다운로드 횟수 증가 및 리뷰 요청 체크
  Future<void> incrementDownloadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_keyDownloadCount) ?? 0) + 1;
    await prefs.setInt(_keyDownloadCount, count);

    print('Download count: $count');

    // 10번째 다운로드 시 리뷰 요청
    if (count == _downloadThreshold) {
      await _checkAndRequestReview();
    }
  }

  /// 앱 실행 횟수 증가 및 리뷰 요청 체크
  Future<void> incrementAppLaunchCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_keyAppLaunchCount) ?? 0) + 1;
    await prefs.setInt(_keyAppLaunchCount, count);

    print('App launch count: $count');

    // 5회 이상 실행 후 리뷰 요청
    if (count >= _appLaunchThreshold) {
      await _checkAndRequestReview();
    }
  }

  /// 리뷰 요청 가능 여부 체크 및 요청
  Future<void> _checkAndRequestReview() async {
    try {
      // 리뷰 기능 사용 가능 여부 확인
      final isAvailable = await _inAppReview.isAvailable();
      if (!isAvailable) {
        print('In-app review is not available on this device');
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      // 마지막 리뷰 요청 시간 확인
      final lastRequestTime = prefs.getInt(_keyLastReviewRequestTime) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // 최소 대기 시간이 지나지 않았으면 요청하지 않음
      if (currentTime - lastRequestTime < _minTimeBetweenRequests) {
        print('Too soon to request review again');
        return;
      }

      // 리뷰 요청
      print('Requesting in-app review...');
      await _inAppReview.requestReview();

      // 마지막 요청 시간 업데이트
      await prefs.setInt(_keyLastReviewRequestTime, currentTime);
      await prefs.setBool(_keyReviewRequested, true);

      print('Review requested successfully');
    } catch (e) {
      print('Error requesting review: $e');
    }
  }

  /// 통계 정보 가져오기 (디버깅용)
  Future<Map<String, int>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'downloadCount': prefs.getInt(_keyDownloadCount) ?? 0,
      'appLaunchCount': prefs.getInt(_keyAppLaunchCount) ?? 0,
    };
  }

  /// 통계 초기화 (테스트용)
  Future<void> resetStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDownloadCount);
    await prefs.remove(_keyAppLaunchCount);
    await prefs.remove(_keyReviewRequested);
    await prefs.remove(_keyLastReviewRequestTime);
    print('Review stats reset');
  }
}
