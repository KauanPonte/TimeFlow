import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ponto_service.dart';
import '../widgets/bottom_nav.dart';

class HomePage extends StatefulWidget {
  final String employeeName;
  final String profileImageUrl;
  final String logoAsset;

  const HomePage({
    super.key,
    this.employeeName = '',
    this.profileImageUrl = '',
    this.logoAsset = 'assets/app_icon/timeflow_background.png',
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, Map<String, String>> registros = {};
  List<Map<String, dynamic>> eventosHoje = [];
  String statusLabel = 'Fora do expediente';
  String? ultimoTipoHoje;
  double monthBalance = 0.0;
  String employeeName = '';
  String profileImageUrl = '';
  String todayWorkedDisplay = '0h 0m';
  bool loading = true;
  Timer? _tickTimer;
  static const int _targetMinutesPerDay = 8 * 60; // 8 horas por dia
  double workProgress = 0.0;

  @override
  void initState() {
    super.initState();
    employeeName = widget.employeeName;
    profileImageUrl = widget.profileImageUrl;
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => loading = true);
    registros = await PontoService.loadRegistros();

    eventosHoje = await PontoService.loadEventosHoje();
    ultimoTipoHoje = await PontoService.getUltimoTipoHoje();

    final now = DateTime.now();
    statusLabel = _labelFromUltimoTipo(ultimoTipoHoje);
    todayWorkedDisplay = _computeWorkedFromEventos(eventosHoje, now: now);

    final minutesNow = _computeWorkedMinutesFromEventos(eventosHoje, now: now);
    workProgress = (_targetMinutesPerDay == 0 )
    ? 0.0
    : (minutesNow / _targetMinutesPerDay).clamp(0.0, 1.0);

    final prefs = await SharedPreferences.getInstance();
    monthBalance = prefs.getDouble('month_balance') ?? 0.0;

    if (employeeName.isEmpty) {
      employeeName = prefs.getString('employee_name') ?? '';
    }
    if (profileImageUrl.isEmpty) {
      profileImageUrl = prefs.getString('profile_image_path') ?? '';
    }

    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 30), (_){
      if (!mounted) return;

      final now2 = DateTime.now();
      final minutes2 = _computeWorkedMinutesFromEventos(eventosHoje, now: now2);
      final display2 = _computeWorkedFromEventos(eventosHoje, now: now2);

      setState(() {
        todayWorkedDisplay = display2;
        workProgress = (_targetMinutesPerDay == 0)
        ? 0.0
        :(minutes2/_targetMinutesPerDay).clamp(0.0, 1.0);
      });
    });
   
    setState(() => loading = false);
  }

  String _labelFromUltimoTipo(String? ultimo) {
    switch(ultimo) {
      case 'entrada':
      case 'retorno':
        return 'Trabalhando...';
      case 'pausa':
        return 'Pausado';
      case 'saida':
      default:
        return 'Fora do expediente';    
    }
  }
  
  String _computeWorkedFromEventos(List<Map<String, dynamic>> eventos, {required DateTime now}) {
    final totalMin = _computeWorkedMinutesFromEventos(eventos, now: now);
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return '${h}h ${m}m'; 
  }

  int _computeWorkedMinutesFromEventos(List<Map<String, dynamic>> eventos, {required DateTime now}) {
    DateTime? openWork;
    Duration total = Duration.zero;

    DateTime? tsToDate(dynamic ts){
      if (ts is Timestamp) return ts.toDate();
      return null;
    }

    for(final ev in eventos){
      final tipo = (ev['tipo'] ?? '').toString();
      final at = tsToDate(ev['at']);
      if(at == null) continue;

      if (tipo == 'entrada' || tipo == 'retorno'){
       openWork ??= at;
      }else if (tipo == 'pausa' || tipo == 'saida'){
        if(openWork != null && at.isAfter(openWork)){
          total += at.difference(openWork);
        }
        openWork = null;
      }  
    }

    if (openWork != null && now.isAfter(openWork)){
      total += now.difference(openWork);
    }

    return total.inMinutes;
  }



  Color get balanceColor => monthBalance >= 0 ? Colors.green : Colors.red;

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logo = widget.logoAsset;
    // Precompute widgets for registros to avoid inline expression issues
    final List<Widget> registrosWidgets = [];
    if (!loading && registros.isNotEmpty) {
      final datas = registros.keys.toList()..sort((a, b) => b.compareTo(a));
      registrosWidgets.addAll(datas.map((date) {
        final map = registros[date]!;
        final texto =
            map.entries.map((e) => '${e.key}: ${e.value}').join(' • ');
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromARGB(255, 232, 234, 246)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Expanded(child: Text(texto)),
            ],
          ),
        );
      }));
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 232, 234, 246),
      bottomNavigationBar: BottomNav(
        index: 1,
        args: {
          'employeeName': employeeName,
          'profileImageUrl': profileImageUrl,
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(logo, height: 36, width: 36),
                      const SizedBox(width: 10),
                      const Text('TimeFlow',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.notifications_none, size: 26),
                      const SizedBox(width: 12),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 28),
                        onSelected: (String value) {
                          if (value == 'logout') {
                            context
                                .read<AuthBloc>()
                                .add(const LogoutRequested());
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/welcome',
                              (route) => false,
                            );
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout),
                                SizedBox(width: 8),
                                Text('Logout'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Text('OLÁ, ${employeeName.toUpperCase()}',
                  style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xFF192153),
                      fontWeight: FontWeight.bold)),

              const SizedBox(height: 18),

              // Logo com fundo azul
              Center(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFF303F9F)),
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset('assets/app_icon/timeflow.png',
                          fit: BoxFit.contain)),
                ),
              ),

              const SizedBox(height: 18),

              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(statusLabel,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF192153))),
                            const SizedBox(height: 6),
                            Text(todayWorkedDisplay,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF192153))),
                            const SizedBox(height: 8),
                            ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child: LinearProgressIndicator(
                                    value: workProgress,
                                    minHeight: 12,
                                    backgroundColor: const Color(0xFFEEEEEE),
                                    color: const Color(0xFF192153))),
                          ]),
                    ),

                    // Lottie anim à direita (verificação com rootBundle)
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: FutureBuilder<String>(
                        future: rootBundle
                            .loadString('assets/lottie/gears.json')
                            .catchError((_) => ''),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox();
                          }
                          if (!snapshot.hasData ||
                              (snapshot.data ?? '').isEmpty) {
                            return const Icon(Icons.animation, size: 38);
                          }

                          // Protege o build do Lottie com try/catch — algumas Lotties
                          // podem falhar ao serem parseadas em runtime (especialmente na web).
                          try {
                            return Lottie.asset('assets/lottie/gears.json',
                                fit: BoxFit.contain);
                          } catch (e, st) {
                            // evita crash e mostra fallback
                            debugPrint(
                                'Lottie parse error (gears.json): $e\n$st');
                            return const Icon(Icons.animation, size: 38);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 48, 63, 159),
                      side: const BorderSide(
                          color: Color.fromARGB(255, 48, 63, 159)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 26),
                      elevation: 0),
                  onPressed: () => Navigator.pushNamed(context, '/ponto',
                      arguments: {
                        'employeeName': employeeName,
                        'profileImageUrl': profileImageUrl
                      }).then((_) => _loadAll()),
                  child: const Text('BATER PONTO',
                      style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  const Text('Meu saldo de horas',
                      style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(
                      '${monthBalance >= 0 ? '+' : ''}${monthBalance.toStringAsFixed(2)} h',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: balanceColor)),
                  const SizedBox(height: 8),
                  const Text('Horas positivas ou negativas',
                      style: TextStyle(fontSize: 12)),
                ]),
              ),

              const SizedBox(height: 20),

              const Text('Registros recentes',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              loading
                  ? const Center(child: CircularProgressIndicator())
                  : registros.isEmpty
                      ? const Text('Nenhum registro ainda.')
                      : Column(children: registrosWidgets),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
