import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';

class PontoService {
  static const String _root = 'pontos'; 
  static const int _targetMinutesPerDay = 8 * 60;
  static String _mesIdFromDiaId(String diaId) => diaId.substring(0,7);

  static String _hojeId() =>  DateFormat('dd-MM-yyyy').format(DateTime.now());

  static DocumentReference<Map<String, dynamic>> _refDia(String uid, String diaId){
    return FirebaseFirestore.instance
    .collection(_root)
    .doc(uid)
    .collection('dias')
    .doc(diaId);
  }
  
  static CollectionReference<Map<String, dynamic>> _refEventos(String uid, String diaId){
    return _refDia(uid, diaId).collection('eventos');
  }

  static bool _podeRegistrar({required String? ultimoTipo, required String novoTipo}){
    if(ultimoTipo == null) return novoTipo == 'entrada';

    switch(ultimoTipo){
      case 'entrada':
        return novoTipo == 'pausa' || novoTipo == 'saida';
      case 'pausa':
        return novoTipo == 'retorno' || novoTipo == 'saida';
      case 'retorno':
        return novoTipo == 'pausa' || novoTipo == 'saida';
      case 'saida':
        return novoTipo == 'entrada';
      default:
        return false;  
    }
  }

  static String _mensagemErroTransicao(String? ultimo, String novo ){
    if(ultimo == null) return 'O primeiro ponto do dia precisa ser "entrada".';
    return 'Não pode registrar "$novo" agora. Último ponto foi "$novo".';
  }

  static Future<void> registrarPonto(BuildContext context, String tipo) async {
    try{
      final user = FirebaseAuth.instance.currentUser;
      if(user == null){
        CustomSnackbar.showError(context, 'Você precisa estar logado.');
        return;
      }

      if(!['entrada', 'pausa', 'retorno', 'saida'].contains(tipo)){
        CustomSnackbar.showError(context, 'Tipo inválido: $tipo.');
        return;
      }

      final uid = user.uid;
      final diaId = _hojeId();
      final refDia = _refDia(uid, diaId);
      final refEvendtos = _refEventos(uid, diaId);
      final now = Timestamp.now();

      await FirebaseFirestore.instance.runTransaction((tx) async{
        final diaSnap = await tx.get(refDia);

        if(!diaSnap.exists){
          if(tipo != 'entrada'){
            throw Exception('O primeiro ponto do dia precisa ser "entrada".');
          }

          tx.set(refDia, {
            'uid': uid,
            'data': diaId,
            'createdAt': now,
            'updatedAt': now,
            'lastTipo': 'entrada',
            'lastAt': now,
          });

          final newDoc = refEvendtos.doc();
          tx.set(newDoc, {'tipo': 'entrada', 'at': now});
          return;
        }

        final diaData = diaSnap.data() as Map<String, dynamic>;
        final String? ultimoTipo = diaData['lastTipo']?.toString();

        if(!_podeRegistrar(ultimoTipo: ultimoTipo, novoTipo: tipo)){
          throw Exception(_mensagemErroTransicao(ultimoTipo, tipo));
        }

        final newDoc = refEvendtos.doc();
        tx.set(newDoc, {'tipo': tipo , 'at': now});

        tx.update(refDia, {
          'updatedAt': now,
          'lastTipo': tipo,
          'lastAt': now,
        });
      });

      await recalcularBancoDeHorasDoDia(uid: uid, diaId: diaId);

      final horas = DateFormat('HH:mm').format(DateTime.now());
      CustomSnackbar.showSuccess(context, 'Ponto "$tipo" registrado ás $horas.');
    }catch (e){
      CustomSnackbar.showError(context, e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<String?> getUltimoTipoHoje() async {
    final user = FirebaseAuth.instance.currentUser;
    if(user == null) return null;

    final uid = user.uid;
    final diaId = _hojeId();

    final doc = await _refDia(uid, diaId).get();
    final data = doc.data();
    return data?['lastTipo']?.toString();
  }
  
  static Future<List<Map<String, dynamic>>> loadEventosHoje() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final uid = user.uid;
    final diaId = _hojeId();

    final snap = await _refEventos(uid, diaId).orderBy('at', descending: false).get();

    return snap.docs.map((d){
      final m = d.data();
      return {
        'tipo': (m['tipo'] ?? '').toString(),
        'at': m['at'],
      };
    }).toList();
  }
  
  static Future<Map<String, Map<String, String>>> loadRegistros() async{
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final uid = user.uid;

    final diasSnap = await FirebaseFirestore.instance
    .collection(_root)
    .doc(uid)
    .collection('dias')
    .orderBy('data', descending: true)
    .get();

    String ftm(dynamic ts) {
      if (ts is Timestamp) {
        return DateFormat('HH:mm').format(ts.toDate());
      }
      return '';
    }

    final result = <String, Map<String,String>>{};

    for (final diaDoc in diasSnap.docs){
      final diaId = diaDoc.id;

      final eventosSnap = await _refEventos(uid, diaId)
       .orderBy('at', descending: false)
       .get();

      final map = <String, String>{};

      for (final ev in eventosSnap.docs){
        final data = ev.data();
        final tipo = (data['tipo'] ?? '').toString();
        final at = data['at'];

        if (tipo.isEmpty) continue;

        final hora = ftm(at);
        if (hora.isEmpty) continue;

        map[tipo] = hora;
      }

      if(map.isNotEmpty){
        result[diaId] = map;
      }
    }

    return result;

  }

  static DocumentReference<Map<String, dynamic>> _refMes(String uid, String mesId){
    return FirebaseFirestore.instance
    .collection(_root)
    .doc(uid)
    .collection('meses')
    .doc(mesId);
  }

  static Future<void> recalcularBancoDeHorasDoDia({
    required String uid,
    required String diaId,
  }) async {
    final refDia = _refDia(uid, diaId);
    final refEventos = _refEventos(uid, diaId);
    final mesId = _mesIdFromDiaId(diaId);
    final refMes = _refMes(uid, mesId);

    final eventosSnap = await refEventos.orderBy('at', descending: false).get();
    final eventos = eventosSnap.docs.map((d) => d.data()).toList();

    final workedMinutes = _computeWorkedMinutesFromEventosFechado(eventos);
    final deltaMinutes = workedMinutes - _targetMinutesPerDay;

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final diaSnap = await tx.get(refDia);
      final oldDelta = (diaSnap.data()?['deltaMinutes'] as int?) ?? 0;

      tx.set(refDia, {
       'workedMinutes': workedMinutes,
       'deltaMinutes': deltaMinutes,
       'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      final mesSnap = await tx.get(refMes);
      final oldBalance = (mesSnap.data()?['balanceMinutes'] as int?) ?? 0;
      final newBalance = oldBalance + (deltaMinutes - oldDelta);

      tx.set(refMes, {
        'balanceMinutes': newBalance,
        'updatedAt': Timestamp.now(), 
      }, SetOptions(merge: true));
    });
  }

  static int _computeWorkedMinutesFromEventosFechado(List<Map<String, dynamic>> eventos){
    DateTime? openWork;
    Duration total = Duration.zero;

    DateTime? tsToDate(dynamic ts){
      if(ts is Timestamp) return ts.toDate();
      return null;
    }

    for (final ev in eventos ){
      final tipo = (ev['tipo'] ?? '').toString();
      final at = tsToDate(ev['at']);
      if (at == null) continue;

      if(tipo == 'entrada' || tipo == 'retorno'){
        openWork ??= at;
      }else if (tipo == 'pausa' || tipo == 'saida'){
        if (openWork != null && at.isAfter(openWork)){
          total += at.difference(openWork);
        }
        openWork = null;
      }
    }
    return total.inMinutes;
  }

  static Future<double> getSaldoMesAtualHora() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0.0;

    final uid = user.uid;
    final mesId = DateFormat('MM-yyyy').format(DateTime.now());

    final snap = await _refMes(uid,mesId).get();
    final minutes = (snap.data()?['balanceMinutes'] as int?) ?? 0;

    return minutes / 60.0 ;

  }

}
