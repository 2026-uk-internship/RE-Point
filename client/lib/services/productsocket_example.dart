import 'package:flutter/material.dart';
import 'api_service.dart';

class ProductSocketExampleScreen extends StatefulWidget {
  final int productId;

  const ProductSocketExampleScreen({
    Key? key,
    this.productId = 5, // 테스트용 기본 상품 ID
  }) : super(key: key);

  @override
  _ProductSocketExampleScreenState createState() =>
      _ProductSocketExampleScreenState();
}

class _ProductSocketExampleScreenState
    extends State<ProductSocketExampleScreen> {
  final ProductSocketService _productSocketService = ProductSocketService();

  int _viewerCount = 0;
  List<dynamic> _viewers = [];

  @override
  void initState() {
    super.initState();
    _connectAndJoinRoom();
  }

  void _connectAndJoinRoom() {
    // 1. 소켓 서버 연결
    _productSocketService.connect();

    // 2. 실시간 시청자 정보 수신 리스너 등록
    _productSocketService.onProductViewersUpdated((data) {
      if (mounted) {
        setState(() {
          _viewerCount = data['count'] ?? 0;
          _viewers = data['viewers'] ?? [];
        });
      }
    });

    // 3. 해당 상품 방 입장 (테스트용 유저 정보 전송)
    _productSocketService.joinProduct(
      productId: widget.productId,
      userId: 1, // 테스트 유저 ID (실제 개발 시 내 유저 ID 연동)
      userName: "플러터 사용자",
    );
  }

  @override
  void dispose() {
    // 4. 화면 이탈 시 이벤트 해제 및 소켓 정리
    _productSocketService.leaveProduct(widget.productId);
    _productSocketService.offProductViewersUpdated();
    _productSocketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('상품 상세 (${widget.productId}번)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 실시간 시청자 수 배너
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.remove_red_eye, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '지금 $_viewerCount명이 이 상품을 보는 중입니다.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 현재 접속 중인 유저 목록
            const Text(
              '실시간 시청자 목록:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _viewers.isEmpty
                  ? const Center(child: Text('시청자가 없습니다.'))
                  : ListView.builder(
                      itemCount: _viewers.length,
                      itemBuilder: (context, index) {
                        final viewer = _viewers[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(viewer['userName'] ?? '익명'),
                          subtitle: Text('ID: ${viewer['userId']}'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
