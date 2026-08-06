import 'api_service.dart';
import 'package:flutter/foundation.dart';

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
      // 실제 서버 응답 구조를 콘솔에서 확인하기 위한 디버그 로그.
      // username/location/point 필드명이 아래와 다르면 이 로그로 확인해서
      // 아래 파싱 부분의 키 이름만 맞춰주면 됩니다.
      debugPrint('🔍 [Profile] 응답: $res');

      final data = (res['data'] is Map<String, dynamic>)
          ? res['data'] as Map<String, dynamic>
          : res;
      // 일부 API는 유저 정보를 한 단계 더 감싸서 내려주기도 해서
      // (예: { data: { user: {...} } }) 그 경우도 같이 확인.
      final user = (data['user'] is Map<String, dynamic>)
          ? data['user'] as Map<String, dynamic>
          : data;

      // ⚠️ 현재 /users/me 응답에는 id 필드가 없음 (name, img, temperature,
      // totalPoint 등만 내려줌). id는 AuthService.login()이 로그인 응답의
      // data.id로 이미 채워둔 상태이므로, 여기서는 응답에 id가 "있을 때만"
      // 갱신하고 없으면 기존 값을 그대로 유지합니다. (없다고 null로 덮어쓰면
      // 로그인 때 채워둔 값이 날아가서 채팅 isMe 판별이 깨짐)
      final parsedId = user['id'] is int
          ? user['id'] as int
          : int.tryParse('${user['id']}');
      if (parsedId != null) {
        id = parsedId;
      }

      username =
          user['username']?.toString() ??
          user['nickname']?.toString() ??
          user['name']?.toString();
      email = user['email']?.toString();
      final rawLocation = user['location'] ?? user['locationName'];
      location = (rawLocation is Map)
          ? (rawLocation['name'] ?? rawLocation['location'])?.toString()
          : rawLocation?.toString();
      final pointValue =
          user['point'] ?? user['points'] ?? user['availablePoint'];
      points = pointValue is int ? pointValue : int.tryParse('$pointValue');
      avatarUrl =
          user['profileImage']?.toString() ??
          user['avatarUrl']?.toString() ??
          user['profile_image']?.toString() ??
          user['img']?.toString();

      debugPrint(
        '🔍 [Profile] 파싱 결과 -> id: $id, username: $username, '
        'location: $location, points: $points',
      );
    } catch (e) {
      // 프로필 조회 실패 원인을 콘솔에서 확인할 수 있도록 로그만 남기고,
      // 화면에는 기본값(더미)으로 표시되도록 조용히 무시합니다.
      debugPrint('🔍 [Profile] 조회 실패: $e');
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
