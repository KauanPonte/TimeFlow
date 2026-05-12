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

class _ConnectivityGuardState extends State<ConnectivityGuard>
    with WidgetsBindingObserver {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<dynamic>? _connectivitySub;
  Timer? _probeTimer;
  Timer? _offlineDebounceTimer;
  bool _probeRunning = false;
  int _transportLossEpoch = 0;
  int _internetFailureStreak = 0;

  bool _hasTransport = true;
  bool _hasInternet = true;
  bool _initialized = false;
  DateTime? _resumeGraceUntil;

  static const Duration _resumeGracePeriod = Duration(seconds: 3);
  static const Duration _transportLossConfirmDelay = Duration(seconds: 2);
  static const int _internetFailuresToMarkOffline = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    _probeTimer?.cancel();
    _offlineDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeGraceUntil = DateTime.now().add(_resumeGracePeriod);
      _offlineDebounceTimer?.cancel();
      _refreshConnectivityStatus();
    }
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
      final now = DateTime.now();
      final resumeGraceUntil = _resumeGraceUntil;
      if (resumeGraceUntil != null && now.isBefore(resumeGraceUntil)) {
        _offlineDebounceTimer?.cancel();
        _offlineDebounceTimer = Timer(
          resumeGraceUntil.difference(now),
          _refreshConnectivityStatus,
        );
        return;
      }

      _offlineDebounceTimer?.cancel();
      if (_hasTransport) {
        _confirmTransportLoss();
        return;
      }

      // Desabilita rede do Firestore apenas quando a falta de transporte
      // estiver confirmada, para evitar falso offline ao voltar do background.
      FirebaseFirestore.instance.disableNetwork();
      if (!mounted) return;
      setState(() {
        _hasTransport = false;
        _hasInternet = false;
        _initialized = true;
      });
      return;
    }

    _transportLossEpoch++;
    _offlineDebounceTimer?.cancel();

    final hasInternet = await internet_reachability.hasInternetAccess();
    if (!mounted) return;

    if (hasInternet) {
      _internetFailureStreak = 0;
    } else {
      _internetFailureStreak += 1;
      final shouldMarkOffline =
          _internetFailureStreak >= _internetFailuresToMarkOffline ||
              !_hasInternet;

      if (!shouldMarkOffline) {
        if (!_initialized || !_hasTransport) {
          setState(() {
            _hasTransport = true;
            _initialized = true;
          });
        }
        return;
      }
    }

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

  Future<void> _confirmTransportLoss() async {
    final epoch = ++_transportLossEpoch;
    await Future.delayed(_transportLossConfirmDelay);
    if (!mounted || epoch != _transportLossEpoch) return;

    final retry = await _connectivity.checkConnectivity();
    if (!mounted || epoch != _transportLossEpoch) return;
    if (_hasConnection(retry)) {
      await _applyConnectivityResult(retry);
      return;
    }

    final hasInternet = await internet_reachability.hasInternetAccess();
    if (!mounted || epoch != _transportLossEpoch) return;
    if (hasInternet) {
      FirebaseFirestore.instance.enableNetwork();
      if (!_initialized || !_hasTransport || !_hasInternet) {
        setState(() {
          _hasTransport = true;
          _hasInternet = true;
          _initialized = true;
        });
      }
      return;
    }

    FirebaseFirestore.instance.disableNetwork();
    if (!mounted || epoch != _transportLossEpoch) return;
    setState(() {
      _hasTransport = false;
      _hasInternet = false;
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

      if (hasInternet) {
        _internetFailureStreak = 0;
        _resumeGraceUntil = null;
        _offlineDebounceTimer?.cancel();
      } else {
        _internetFailureStreak += 1;
      }

      final shouldSetInternetOffline = hasInternet ||
          _internetFailureStreak >= _internetFailuresToMarkOffline ||
          !_hasInternet;

      if ((_initialized && _hasTransport && _hasInternet == hasInternet) ||
          !shouldSetInternetOffline) {
        if (!_initialized || !_hasTransport) {
          setState(() {
            _hasTransport = true;
            _initialized = true;
          });
        }
        return;
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

    return Stack(
      children: [
        widget.child,
        if (shouldBlockByOffline)
          Positioned.fill(
            child: NoInternetPage(onRetry: _refreshConnectivityStatus),
          ),
      ],
    );
  }
}
