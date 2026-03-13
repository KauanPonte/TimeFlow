import 'dart:convert';

import 'package:flutter_application_appdeponto/models/place_result.dart';
import 'package:http/http.dart' as http;

class AdminSettingsGeocodingService {
  static const _userAgent = 'TimeFlowApp/1.0 (timeflow@app)';

  Future<List<PlaceResult>> fetchSuggestions(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'limit': '6',
      'accept-language': 'pt-BR,pt',
      'addressdetails': '1',
    });

    final response = await http.get(uri, headers: {'User-Agent': _userAgent});
    if (response.statusCode != 200) {
      return const [];
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((item) => PlaceResult.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': lat.toString(),
        'lon': lng.toString(),
        'format': 'jsonv2',
        'accept-language': 'pt-BR,pt',
      });

      final response = await http.get(uri, headers: {'User-Agent': _userAgent});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final displayName = (data['display_name'] as String? ?? '').trim();
        if (displayName.isNotEmpty) {
          return displayName.split(', ').take(3).join(', ');
        }
      }
    } catch (_) {}

    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }
}
