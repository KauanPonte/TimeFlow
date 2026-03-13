import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationResult {
  final bool success;
  final String message;
  final Position? position;
  const LocationResult({
    required this.success,
    required this.message,
    this.position,
  });
}

class LocationService {
  static const double _defaultMaxDistanceMeters = 100.0;

  /// Valida se o usuário está dentro do raio permitido do local de trabalho.
  static Future<LocationResult> validatePresencialLocation() async {
    // 1. Verifica se o serviço de localização está ativado
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult(
        success: false,
        message: 'Serviço de localização desativado. Ative o GPS.',
      );
    }

    // 2. Verifica/solicita permissão
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationResult(
          success: false,
          message: 'Permissão de localização negada.',
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(
        success: false,
        message:
            'Permissão de localização permanentemente negada. Ative nas configurações do dispositivo.',
      );
    }

    // 3. Obtém posição atual
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // 4. Busca coordenadas do local de trabalho no Firestore
    final workplaceSettings = await _getWorkplaceSettings();
    if (workplaceSettings == null || workplaceSettings.workplaces.isEmpty) {
      return const LocationResult(
        success: false,
        message:
            'Coordenadas do local de trabalho não configuradas. Contate o administrador.',
      );
    }

    // 5. Calcula a menor distância para qualquer local cadastrado.
    _DistanceToWorkplace? nearest;

    for (final workplace in workplaceSettings.workplaces) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        workplace.lat,
        workplace.lng,
      );
      if (nearest == null || distance < nearest.distanceMeters) {
        nearest = _DistanceToWorkplace(
            workplace: workplace, distanceMeters: distance);
      }
    }

    if (nearest == null) {
      return const LocationResult(
        success: false,
        message:
            'Coordenadas do local de trabalho não configuradas. Contate o administrador.',
      );
    }

    final maxDistanceMeters = workplaceSettings.maxDistanceMeters;
    if (nearest.distanceMeters > maxDistanceMeters) {
      final nearestName = nearest.workplace.name.trim();
      final nearestLabel = nearestName.isEmpty
          ? 'local de trabalho mais próximo'
          : 'local "$nearestName"';

      return LocationResult(
        success: false,
        message:
            'Você está a ${nearest.distanceMeters.toStringAsFixed(0)}m do $nearestLabel. '
            'Máximo permitido: ${maxDistanceMeters.toStringAsFixed(0)}m.',
        position: position,
      );
    }

    return LocationResult(
      success: true,
      message: 'Localização validada.',
      position: position,
    );
  }

  /// Lê locais de trabalho e configuração de distância do Firestore.
  static Future<_WorkplaceSettings?> _getWorkplaceSettings() async {
    final doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('company')
        .get();

    final data = doc.data();
    if (data == null) return null;

    final workplaces = <_WorkplaceLocation>[];

    final rawWorkplaces = data['workplaces'];
    if (rawWorkplaces is List) {
      for (final item in rawWorkplaces) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final lat = ((map['lat'] ?? map['workplaceLat']) as num?)?.toDouble();
        final lng = ((map['lng'] ?? map['workplaceLng']) as num?)?.toDouble();
        if (lat == null || lng == null) continue;
        final name = (map['name'] ?? map['workplaceName'] ?? '').toString();
        workplaces.add(_WorkplaceLocation(lat: lat, lng: lng, name: name));
      }
    }

    // Compatibilidade com o formato legado (local único).
    if (workplaces.isEmpty) {
      final lat = (data['workplaceLat'] as num?)?.toDouble();
      final lng = (data['workplaceLng'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        final name = (data['workplaceName'] ?? '').toString();
        workplaces.add(_WorkplaceLocation(lat: lat, lng: lng, name: name));
      }
    }

    if (workplaces.isEmpty) return null;

    final maxDistanceMeters = (data['maxDistanceMeters'] as num?)?.toDouble() ??
        _defaultMaxDistanceMeters;

    return _WorkplaceSettings(
      workplaces: workplaces,
      maxDistanceMeters: maxDistanceMeters,
    );
  }
}

class _WorkplaceSettings {
  final List<_WorkplaceLocation> workplaces;
  final double maxDistanceMeters;

  const _WorkplaceSettings({
    required this.workplaces,
    required this.maxDistanceMeters,
  });
}

class _WorkplaceLocation {
  final double lat;
  final double lng;
  final String name;

  const _WorkplaceLocation({
    required this.lat,
    required this.lng,
    required this.name,
  });
}

class _DistanceToWorkplace {
  final _WorkplaceLocation workplace;
  final double distanceMeters;

  const _DistanceToWorkplace({
    required this.workplace,
    required this.distanceMeters,
  });
}
