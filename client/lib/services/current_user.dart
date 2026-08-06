import 'api_service.dart';

/// 로그인 이후 채워지는 내 프로필 캐시.
///
/// ProfileService.getMyProfile()을 매 화면마다 다시 호출하지 않도록
/// 로그인 직후(또는 필요할 때) 한 번 채워두고 여러 화면에서 재사용합니다.
/// 서버 응답 필드명이 실제와 다르면 refresh() 안의 키 이름만 맞춰주면 됩니다.
class CurrentUser {
  CurrentUser._();

  static int? id;
  static String? username;
  static String? email;
  static String? location;
  static int? points;
  static String? avatarUrl;

  static bool get isLoaded => id != null;

  /// 로그인 직후 또는 화면 진입 시 호출해서 프로필을 채웁니다.
  static Future<void> refresh() async {
    try {
      final res = await ProfileService.getMyProfile();
      final data = (res['data'] is Map<String, dynamic>)
          ? res['data'] as Map<String, dynamic>
          : res;

      id = data['id'] is int ? data['id'] as int : int.tryParse('${data['id']}');
      username = data['username']?.toString();
      email = data['email']?.toString();
      location = data['location']?.toString() ?? data['locationName']?.toString();
      final pointValue = data['point'] ?? data['points'];
      points = pointValue is int ? pointValue : int.tryParse('$pointValue');
      avatarUrl = data['profileImage']?.toString() ?? data['avatarUrl']?.toString();
    } catch (e) {
      // 프로필 조회 실패는 각 화면에서 기본값(더미)으로 표시되도록 조용히 무시합니다.
    }
  }

  static void clear() {
    id = null;
    username = null;
    email = null;
    location = null;
    points = null;
    avatarUrl = null;
  }
}