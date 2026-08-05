import 'package:flutter/material.dart';
import 'api_service.dart';

class ApiTestScreen extends StatefulWidget {
  @override
  _ApiTestScreenState createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  // 화면에 보여줄 데이터를 담을 변수
  String _resultText = "버튼을 눌러 API를 테스트해보세요!";

  // 실시간 채팅 소켓 변수
  final ChatSocketService _chatSocket = ChatSocketService();

  // ------------------------------------------------------
  // 1. 로그인 테스트 (토큰 자동 저장)
  // ------------------------------------------------------
  Future<void> _testLogin() async {
    try {
      // 1) 함수 호출
      final res = await AuthService.login('test@test.com', '1234');

      // 2) 결과 처리
      setState(() {
        if (res['token'] != null) {
          _resultText = "로그인 성공! 토큰 저장됨.\n내 정보: ${res['data']}";
        } else {
          _resultText = "로그인 실패: $res";
        }
      });
    } catch (e) {
      setState(() => _resultText = "에러 발생: $e");
    }
  }

  // ------------------------------------------------------
  // 2. 상품 목록 불러오기 테스트
  // ------------------------------------------------------
  Future<void> _testFetchProducts() async {
    try {
      // 일반(general) 상품 최신순으로 가져오기
      final res = await ProductService.getProductList(
        'general',
        sort: 'newest',
      );

      setState(() {
        // 서버 응답 구조(예: res['data'])에 맞게 데이터 추출
        List products = res['data'] ?? [];
        _resultText =
            "상품 ${products.length}개를 불러왔습니다!\n첫번째 상품: ${products.isNotEmpty ? products[0] : '없음'}";
      });
    } catch (e) {
      setState(() => _resultText = "에러 발생: $e");
    }
  }

  // ------------------------------------------------------
  // 3. 채팅 소켓 연결 테스트
  // ------------------------------------------------------
  void _testConnectChat() {
    if (ApiConfig.token == null) {
      setState(() => _resultText = "로그인을 먼저 해주세요 (토큰 없음)");
      return;
    }

    _chatSocket.connect(
      onRoomInfo: (data) => print("방 정보 도착: $data"),
      onChatHistory: (data) => print("이전 채팅 내역: $data"),
      onReceiveMessage: (data) => print("새 메시지 도착: $data"),
      onUserTyping: (data) => print("상대방이 입력 중..."),
      onUserStopTyping: (data) => print("상대방 입력 멈춤"),
    );

    setState(() {
      _resultText = "채팅 서버 연결 시도 중! (콘솔 로그 확인)";
    });
  }

  // ------------------------------------------------------
  // 위젯 종료 시 채팅 소켓 닫기
  // ------------------------------------------------------
  @override
  void dispose() {
    _chatSocket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("API 사용 예시")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // API 테스트 버튼들
            ElevatedButton(
              onPressed: _testLogin,
              child: Text("1. 로그인 (토큰 발급)"),
            ),
            ElevatedButton(
              onPressed: _testFetchProducts,
              child: Text("2. 일반 상품 목록 불러오기"),
            ),
            ElevatedButton(
              onPressed: _testConnectChat,
              child: Text("3. 채팅 서버 접속하기"),
            ),

            SizedBox(height: 20),

            // 결과 출력창
            Text(
              "결과 화면:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(12),
                color: Colors.grey[200],
                child: SingleChildScrollView(child: Text(_resultText)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
