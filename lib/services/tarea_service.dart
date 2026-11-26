import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/tarea.dart';

class TareaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================
  // OBTENER LAS TAREAS DEL USUARIO (EN TIEMPO REAL)
  // ============================================
  Stream<List<Tarea>> obtenerTareasDelUsuario(String usuarioId) {
    return _db
        .collection('tareas')
        .where('usuarioId', isEqualTo: usuarioId)
        .orderBy('horaProgramada')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Tarea.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // ============================================
  // ACTUALIZAR EL PROGRESO DE UNA TAREA
  // ============================================
  Future<void> actualizarProgreso(String tareaId, int nuevoProgreso) async {
    try {
      await _db.collection('tareas').doc(tareaId).update({
        'progreso': nuevoProgreso,
      });
    } catch (e) {
      debugPrint('Error al actualizar progreso: $e');
      rethrow;
    }
  }

  // ============================================
  // ACTUALIZAR EL ESTADO DE UNA TAREA
  // ============================================
  Future<void> actualizarEstado(String tareaId, String nuevoEstado) async {
    try {
      await _db.collection('tareas').doc(tareaId).update({
        'estado': nuevoEstado,
      });
    } catch (e) {
      debugPrint('Error al actualizar estado: $e');
      rethrow;
    }
  }

  // ============================================
  // AGREGAR UNA TAREA (ÚTIL PARA PRUEBAS)
  // ============================================
  Future<String> agregarTarea(Tarea tarea) async {
    try {
      final docRef = await _db.collection('tareas').add(tarea.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error al agregar tarea: $e');
      rethrow;
    }
  }
}
