import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 지도 탭 화면.
///
/// 1) 지도를 터치하면 해당 위치에 핀(마커)이 찍히고 위도·경도가 추출됩니다.
/// 2) 우측 하단의 현위치 버튼을 누르면 GPS로 현재 위치를 가져와 그 위치로 이동합니다.
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  bool _isLocating = false;

  // 선택한 위치의 위도·경도를 저장하는 변수
  LatLng? _selectedLocation;

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
          minMaxZoomPreference: const MinMaxZoomPreference(5, 20),
          myLocationEnabled: true, // 지도 위에 파란 점으로 내 위치 표시
          myLocationButtonEnabled: false, // 기본 제공 버튼 대신 아래 커스텀 버튼 사용
          onMapCreated: (controller) => _mapController = controller,

          // 1. 지도를 터치(클릭)했을 때 동작
          onTap: (LatLng location) {
            setState(() {
              _selectedLocation = location;
            });

            // 콘솔창에서 추출된 위도, 경도 확인 가능!
            print("선택된 위도(latitude): ${location.latitude}");
            print("선택된 경도(longitude): ${location.longitude}");

            // TODO: 상품 등록 화면이나 백엔드 API 요청 시
            // location.latitude 와 location.longitude 값을 사용하시면 됩니다.
          },

          // 2. 터치한 위치에 마커(핀) 띄우기
          markers: _selectedLocation == null
              ? {}
              : {
                  Marker(
                    markerId: const MarkerId('selected_location'),
                    position: _selectedLocation!,
                    infoWindow: InfoWindow(
                      title: '선택한 위치',
                      snippet:
                          '${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                    ),
                  ),
                },
        ),

        // 우측 하단 현위치 버튼
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