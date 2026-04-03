import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';

class MosqueSummary {
  final String id;
  final String slug;
  final String name;
  final String? area;
  final String? logoUrl;

  const MosqueSummary({
    required this.id,
    required this.slug,
    required this.name,
    this.area,
    this.logoUrl,
  });

  factory MosqueSummary.fromJson(Map<String, dynamic> json) => MosqueSummary(
    id:      (json['id'] ?? '').toString(),
    slug:    json['slug'] as String? ?? '',
    name:    json['name'] as String,
    area:    json['area'] as String?,
    logoUrl: json['logo_url'] as String?,
  );
}

class MosqueDetail {
  final String id;
  final String slug;
  final String name;
  final String? area;
  final String? logoUrl;
  final String? phone;
  final String? email;
  final String? website;
  final String? announcement;
  final String? fajr;
  final String? thuhr;
  final String? asr;
  final String? maghrib;
  final String? isha;

  const MosqueDetail({
    required this.id,
    required this.slug,
    required this.name,
    this.area,
    this.logoUrl,
    this.phone,
    this.email,
    this.website,
    this.announcement,
    this.fajr,
    this.thuhr,
    this.asr,
    this.maghrib,
    this.isha,
  });

  factory MosqueDetail.fromJson(Map<String, dynamic> json) {
    final m     = json['mosque'] as Map<String, dynamic>? ?? json;
    final times = json['today']  as Map<String, dynamic>?;
    return MosqueDetail(
      id:           (m['id'] ?? '').toString(),
      slug:         m['slug'] as String? ?? '',
      name:         m['name'] as String,
      area:         m['area'] as String?,
      logoUrl:      m['logo_url'] as String?,
      phone:        m['phone'] as String?,
      email:        m['email'] as String?,
      website:      m['website'] as String?,
      announcement: (m['announcements'] is List && (m['announcements'] as List).isNotEmpty)
                      ? (m['announcements'] as List).first.toString()
                      : m['announcement'] as String?,
      fajr:    times?['fajr']    as String?,
      thuhr:   times?['thuhr']   as String?,
      asr:     times?['asr']     as String?,
      maghrib: times?['maghrib'] as String?,
      isha:    times?['isha']    as String?,
    );
  }
}

// ── Providers ──────────────────────────────────────────────────────────────────

final mosquesProvider = FutureProvider<List<MosqueSummary>>((ref) async {
  final response = await ApiClient.dio.get('/mosques');
  final list     = response.data['mosques'] as List;
  return list.map((e) => MosqueSummary.fromJson(e as Map<String, dynamic>)).toList();
});

final mosqueDetailProvider = FutureProvider.family<MosqueDetail, String>((ref, slug) async {
  final response = await ApiClient.dio.get('/mosques/$slug');
  return MosqueDetail.fromJson(response.data as Map<String, dynamic>);
});
