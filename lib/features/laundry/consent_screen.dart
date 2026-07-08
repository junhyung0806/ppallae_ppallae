import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/error_codes.dart';
import 'laundry_prefs.dart';

/// 첫 실행 약관·개인정보·위치 동의 화면.
///
/// 위치 수집 앱은 데이터 수집 전에 사용자 동의를 받아야 한다(위치정보법·개인정보보호법).
/// 여기서 동의를 받고 [kConsentVersionKey] 에 현재 버전을 저장한 뒤에야
/// 앱 본체(위치 접근 포함)가 시작된다. 이후 실행은 동의가 이미 있으면 스킵.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key, required this.onAgreed});

  /// 동의 완료 후 앱을 시작시키는 콜백 (shell 이 컨트롤러를 initialize).
  final VoidCallback onAgreed;

  /// 저장된 동의 버전이 현재 버전 이상이면 true (동의 완료).
  static Future<bool> hasConsented() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getInt(kConsentVersionKey) ?? 0;
      return v >= kCurrentConsentVersion;
    } catch (e) {
      // 읽기 실패 시 안전하게 "미동의"로 취급 (동의 화면을 다시 보여줌).
      PpallaeError(ErrorCodes.prfRead, '동의 상태를 확인하지 못했어요.', e.toString()).log();
      return false;
    }
  }

  static Future<void> _markConsented() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kConsentVersionKey, kCurrentConsentVersion);
  }

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  // 전문 URL — 운영 도메인 호스팅 후 실제 페이지로 연결됨(현재는 placeholder).
  static const _termsUrl = 'https://ppallae.app/terms';
  static const _privacyUrl = 'https://ppallae.app/privacy';
  static const _locationUrl = 'https://ppallae.app/location-terms';

  bool _agreeService = false;
  bool _agreePrivacy = false;
  bool _agreeLocation = false;
  bool _submitting = false;

  bool get _allRequiredAgreed =>
      _agreeService && _agreePrivacy && _agreeLocation;

  void _setAll(bool v) {
    setState(() {
      _agreeService = v;
      _agreePrivacy = v;
      _agreeLocation = v;
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      final ok =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('약관 전문은 곧 제공됩니다.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('약관 전문은 곧 제공됩니다.')),
        );
      }
    }
  }

  Future<void> _agreeAndStart() async {
    if (!_allRequiredAgreed || _submitting) return;
    setState(() => _submitting = true);
    try {
      await ConsentScreen._markConsented();
    } catch (e) {
      PpallaeError(ErrorCodes.prfWrite, '동의 저장에 실패했어요.', e.toString()).log();
      // 저장 실패해도 진행은 시킨다(다음 실행에 다시 물어봄). 사용자 흐름 우선.
    }
    if (mounted) widget.onAgreed();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF3A7BD5);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                children: [
                  const Text('빨래빨래 시작하기',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text(
                    '정확한 빨래 지수를 위해 아래 항목에 동의가 필요해요.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF5A6472)),
                  ),
                  const SizedBox(height: 20),
                  _DisclosureCard(),
                  const SizedBox(height: 20),
                  // 전체 동의
                  _AgreeTile(
                    value: _allRequiredAgreed,
                    onChanged: (v) => _setAll(v ?? false),
                    title: '전체 동의',
                    bold: true,
                  ),
                  const Divider(height: 8),
                  _AgreeTile(
                    value: _agreeService,
                    onChanged: (v) => setState(() => _agreeService = v ?? false),
                    title: '[필수] 서비스 이용약관',
                    onView: () => _openUrl(_termsUrl),
                  ),
                  _AgreeTile(
                    value: _agreePrivacy,
                    onChanged: (v) => setState(() => _agreePrivacy = v ?? false),
                    title: '[필수] 개인정보 수집·이용 동의',
                    onView: () => _openUrl(_privacyUrl),
                  ),
                  _AgreeTile(
                    value: _agreeLocation,
                    onChanged: (v) =>
                        setState(() => _agreeLocation = v ?? false),
                    title: '[필수] 위치기반서비스 이용약관',
                    onView: () => _openUrl(_locationUrl),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed:
                      _allRequiredAgreed && !_submitting ? _agreeAndStart : null,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('동의하고 시작',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 무엇을·왜·어떻게 처리하는지 인라인 고지 (동의의 실질적 근거).
class _DisclosureCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6ECF3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DisclosureRow(
            icon: Icons.my_location_outlined,
            title: '현재 위치',
            body: '내 지역의 날씨로 빨래 지수를 계산하는 데 사용해요. '
                '좌표는 지역(동) 변환에만 쓰고 서버에 저장하지 않아요.',
          ),
          SizedBox(height: 12),
          _DisclosureRow(
            icon: Icons.mail_outline,
            title: '문의 이메일 (선택)',
            body: '문의하실 때만 선택 입력하며, 답변을 위해서만 사용해요.',
          ),
          SizedBox(height: 12),
          _DisclosureRow(
            icon: Icons.shield_outlined,
            title: '그 외',
            body: '이름·연락처 등 다른 개인정보는 수집하지 않아요.',
          ),
        ],
      ),
    );
  }
}

class _DisclosureRow extends StatelessWidget {
  const _DisclosureRow(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF3A7BD5)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(body,
                  style: const TextStyle(
                      fontSize: 13, height: 1.45, color: Color(0xFF5A6472))),
            ],
          ),
        ),
      ],
    );
  }
}

class _AgreeTile extends StatelessWidget {
  const _AgreeTile({
    required this.value,
    required this.onChanged,
    required this.title,
    this.onView,
    this.bold = false,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String title;
  final VoidCallback? onView;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF3A7BD5),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Text(
              title,
              style: TextStyle(
                fontSize: bold ? 16 : 14,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ),
        if (onView != null)
          TextButton(
            onPressed: onView,
            child: const Text('보기', style: TextStyle(fontSize: 13)),
          ),
      ],
    );
  }
}
