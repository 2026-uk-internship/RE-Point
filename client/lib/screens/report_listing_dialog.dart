import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';

/// 채팅방 메뉴의 "Report User" (혹은 게시물/채팅방 신고)를 누르면 뜨는 다이얼로그.
///
/// 사용 예:
///   final reasons = await showReportListingDialog(context);
///   if (reasons != null) {
///     // TODO: 선택된 reasons로 신고 API 호출
///   }
/// reasons == null 이면 사용자가 Cancel을 누르거나 다이얼로그 바깥을 탭해서 닫은 것입니다.
Future<List<String>?> showReportListingDialog(BuildContext context) {
  return showDialog<List<String>>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (context) => const _ReportListingDialog(),
  );
}

class _ReportListingDialog extends StatefulWidget {
  const _ReportListingDialog();

  @override
  State<_ReportListingDialog> createState() => _ReportListingDialogState();
}

class _ReportListingDialogState extends State<_ReportListingDialog> {
  static const int _maxReasons = 2;

  static const List<String> _reasonOptions = [
    'Harassment or Sexual Harassment',
    'Abusive or Offensive Language',
    'Spam or Scam',
    'Fake Listing',
    'Prohibited Item',
    'Counterfeit Item',
    'Threats or Intimidation',
  ];

  final Set<String> _selectedReasons = {};

  void _toggleReason(String reason) {
    setState(() {
      if (_selectedReasons.contains(reason)) {
        _selectedReasons.remove(reason);
      } else if (_selectedReasons.length < _maxReasons) {
        _selectedReasons.add(reason);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          color: ChatColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_rounded, color: ChatColors.accentYellow, size: 64),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ChatColors.accentYellow, width: 1.4),
              ),
              child: const Column(
                children: [
                  Text(
                    'Report this listing?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Help us keep the community safe\nOur team will review this report.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ChatColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select up to $_maxReasons reasons.',
              style: const TextStyle(color: ChatColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ..._reasonOptions.map(_reasonRow),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _cancelButton()),
                const SizedBox(width: 12),
                Expanded(child: _reportButton()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _reasonRow(String reason) {
    final isSelected = _selectedReasons.contains(reason);
    // 이미 2개를 골랐고 이 항목은 선택 안 된 상태라면 비활성화 처리
    final isDisabled = !isSelected && _selectedReasons.length >= _maxReasons;

    return InkWell(
      onTap: isDisabled ? null : () => _toggleReason(reason),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: isSelected,
                onChanged: isDisabled ? null : (_) => _toggleReason(reason),
                checkColor: const Color(0xFF241A3D),
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return ChatColors.accentYellow;
                  }
                  return Colors.transparent;
                }),
                side: BorderSide(
                  color: isDisabled ? Colors.white24 : Colors.white54,
                  width: 1.4,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                reason,
                style: TextStyle(
                  color: isDisabled ? Colors.white38 : Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cancelButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.18),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      onPressed: () => Navigator.pop(context),
      child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    );
  }

  Widget _reportButton() {
    final hasSelection = _selectedReasons.isNotEmpty;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: ChatColors.danger,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        disabledBackgroundColor: ChatColors.danger.withOpacity(0.4),
      ),
      onPressed: hasSelection ? () => Navigator.pop(context, _selectedReasons.toList()) : null,
      child: const Text('Report', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    );
  }
}