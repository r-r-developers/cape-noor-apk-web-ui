import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

class DuasScreen extends ConsumerWidget {
  const DuasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(duaCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Duas & Dhikr')),
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Unable to load duas: $e', style: const TextStyle(color: AppTheme.error)),
        ),
        data: (categories) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: categories.length,
          itemBuilder: (_, i) {
            final cat = categories[i];
            return _CategoryCard(
              nameEn: cat.nameEn,
              nameAr: cat.nameAr,
              icon: cat.icon,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _DuasListScreen(categoryId: cat.id, category: cat.nameEn),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class DuaCategory {
  final int id;
  final String nameAr;
  final String nameEn;
  final String icon;

  const DuaCategory({required this.id, required this.nameAr, required this.nameEn, required this.icon});

  factory DuaCategory.fromJson(Map<String, dynamic> json) => DuaCategory(
    id: json['id'] as int,
    nameAr: json['name_ar'] as String? ?? '',
    nameEn: json['name_en'] as String? ?? '',
    icon: json['icon'] as String? ?? 'auto_awesome',
  );
}

final duaCategoriesProvider = FutureProvider<List<DuaCategory>>((ref) async {
  final response = await ApiClient.dio.get('/duas/categories');
  final list = (response.data['categories'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
  return list.map(DuaCategory.fromJson).toList();
});

final duasByCategoryProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, categoryId) async {
  final response = await ApiClient.dio.get('/duas/categories/$categoryId');
  final list = (response.data['duas'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
  return list;
});

class _CategoryCard extends StatelessWidget {
  final String nameEn;
  final String nameAr;
  final String icon;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.nameEn,
    required this.nameAr,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: AppTheme.gold, size: 32),
          const SizedBox(height: 8),
          Text(nameEn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          Text(nameAr, style: const TextStyle(fontFamily: 'Amiri', fontSize: 14, color: AppTheme.gold)),
        ],
      ),
    ),
  );
}

class _DuasListScreen extends ConsumerWidget {
  final int categoryId;
  final String category;

  const _DuasListScreen({required this.categoryId, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duasAsync = ref.watch(duasByCategoryProvider(categoryId));
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: duasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Unable to load duas: $e', style: const TextStyle(color: AppTheme.error)),
        ),
        data: (duas) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: duas.length,
          itemBuilder: (_, i) => _DuaCard(dua: duas[i]),
        ),
      ),
    );
  }
}

class _DuaCard extends StatefulWidget {
  final Map<String, dynamic> dua;

  const _DuaCard({required this.dua});

  @override
  State<_DuaCard> createState() => _DuaCardState();
}

class _DuaCardState extends State<_DuaCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final dua = widget.dua;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Arabic text (always visible)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (dua['title_en'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(dua['title_en'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.gold)),
                  ),
                Text(
                  dua['arabic'] as String? ?? '',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'Amiri', fontSize: 22, height: 1.8, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),

          // Expand for transliteration + translation
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dua['transliteration'] != null) ...[
                    Text(dua['transliteration'] as String,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 12),
                  ],
                  Text(dua['translation'] as String? ?? '',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.6)),
                  if (dua['reference'] != null) ...[
                    const SizedBox(height: 8),
                    Text('— ${dua['reference']}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ],
              ),
            ),
          ],

          // Expand/collapse row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18),
                label: Text(_expanded ? 'Less' : 'Translation'),
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(foregroundColor: AppTheme.green),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 18),
                onPressed: () => _share(dua),
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _share(Map<String, dynamic> dua) {
    // share_plus integration would go here
    final text = '${dua['arabic']}\n\n${dua['translation']}\n\n(${dua['reference'] ?? ''})';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dua copied to clipboard')),
    );
  }
}
