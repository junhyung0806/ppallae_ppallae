import 'package:flutter/material.dart';

import '../../api/models/api_models.dart';
import '../../api/ppallae_api_client.dart';

/// 활성 공지 목록 + 상세 (백엔드 admin 콘솔에서 발행).
class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key, required this.apiClient});

  final PpallaeApiClient apiClient;

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  late Future<List<NoticeModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.apiClient.activeNotices();
  }

  Future<void> _reload() async {
    setState(() {
      _future = widget.apiClient.activeNotices();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('공지사항'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<NoticeModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  const Center(child: Icon(Icons.cloud_off, size: 40)),
                  const SizedBox(height: 12),
                  Text(
                    '공지를 불러오지 못했어요\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              );
            }
            final list = snapshot.data ?? const [];
            if (list.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Center(
                    child: Text(
                      '현재 공지가 없어요',
                      style: TextStyle(color: Colors.black45),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _NoticeTile(notice: list[i]),
            );
          },
        ),
      ),
    );
  }
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({required this.notice});
  final NoticeModel notice;

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '${local.year}.$m.$d';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: notice.isImportant
          ? const Icon(Icons.campaign, color: Color(0xFFD23B3B))
          : const Icon(Icons.notifications_none, color: Color(0xFF3A7BD5)),
      title: Text(
        notice.title,
        style: TextStyle(
          fontWeight: notice.isImportant ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      subtitle: Text(_formatDate(notice.createdAt)),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scroll) => SingleChildScrollView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (notice.isImportant)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE5E5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '중요',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFD23B3B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        notice.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(notice.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
                const SizedBox(height: 14),
                Text(
                  notice.content,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
