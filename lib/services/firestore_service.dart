import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  // Obtenemos la instancia de Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================
  // EJEMPLO: GUARDAR UN DATO
  // ============================================
  Future<void> guardarEjemplo(
    String coleccion,
    String documentoId,
    Map<String, dynamic> datos,
  ) async {
    try {
      await _db.collection(coleccion).doc(documentoId).set(datos);
      debugPrint('Dato guardado correctamente en $coleccion/$documentoId');
    } catch (e) {
      debugPrint('Error al guardar: $e');
      rethrow;
    }
  }

  // ============================================
  // EJEMPLO: LEER UN DATO
  // ============================================
  Future<Map<String, dynamic>?> leerEjemplo(
    String coleccion,
    String documentoId,
  ) async {
    try {
      final doc = await _db.collection(coleccion).doc(documentoId).get();
      if (doc.exists) {
        return doc.data();
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error al leer: $e');
      rethrow;
    }
  }
}
