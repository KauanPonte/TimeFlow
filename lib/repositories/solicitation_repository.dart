import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';
import 'package:flutter_application_appdeponto/services/ponto_validator.dart';
import 'package:flutter_application_appdeponto/services/ponto_service.dart';

class SolicitationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'solicitations';
  static const String _pontosRoot = 'pontos';

  //  Funcionário: criar solicitação

  /// Cria uma solicitação de modificação de ponto.
  /// Valida se os itens solicitados são consistentes com os eventos existentes
  /// e com os itens pendentes já solicitados.
  Future<SolicitationModel> createSolicitation({
    required String diaId,
    required List<SolicitationItem> items,
    String? reason,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');

    final uid = user.uid;

    // Busca nome do funcionário
    final userDoc = await _firestore.collection('usuarios').doc(uid).get();
    final employeeName = (userDoc.data()?['name'] ?? '').toString();

    // Carrega eventos reais do dia
    final eventosReais = await _loadEventosDoDia(uid, diaId);

    // Carrega solicitações pendentes do mesmo dia para compor estado virtual
    final pendentes = await _loadPendingForDay(uid, diaId);

    // Compõe lista virtual de eventos (reais + pendentes já existentes + novos)
    final virtualEventos = _buildVirtualEventos(eventosReais, pendentes);

    // Adiciona os novos itens à lista virtual para validar
    final novosVirtual = List<Map<String, dynamic>>.from(virtualEventos);
    for (final item in items) {
      if (item.action == SolicitationAction.add) {
        novosVirtual.add({'tipo': item.tipo, 'at': item.horario});
      } else if (item.action == SolicitationAction.edit) {
        final idx = novosVirtual.indexWhere((e) => e['id'] == item.eventoId);
        if (idx >= 0) {
          novosVirtual[idx] = {
            'id': item.eventoId,
            'tipo': item.tipo,
            'at': item.horario,
          };
        }
      } else if (item.action == SolicitationAction.delete) {
        novosVirtual.removeWhere((e) => e['id'] == item.eventoId);
      }
    }

    // Valida a sequência resultante
    final erro = PontoValidator.validarSequenciaCompleta(novosVirtual);
    if (erro != null) throw Exception(erro);

    // Salva no Firestore
    final docRef = _firestore.collection(_collection).doc();
    final solicitation = SolicitationModel(
      id: docRef.id,
      uid: uid,
      employeeName: employeeName.isEmpty ? (user.email ?? uid) : employeeName,
      diaId: diaId,
      items: items,
      status: SolicitationStatus.pending,
      createdAt: DateTime.now(),
      reason: reason,
    );

    await docRef.set(solicitation.toMap());
    return solicitation;
  }

  //  Funcionário: atualizar solicitação (edição in-place)

  /// Atualiza os itens e a observação de uma solicitação pendente existente.
  /// Valida a sequência resultante antes de persistir.
  Future<void> updateSolicitation({
    required String existingSolicitationId,
    required String diaId,
    required List<SolicitationItem> items,
    String? reason,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');
    final uid = user.uid;

    // Carrega eventos reais do dia
    final eventosReais = await _loadEventosDoDia(uid, diaId);

    // Outras solicitações pendentes do mesmo dia (excluindo a atual)
    final todasPendentes = await _loadPendingForDay(uid, diaId);
    final outrasPendentes =
        todasPendentes.where((s) => s.id != existingSolicitationId).toList();

    // Compõe estado virtual sem a solicitação atual
    final virtualEventos = _buildVirtualEventos(eventosReais, outrasPendentes);

    // Aplica os novos itens para validação
    final novosVirtual = List<Map<String, dynamic>>.from(virtualEventos);
    for (final item in items) {
      if (item.action == SolicitationAction.add) {
        novosVirtual.add({'tipo': item.tipo, 'at': item.horario});
      } else if (item.action == SolicitationAction.edit) {
        final idx = novosVirtual.indexWhere((e) => e['id'] == item.eventoId);
        if (idx >= 0) {
          novosVirtual[idx] = {
            'id': item.eventoId,
            'tipo': item.tipo,
            'at': item.horario,
          };
        }
      } else if (item.action == SolicitationAction.delete) {
        novosVirtual.removeWhere((e) => e['id'] == item.eventoId);
      }
    }

    final erro = PontoValidator.validarSequenciaCompleta(novosVirtual);
    if (erro != null) throw Exception(erro);

    // Atualiza o documento existente
    await _firestore
        .collection(_collection)
        .doc(existingSolicitationId)
        .update({
      'items': items.map((i) => i.toMap()).toList(),
      'reason': reason,
    });
  }

  //  Funcionário: cancelar solicitação

  Future<void> cancelSolicitation(String solicitationId) async {
    await _firestore.collection(_collection).doc(solicitationId).update({
      'status': SolicitationStatus.cancelled.name,
      'resolvedAt': Timestamp.now(),
    });
  }

  //  Funcionário: minhas solicitações pendentes

  Future<List<SolicitationModel>> getMyPendingSolicitations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snap = await _firestore
        .collection(_collection)
        .where('uid', isEqualTo: user.uid)
        .where('status', isEqualTo: SolicitationStatus.pending.name)
        .get();

    final list = snap.docs.map((d) => SolicitationModel.fromDoc(d)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Retorna solicitações revisadas (aprovadas/rejeitadas) do usuário atual
  /// nos últimos [windowDays] dias. Usado para notificar o funcionário.
  Future<List<SolicitationModel>> getMyReviewedSolicitations({
    int windowDays = 7,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final cutoff = DateTime.now().subtract(Duration(days: windowDays));

    final snap = await _firestore
        .collection(_collection)
        .where('uid', isEqualTo: user.uid)
        .where('status', whereIn: [
      SolicitationStatus.approved.name,
      SolicitationStatus.rejected.name,
    ]).get();

    return snap.docs
        .map((d) => SolicitationModel.fromDoc(d))
        .where((s) => s.resolvedAt != null && s.resolvedAt!.isAfter(cutoff))
        .toList()
      ..sort((a, b) {
        // Não vistos primeiro; dentro de cada grupo, mais recente primeiro.
        if (a.seenByEmployee != b.seenByEmployee) {
          return a.seenByEmployee ? 1 : -1;
        }
        return (b.resolvedAt ?? b.createdAt)
            .compareTo(a.resolvedAt ?? a.createdAt);
      });
  }

  /// Marca uma solicitação como vista pelo funcionário no servidor.
  Future<void> markSeenByEmployee(String solicitationId) async {
    await _firestore.collection(_collection).doc(solicitationId).update({
      'seenByEmployee': true,
    });
  }

  //  Admin: solicitações pendentes de todos

  Future<List<SolicitationModel>> getAllPendingSolicitations() async {
    final snap = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: SolicitationStatus.pending.name)
        .get();

    final list = snap.docs.map((d) => SolicitationModel.fromDoc(d)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  //  Admin: processar solicitação

  /// Processa uma solicitação com os status individuais de cada item.
  /// Se algum item for rejeitado, todos os posteriores também são rejeitados
  /// (respeitando a ordem cronológica dos eventos).
  Future<void> processSolicitation({
    required String solicitationId,
    required List<SolicitationItemStatus> itemStatuses,
    String? reason,
  }) async {
    final docRef = _firestore.collection(_collection).doc(solicitationId);
    final docSnap = await docRef.get();
    if (!docSnap.exists) throw Exception('Solicitação não encontrada.');

    final solicitation = SolicitationModel.fromDoc(docSnap);
    final uid = solicitation.uid;
    final diaId = solicitation.diaId;

    // Aplica cascata de rejeição: se item i é rejeitado, os posteriores
    // que dependam dele também são rejeitados.
    var finalStatuses = _applyCascadeRejection(
      solicitation.items,
      itemStatuses,
    );

    // Valida o estado resultante contra os eventos reais do dia.
    // Se inválido, rejeita itens adicionais até a sequência ser válida.
    final baseEvents = await _loadEventosDoDia(uid, diaId);
    finalStatuses = _validateAndRecascade(
      solicitation.items,
      finalStatuses,
      baseEvents,
    );

    // Aplica os itens aceitos no Firestore
    final refDia = _firestore
        .collection(_pontosRoot)
        .doc(uid)
        .collection('dias')
        .doc(diaId);
    final refEventos = refDia.collection('eventos');

    final admin = FirebaseAuth.instance.currentUser;

    for (int i = 0; i < solicitation.items.length; i++) {
      final item = solicitation.items[i];
      final itemStatus = finalStatuses[i];

      if (itemStatus != SolicitationItemStatus.accepted) continue;

      if (item.action == SolicitationAction.add) {
        // Cria dia se não existe
        final diaSnap = await refDia.get();
        if (!diaSnap.exists) {
          await refDia.set({
            'uid': uid,
            'date': diaId,
            'createdAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
            'lastTipo': item.tipo,
            'lastAt': Timestamp.fromDate(item.horario),
          });
        }
        await refEventos.add({
          'tipo': item.tipo,
          'at': Timestamp.fromDate(item.horario),
        });
      } else if (item.action == SolicitationAction.edit &&
          item.eventoId != null) {
        await refEventos.doc(item.eventoId).update({
          'tipo': item.tipo,
          'at': Timestamp.fromDate(item.horario),
        });
      } else if (item.action == SolicitationAction.delete &&
          item.eventoId != null) {
        await refEventos.doc(item.eventoId).delete();
      }
    }

    // Recalcula meta do dia após aplicar alterações
    final hasAccepted = finalStatuses.contains(SolicitationItemStatus.accepted);
    if (hasAccepted) {
      // Verifica se dia ainda tem eventos
      final remaining = await refEventos.get();
      if (remaining.docs.isEmpty) {
        await refDia.delete();
      } else {
        await PontoService.recalcularBancoDeHorasDoDia(uid: uid, diaId: diaId);
      }
    }

    // Determina status geral
    final allRejected =
        finalStatuses.every((s) => s == SolicitationItemStatus.rejected);
    final overallStatus =
        allRejected ? SolicitationStatus.rejected : SolicitationStatus.approved;

    // Atualiza solicitação no Firestore
    final updatedItems = <Map<String, dynamic>>[];
    for (int i = 0; i < solicitation.items.length; i++) {
      final newItem = solicitation.items[i].copyWith(status: finalStatuses[i]);
      updatedItems.add(newItem.toMap());
    }

    await docRef.update({
      'items': updatedItems,
      'status': overallStatus.name,
      'resolvedAt': Timestamp.now(),
      'resolvedBy': admin?.uid,
      'reason': reason,
    });
  }

  //  Helpers internos

  /// Constrói o estado virtual final aplicando os itens aceitos sobre a base.
  List<Map<String, dynamic>> _buildFinalVirtualState(
    List<SolicitationItem> items,
    List<SolicitationItemStatus> statuses,
    List<Map<String, dynamic>> baseEvents,
  ) {
    final events = baseEvents.map((e) => Map<String, dynamic>.from(e)).toList();

    // 1. Deletes primeiro (para liberar ids)
    for (int i = 0; i < items.length; i++) {
      if (statuses[i] != SolicitationItemStatus.accepted) continue;
      final item = items[i];
      if (item.action == SolicitationAction.delete && item.eventoId != null) {
        events.removeWhere((e) => e['id'] == item.eventoId);
      }
    }
    // 2. Edições
    for (int i = 0; i < items.length; i++) {
      if (statuses[i] != SolicitationItemStatus.accepted) continue;
      final item = items[i];
      if (item.action == SolicitationAction.edit && item.eventoId != null) {
        final idx = events.indexWhere((e) => e['id'] == item.eventoId);
        if (idx >= 0) {
          events[idx] = {
            'id': item.eventoId,
            'tipo': item.tipo,
            'at': item.horario,
          };
        }
      }
    }
    // 3. Adições
    for (int i = 0; i < items.length; i++) {
      if (statuses[i] != SolicitationItemStatus.accepted) continue;
      final item = items[i];
      if (item.action == SolicitationAction.add) {
        events.add({'tipo': item.tipo, 'at': item.horario});
      }
    }
    return events;
  }

  /// Após a cascata de tempo, valida o estado final e rejeita itens
  /// adicionais (do mais recente para o mais antigo) até a sequência
  /// de pontos ser válida.
  List<SolicitationItemStatus> _validateAndRecascade(
    List<SolicitationItem> items,
    List<SolicitationItemStatus> statuses,
    List<Map<String, dynamic>> baseEvents,
  ) {
    final result = List<SolicitationItemStatus>.from(statuses);

    while (true) {
      final virtualEvents = _buildFinalVirtualState(items, result, baseEvents);
      final error = PontoValidator.validarSequenciaCompleta(virtualEvents);
      if (error == null) return result; // Sequência válida ✓

      // Encontra o item aceito com o horário mais tardio para rejeitar.
      int latestIdx = -1;
      DateTime? latestTime;
      for (int i = 0; i < items.length; i++) {
        if (result[i] != SolicitationItemStatus.accepted) continue;
        final t = items[i].horario;
        if (latestTime == null || t.isAfter(latestTime)) {
          latestTime = t;
          latestIdx = i;
        }
      }

      if (latestIdx == -1) {
        // Não há mais itens aceitos — rejeita tudo.
        return List.filled(items.length, SolicitationItemStatus.rejected);
      }

      result[latestIdx] = SolicitationItemStatus.rejected;
    }
  }

  /// Aplica rejeição em cascata: se o item i foi rejeitado,
  /// e os itens posteriores dependem dele (na sequência de transições),
  /// também são rejeitados.
  List<SolicitationItemStatus> _applyCascadeRejection(
    List<SolicitationItem> items,
    List<SolicitationItemStatus> statuses,
  ) {
    final result = List<SolicitationItemStatus>.from(statuses);

    // Ordena itens por horário para determinar dependência
    final indexed = List<int>.generate(items.length, (i) => i);
    indexed.sort((a, b) => items[a].horario.compareTo(items[b].horario));

    bool foundRejection = false;
    for (final i in indexed) {
      if (foundRejection) {
        result[i] = SolicitationItemStatus.rejected;
      } else if (result[i] == SolicitationItemStatus.rejected) {
        foundRejection = true;
      }
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> _loadEventosDoDia(
      String uid, String diaId) async {
    final snap = await _firestore
        .collection(_pontosRoot)
        .doc(uid)
        .collection('dias')
        .doc(diaId)
        .collection('eventos')
        .orderBy('at', descending: false)
        .get();

    return snap.docs.map((e) {
      final data = e.data();
      final ts = data['at'] as Timestamp?;
      return {
        'id': e.id,
        'tipo': (data['tipo'] ?? '').toString(),
        'at': ts?.toDate(),
      };
    }).toList();
  }

  Future<List<SolicitationModel>> _loadPendingForDay(
      String uid, String diaId) async {
    final snap = await _firestore
        .collection(_collection)
        .where('uid', isEqualTo: uid)
        .where('diaId', isEqualTo: diaId)
        .where('status', isEqualTo: SolicitationStatus.pending.name)
        .get();

    return snap.docs.map((d) => SolicitationModel.fromDoc(d)).toList();
  }

  /// Constrói lista virtual de eventos = reais + itens pendentes (add/edit/delete).
  List<Map<String, dynamic>> _buildVirtualEventos(
    List<Map<String, dynamic>> reais,
    List<SolicitationModel> pendentes,
  ) {
    final result = reais.map((e) => Map<String, dynamic>.from(e)).toList();

    for (final sol in pendentes) {
      for (final item in sol.items) {
        if (item.action == SolicitationAction.add) {
          result.add({
            'tipo': item.tipo,
            'at': item.horario,
            'pending': true,
          });
        } else if (item.action == SolicitationAction.edit &&
            item.eventoId != null) {
          final idx = result.indexWhere((e) => e['id'] == item.eventoId);
          if (idx >= 0) {
            result[idx] = {
              'id': item.eventoId,
              'tipo': item.tipo,
              'at': item.horario,
              'pending': true,
            };
          }
        } else if (item.action == SolicitationAction.delete &&
            item.eventoId != null) {
          result.removeWhere((e) => e['id'] == item.eventoId);
        }
      }
    }

    return result;
  }

  /// Carrega solicitações pendentes para um dia específico de um usuário.
  Future<List<SolicitationModel>> getPendingSolicitationsForDay(
      String uid, String diaId) async {
    return _loadPendingForDay(uid, diaId);
  }

  /// Carrega os eventos reais do dia de um usuário (método público).
  Future<List<Map<String, dynamic>>> getEventosDoDia(
      String uid, String diaId) async {
    return _loadEventosDoDia(uid, diaId);
  }
}
