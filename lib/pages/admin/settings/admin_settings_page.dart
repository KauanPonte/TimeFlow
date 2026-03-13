import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/models/place_result.dart';
import 'package:flutter_application_appdeponto/pages/admin/settings/widgets/settings_bottom_card.dart';
import 'package:flutter_application_appdeponto/pages/admin/settings/widgets/settings_header_card.dart';
import 'package:flutter_application_appdeponto/pages/admin/settings/widgets/settings_map_card.dart';
import 'package:flutter_application_appdeponto/pages/admin/settings/widgets/settings_search_field.dart';
import 'package:flutter_application_appdeponto/pages/admin/settings/widgets/settings_suggestions_card.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// Settings Page

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  static const _defaultLat = -15.7801;
  static const _defaultLng = -47.9292;
  static const _defaultZoom = 5.2;
  static const _focusedZoom = 16.0;

  bool _loading = true;
  bool _saving = false;
  bool _capturingGps = false;
  bool _loadingSuggestions = false;
  bool _showSuggestions = false;

  double? _lat;
  double? _lng;
  String _address = '';

  late final MapController _mapController;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _firestore = FirebaseFirestore.instance;

  LatLng _center = const LatLng(_defaultLat, _defaultLng);
  List<PlaceResult> _suggestions = [];
  Timer? _debounce;

  bool get _hasSavedLocation => _lat != null && _lng != null;

  bool get _hasPendingChange {
    if (!_hasSavedLocation) {
      return true;
    }

    return (_lat! - _center.latitude).abs() > 0.00001 ||
        (_lng! - _center.longitude).abs() > 0.00001;
  }

  String get _coordinateLabel =>
      '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && mounted) {
        setState(() => _showSuggestions = false);
      }
    });
    _loadSettings();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await _firestore.collection('settings').doc('company').get();
      if (doc.exists) {
        final data = doc.data()!;
        final lat = (data['workplaceLat'] as num?)?.toDouble();
        final lng = (data['workplaceLng'] as num?)?.toDouble();
        _address = (data['workplaceName'] ?? '').toString();

        if (lat != null && lng != null) {
          _lat = lat;
          _lng = lng;
          _center = LatLng(lat, lng);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchSuggestions(value.trim());
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() => _loadingSuggestions = true);

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'jsonv2',
        'limit': '6',
        'accept-language': 'pt-BR,pt',
        'addressdetails': '1',
      });

      final response = await http.get(uri, headers: {
        'User-Agent': 'TimeFlowApp/1.0 (timeflow@app)',
      });

      if (!mounted || _searchController.text.trim() != query) {
        return;
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _suggestions = data
              .map((item) => PlaceResult.fromJson(item as Map<String, dynamic>))
              .toList();
          _showSuggestions = _suggestions.isNotEmpty;
        });
      }
    } catch (_) {
      if (mounted && _searchController.text.trim() == query) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
      }
    } finally {
      if (mounted && _searchController.text.trim() == query) {
        setState(() => _loadingSuggestions = false);
      }
    }
  }

  void _selectSuggestion(PlaceResult place) {
    FocusScope.of(context).unfocus();
    setState(() {
      _center = LatLng(place.lat, place.lng);
      _searchController.text = place.shortName;
      _suggestions = [];
      _showSuggestions = false;
    });
    _mapController.move(_center, _focusedZoom);
  }

  Future<void> _goToMyLocation() async {
    setState(() => _capturingGps = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          CustomSnackbar.showError(context, 'Ative o GPS do dispositivo.');
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          CustomSnackbar.showError(context, 'Permissão de localização negada.');
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _center = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_center, 17);
    } catch (_) {
      if (mounted) {
        CustomSnackbar.showError(
          context,
          'Não foi possível obter a localização.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _capturingGps = false);
      }
    }
  }

  Future<String> _reverseGeocode(LatLng point) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': point.latitude.toString(),
        'lon': point.longitude.toString(),
        'format': 'jsonv2',
        'accept-language': 'pt-BR,pt',
      });

      final response = await http.get(uri, headers: {
        'User-Agent': 'TimeFlowApp/1.0 (timeflow@app)',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final displayName = (data['display_name'] as String? ?? '').trim();
        if (displayName.isNotEmpty) {
          return displayName.split(', ').take(3).join(', ');
        }
      }
    } catch (_) {}

    return '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
  }

  Future<void> _confirmLocation() async {
    if (_saving) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _showSuggestions = false;
    });

    final point = _center;

    try {
      final address = await _reverseGeocode(point);
      await _firestore.collection('settings').doc('company').set({
        'workplaceLat': point.latitude,
        'workplaceLng': point.longitude,
        'workplaceName': address,
        'maxDistanceMeters': 100,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      if (!mounted) {
        return;
      }

      setState(() {
        _lat = point.latitude;
        _lng = point.longitude;
        _address = address;
      });

      CustomSnackbar.showSuccess(context, 'Local salvo com sucesso.');
    } catch (_) {
      if (mounted) {
        CustomSnackbar.showError(
            context, 'Erro ao salvar o local. Tente novamente.');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _buildHeaderCard() {
    return SettingsHeaderCard(
      hasSavedLocation: _hasSavedLocation,
    );
  }

  Widget _buildSearchField() {
    return SettingsSearchField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      loadingSuggestions: _loadingSuggestions,
      onChanged: _onSearchChanged,
      onClear: () {
        _searchController.clear();
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
      },
    );
  }

  Widget _buildSuggestionsCard() {
    return SettingsSuggestionsCard(
      suggestions: _suggestions,
      onSuggestionTap: _selectSuggestion,
    );
  }

  Widget _buildMapCard() {
    return SettingsMapCard(
      mapController: _mapController,
      center: _center,
      hasSavedLocation: _hasSavedLocation,
      hasPendingChange: _hasPendingChange,
      capturingGps: _capturingGps,
      defaultZoom: _defaultZoom,
      focusedZoom: _focusedZoom,
      onMyLocationPressed: _goToMyLocation,
      onCenterChanged: (center) {
        setState(() => _center = center);
      },
    );
  }

  Widget _buildMapWithSuggestionsOverlay() {
    return Stack(
      children: [
        Positioned.fill(child: _buildMapCard()),
        if (_showSuggestions && _suggestions.isNotEmpty)
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: _buildSuggestionsCard(),
          ),
      ],
    );
  }

  Widget _buildBottomCard() {
    return SettingsBottomCard(
      hasPendingChange: _hasPendingChange,
      address: _address,
      coordinateLabel: _coordinateLabel,
      saving: _saving,
      onConfirm: _confirmLocation,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.settings,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Configurações',
                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 12),
                      _buildSearchField(),
                      const SizedBox(height: 12),
                      Expanded(child: _buildMapWithSuggestionsOverlay()),
                      const SizedBox(height: 12),
                      _buildBottomCard(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
