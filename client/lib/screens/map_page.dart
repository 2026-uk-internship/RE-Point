import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 지도 탭 화면.
///
/// 우측 하단의 현위치 버튼을 누르면 GPS로 현재 위치를 가져와
/// 그 위치로 카메라를 이동시킵니다.
///
/// 사용 전 준비물:
/// 1) pubspec.yaml에 geolocator 패키지 추가
///    dependencies:
///      geolocator: ^12.0.0
/// 2) Android: android/app/src/main/AndroidManifest.xml <manifest> 안에 추가
///    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
///    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
/// 3) iOS: ios/Runner/Info.plist에 추가
///    <key>NSLocationWhenInUseUsageDescription</key>
///    <string>주변 경매/중고 물품을 보여주기 위해 위치 권한이 필요합니다.</string>
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  bool _isLocating = false;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(51.5074, -0.1278), // London, UK
    zoom: 12,
  );

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _initialPosition,
          // 너무 축소하면 에뮬레이터에서 타일 렌더링이 깨지는 경우가 있어
          // 최소 줌 레벨을 제한해서 문제 구간 자체를 피합니다.
          minMaxZoomPreference: const MinMaxZoomPreference(5, 20),
          myLocationEnabled: true, // 지도 위에 파란 점으로 내 위치 표시
          myLocationButtonEnabled: false, // 기본 제공 버튼 대신 아래 커스텀 버튼 사용
          onMapCreated: (controller) => _mapController = controller,
        ),
        Positioned(
          right: 16,
          bottom: 110, // 하단 네비게이션 바와 안 겹치도록 여유를 둠
          child: _buildLocationButton(),
        ),
      ],
    );
  }

  Widget _buildLocationButton() {
    return GestureDetector(
      onTap: _goToCurrentLocation,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: _isLocating
            ? const Padding(
                padding: EdgeInsets.all(13),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF241A3D),
                ),
              )
            : const Icon(
                Icons.my_location_rounded,
                color: Color(0xFF241A3D),
                size: 22,
              ),
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      final position = await _determinePosition();
      final target = LatLng(position.latitude, position.longitude);
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 16),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('현재 위치를 가져오지 못했어요: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  /// 위치 서비스 활성화 여부와 권한을 확인한 뒤 현재 위치를 반환합니다.
  /// TODO: 실제 앱에서는 권한이 영구 거부됐을 때 설정 화면으로 안내하는
  /// 다이얼로그(Geolocator.openAppSettings() 등)를 추가하면 사용성이 좋아집니다.
  Future<Position> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('위치 서비스가 꺼져 있어요');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('위치 권한이 거부됐어요');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('위치 권한이 영구적으로 거부됐어요. 설정에서 허용해주세요');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
