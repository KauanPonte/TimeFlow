import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';

class PontoService {
  static const String _root = 'pontos'; 

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

}
