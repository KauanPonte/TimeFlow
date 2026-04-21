import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_state.dart';
import 'package:flutter_application_appdeponto/pages/no_internet/no_internet_page.dart';
import 'package:flutter_application_appdeponto/services/internet_reachability_stub.dart'
    if (dart.library.io) 'package:flutter_application_appdeponto/services/internet_reachability_io.dart'
    as internet_reachability;

class ConnectivityGuard extends StatefulWidget {
  final Widget child;

  const ConnectivityGuard({
    super.key,
    required this.child,
  });

  @override
  State<ConnectivityGuard> createState() => _ConnectivityGuardState();
}

class _ConnectivityGuardState extends State<ConnectivityGuard> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<dynamic>? _connectivitySub;
  Timer? _probeTimer;
  bool _probeRunning = false;

  bool _hasTransport = true;
  bool _hasInternet = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _refreshConnectivityStatus();
    _connectivitySub =
        _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    _probeTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_hasTransport) {
        _probeInternetAccess();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _probeTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshConnectivityStatus() async {
    final result = await _connectivity.checkConnectivity();
    await _applyConnectivityResult(result);
  }

  Future<void> _onConnectivityChanged(dynamic result) async {
    await _applyConnectivityResult(result);
  }

  Future<void> _applyConnectivityResult(dynamic result) async {
    final hasTransport = _hasConnection(result);

    if (!hasTransport) {
      // Desabilita rede do Firestore para impedir tentativas de reconexão
      // (WriteStream) e os erros de DNS associados.
      FirebaseFirestore.instance.disableNetwork();
      if (!mounted) return;
      setState(() {
        _hasTransport = false;
        _hasInternet = false;
        _initialized = true;
      });
      return;
    }

    final hasInternet = await internet_reachability.hasInternetAccess();
    if (!mounted) return;

    // Reabilita rede do Firestore ao recuperar conexão com a internet.
    if (hasInternet && (!_hasInternet || !_hasTransport)) {
      FirebaseFirestore.instance.enableNetwork();
    }

    if (_initialized &&
        _hasTransport == hasTransport &&
        _hasInternet == hasInternet) {
      return;
    }

    setState(() {
      _hasTransport = hasTransport;
      _hasInternet = hasInternet;
      _initialized = true;
    });
  }

  Future<void> _probeInternetAccess() async {
    if (_probeRunning) return;
    _probeRunning = true;

    try {
      final hasInternet = await internet_reachability.hasInternetAccess();
      if (!mounted) return;

      // Reabilita rede do Firestore ao recuperar conexão via probe periódico.
      if (hasInternet && (!_hasInternet || !_hasTransport)) {
        FirebaseFirestore.instance.enableNetwork();
      }

      if (!_initialized || _hasInternet != hasInternet || !_hasTransport) {
        setState(() {
          _hasTransport = true;
          _hasInternet = hasInternet;
          _initialized = true;
        });
      }
    } finally {
      _probeRunning = false;
    }
  }

  bool _hasConnection(dynamic result) {
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }

    if (result is List<ConnectivityResult>) {
      return result.any((item) => item != ConnectivityResult.none);
    }

    return true;
  }

  bool _isAuthenticated(AuthState state) {
    return state is UserAuthenticated || state is AdminAuthenticated;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final shouldBlockByOffline = _initialized &&
        (!_hasTransport || !_hasInternet) &&
        _isAuthenticated(authState);

    if (shouldBlockByOffline) {
      return NoInternetPage(onRetry: _refreshConnectivityStatus);
    }

    return widget.child;
  }
}
