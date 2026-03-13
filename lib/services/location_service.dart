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
  static const double _maxDistanceMeters = 100.0;

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
    final workplaceCoords = await _getWorkplaceCoordinates();
    if (workplaceCoords == null) {
      return const LocationResult(
        success: false,
        message:
            'Coordenadas do local de trabalho não configuradas. Contate o administrador.',
      );
    }

    // 5. Calcula distância
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      workplaceCoords['lat']!,
      workplaceCoords['lng']!,
    );

    if (distance > _maxDistanceMeters) {
      return LocationResult(
        success: false,
        message:
            'Você está a ${distance.toStringAsFixed(0)}m do local de trabalho. '
            'Máximo permitido: ${_maxDistanceMeters.toStringAsFixed(0)}m.',
        position: position,
      );
    }

    return LocationResult(
      success: true,
      message: 'Localização validada.',
      position: position,
    );
  }

  /// Lê coordenadas do local de trabalho do Firestore.
  static Future<Map<String, double>?> _getWorkplaceCoordinates() async {
    final doc = await FirebaseFirestore.instance
        .collection('settings')
        .doc('company')
        .get();

    final data = doc.data();
    if (data == null) return null;

    final lat = (data['workplaceLat'] as num?)?.toDouble();
    final lng = (data['workplaceLng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    return {'lat': lat, 'lng': lng};
  }
}
