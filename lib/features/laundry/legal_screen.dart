import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/models/api_models.dart';

/// 정책 / 약관 / 위치기반서비스 / 오픈소스 / 문의 링크 허브.
///
/// 백엔드 `/app-config/public` 응답의 URL을 우선 사용하고, 비어 있을 때만
/// [_LegalUrls] 의 placeholder URL 로 폴백한다.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, this.appConfig});

  /// 동적 URL 소스. null 이면 전부 로컬 fallback.
  final AppConfigModel? appConfig;

  /// `appConfig.urls` 의 값이 비어있지 않으면 그걸, 아니면 [fallback] 사용.
  String _pickUrl(String Function(AppUrlsModel u) pick, String fallback) {
    final config = appConfig;
    if (config == null) return fallback;
    final v = pick(config.urls);
    return v.isNotEmpty ? v : fallback;
  }

  /// 문의는 백엔드의 customerCenter 우선, 없으면 support, 둘 다 없으면 로컬.
  String _resolvedContact() {
    final config = appConfig;
    if (config != null) {
      if (config.urls.customerCenter.isNotEmpty) {
        return config.urls.customerCenter;
      }
      if (config.urls.support.isNotEmpty) return config.urls.support;
    }
    return _LegalUrls.contactForm;
  }

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아직 준비 중인 링크예요.')),
      );
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없어요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('정책 · 약관 · 문의'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const _SectionHeader('정책'),
          _LinkTile(
            icon: Icons.privacy_tip_outlined,
            title: '개인정보처리방침',
            url: _pickUrl((u) => u.privacyPolicy, _LegalUrls.privacyPolicy),
            onTap: _open,
          ),
          _LinkTile(
            icon: Icons.description_outlined,
            title: '서비스 이용약관',
            url: _pickUrl((u) => u.terms, _LegalUrls.termsOfService),
            onTap: _open,
          ),
          _LinkTile(
            icon: Icons.location_on_outlined,
            title: '위치기반서비스 이용약관',
            url: _pickUrl((u) => u.locationTerms, _LegalUrls.locationTerms),
            onTap: _open,
          ),
          const Divider(),
          const _SectionHeader('지원'),
          _LinkTile(
            icon: Icons.feedback_outlined,
            title: '문의하기 (Google Form)',
            subtitle: _resolvedContact().isEmpty
                ? '아직 등록 전 — 곧 활성화'
                : null,
            url: _resolvedContact(),
            onTap: _open,
          ),
          ListTile(
            leading: const Icon(Icons.code_outlined),
            title: const Text('오픈소스 라이선스'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: '빨래빨래',
              applicationLegalese: '© ppallae',
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// TODO(release): privacyPolicy / termsOfService / locationTerms 는 운영 도메인의
/// 실제 페이지로 교체. contactForm 은 운영 중인 Google Form (수정 시 동일 위치).
class _LegalUrls {
  static const String privacyPolicy = 'https://ppallae.app/privacy';
  static const String termsOfService = 'https://ppallae.app/terms';
  static const String locationTerms = 'https://ppallae.app/location-terms';
  static const String contactForm = 'https://forms.gle/F3Z2prSBHTorcB6W9';
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF3A7BD5),
          fontSize: 14,
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.url,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String url;
  final String? subtitle;
  final Future<void> Function(BuildContext, String) onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 12))
          : null,
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => onTap(context, url),
    );
  }
}
