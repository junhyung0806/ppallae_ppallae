import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/models/api_models.dart';
import '../../api/ppallae_api_client.dart';

class RegionSearchScreen extends StatefulWidget {
  const RegionSearchScreen({super.key, required this.apiClient});

  final PpallaeApiClient apiClient;

  @override
  State<RegionSearchScreen> createState() => _RegionSearchScreenState();
}

class _RegionSearchScreenState extends State<RegionSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<RegionModel> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(value.trim());
    });
  }

  Future<void> _search(String keyword) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.apiClient.searchRegions(keyword);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '검색 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('지역 검색')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: '시/군/구/동 이름 입력 (예: 강남, 부산)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final region = _results[index];
                return ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(region.displayName),
                  subtitle: Text('격자 (${region.nx}, ${region.ny})'),
                  onTap: () => Navigator.of(context).pop(region),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
