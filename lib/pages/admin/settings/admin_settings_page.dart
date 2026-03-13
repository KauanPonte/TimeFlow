import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/models/place_result.dart';
import 'package:flutter_application_appdeponto/models/saved_workplace.dart';
import 'package:flutter_application_appdeponto/services/admin_settings_firestore_service.dart';
import 'package:flutter_application_appdeponto/services/admin_settings_geocoding_service.dart';
import 'package:flutter_application_appdeponto/pages/admin/settings/widgets/settings_bottom_card.dart';
import 'package:flutter_application_appdeponto/pages/admin/settings/widgets/settings_header_card.dart';
import 'package:flutter_application_appdeponto/pages/admin/settings/widgets/settings_app_bar.dart';
import 'package:flutter_application_appdeponto/pages/admin/settings/widgets/settings_map_card.dart';
import 'package:flutter_application_appdeponto/pages/admin/settings/widgets/settings_map_with_suggestions_overlay.dart';
import 'package:flutter_application_appdeponto/pages/admin/settings/widgets/settings_page_content.dart';
import 'package:flutter_application_appdeponto/pages/admin/settings/widgets/settings_search_field.dart';
import 'package:flutter_application_appdeponto/pages/admin/settings/widgets/settings_suggestions_card.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
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

  List<SavedWorkplace> _savedWorkplaces = [];

  late final MapController _mapController;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _settingsService = AdminSettingsFirestoreService();
  final _geocodingService = AdminSettingsGeocodingService();

  LatLng _center = const LatLng(_defaultLat, _defaultLng);
  List<PlaceResult> _suggestions = [];
  Timer? _debounce;

  bool get _hasSavedLocation => _savedWorkplaces.isNotEmpty;

  int get _savedLocationsCount => _savedWorkplaces.length;

  SavedWorkplace? get _selectedSavedWorkplace {
    return _settingsService.findNearbyWorkplace(
      workplaces: _savedWorkplaces,
      lat: _center.latitude,
      lng: _center.longitude,
    );
  }

  bool get _hasPendingChange {
    if (!_hasSavedLocation) {
      return true;
    }

    return _selectedSavedWorkplace == null;
  }

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
      final workplaces = await _settingsService.loadWorkplaces();
      if (workplaces.isNotEmpty) {
        _savedWorkplaces = workplaces;
        final last = workplaces.last;
        _center = LatLng(last.lat, last.lng);
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
      final suggestions = await _geocodingService.fetchSuggestions(query);

      if (!mounted || _searchController.text.trim() != query) {
        return;
      }

      setState(() {
        _suggestions = suggestions;
        _showSuggestions = _suggestions.isNotEmpty;
      });
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
      final duplicate = _settingsService.findNearbyWorkplace(
        workplaces: _savedWorkplaces,
        lat: point.latitude,
        lng: point.longitude,
        withinMeters: 10,
      );
      if (duplicate != null) {
        if (mounted) {
          CustomSnackbar.showInfo(
            context,
            'Este local já está na lista de locais presenciais.',
          );
        }
        return;
      }

      final address = await _geocodingService.reverseGeocode(
        point.latitude,
        point.longitude,
      );
      final updatedWorkplaces = await _settingsService.addWorkplace(
        currentWorkplaces: _savedWorkplaces,
        workplace: SavedWorkplace(
          lat: point.latitude,
          lng: point.longitude,
          name: address,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _savedWorkplaces = updatedWorkplaces;
      });

      CustomSnackbar.showSuccess(context, 'Local adicionado com sucesso.');
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

  Future<void> _removeLocation(int index) async {
    if (_saving || index < 0 || index >= _savedWorkplaces.length) {
      return;
    }

    final location = _savedWorkplaces[index];
    final label = location.name.isNotEmpty
        ? location.name
        : '${location.lat.toStringAsFixed(5)}, ${location.lng.toStringAsFixed(5)}';

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Excluir local?'),
              content: Text(
                'Deseja remover este local presencial?\n\n$label',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Excluir'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete) {
      return;
    }

    setState(() => _saving = true);

    try {
      final updated = await _settingsService.removeWorkplaceAt(
        currentWorkplaces: _savedWorkplaces,
        index: index,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _savedWorkplaces = updated;
        if (updated.isNotEmpty) {
          final last = updated.last;
          _center = LatLng(last.lat, last.lng);
        }
      });

      CustomSnackbar.showSuccess(context, 'Local removido com sucesso.');
    } catch (_) {
      if (mounted) {
        CustomSnackbar.showError(
          context,
          'Erro ao remover o local. Tente novamente.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _focusSavedLocation(int index) {
    if (index < 0 || index >= _savedWorkplaces.length) {
      return;
    }

    final location = _savedWorkplaces[index];
    final target = LatLng(location.lat, location.lng);

    setState(() {
      _center = target;
      _showSuggestions = false;
    });

    _mapController.move(target, _focusedZoom);
  }

  Widget _buildHeaderCard() {
    return SettingsHeaderCard(
      hasSavedLocation: _hasSavedLocation,
      savedLocationsCount: _savedLocationsCount,
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
    return SettingsMapWithSuggestionsOverlay(
      mapCard: _buildMapCard(),
      suggestionsCard: _buildSuggestionsCard(),
      showSuggestions: _showSuggestions && _suggestions.isNotEmpty,
    );
  }

  Widget _buildBottomCard() {
    return SettingsBottomCard(
      hasPendingChange: _hasPendingChange,
      savedLocationsCount: _savedLocationsCount,
      address: _selectedSavedWorkplace?.name ?? '',
      savedLocations: _savedWorkplaces
          .map(
            (location) => SettingsSavedLocationItem(
              title: location.name.isNotEmpty ? location.name : 'Sem nome',
            ),
          )
          .toList(),
      onSelectLocation: _focusSavedLocation,
      onDeleteLocation: _saving ? null : _removeLocation,
      saving: _saving,
      onConfirm: _confirmLocation,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: const SettingsAppBar(),
      body: SettingsPageContent(
        loading: _loading,
        headerCard: _buildHeaderCard(),
        searchField: _buildSearchField(),
        mapWithSuggestions: _buildMapWithSuggestionsOverlay(),
        bottomCard: _buildBottomCard(),
      ),
    );
  }
}
