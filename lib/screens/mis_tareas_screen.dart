import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/tarea.dart';
import '../services/tarea_service.dart';
import 'detalle_tarea_screen.dart';

class MisTareasScreen extends StatefulWidget {
  const MisTareasScreen({super.key});

  @override
  State<MisTareasScreen> createState() => _MisTareasScreenState();
}

class _MisTareasScreenState extends State<MisTareasScreen> {
  final TareaService _tareaService = TareaService();

  // ============================================
  // FORMATEAR HORA (HH:MM a. m./p. m.)
  // ============================================
  String _formatearHora(DateTime fecha) {
    final hora = fecha.hour;
    final minuto = fecha.minute.toString().padLeft(2, '0');
    final periodo = hora >= 12 ? 'p. m.' : 'a. m.';
    final hora12 = hora > 12 ? hora - 12 : (hora == 0 ? 12 : hora);
    return '$hora12:$minuto $periodo';
  }

  // ============================================
  // COLORES SEGÚN EL ESTADO
  // ============================================
  Color _colorEstado(String estado) {
    switch (estado) {
      case 'completada':
        return const Color(0xFF00A859); // Verde
      case 'en_progreso':
        return Colors.orange;
      default:
        return Colors.grey; // Pendiente
    }
  }

  IconData _iconoEstado(String estado) {
    switch (estado) {
      case 'completada':
        return Icons.check_circle;
      case 'en_progreso':
        return Icons.pending;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('No hay usuario autenticado'));
    }

    return StreamBuilder<List<Tarea>>(
      stream: _tareaService.obtenerTareasDelUsuario(user.uid),
      builder: (context, snapshot) {
        // 1. Cargando
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Error
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('Error al cargar tareas: ${snapshot.error}'),
            ),
          );
        }

        // 3. Sin tareas
        final tareas = snapshot.data ?? [];
        if (tareas.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No tienes tareas asignadas',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // 4. Lista de tareas
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tareas.length,
          itemBuilder: (context, index) {
            final tarea = tareas[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetalleTareaScreen(tarea: tarea),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado: título + estado
                      Row(
                        children: [
                          Icon(
                            _iconoEstado(tarea.estado),
                            color: _colorEstado(tarea.estado),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tarea.titulo,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _colorEstado(tarea.estado)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tarea.estado.replaceAll('_', ' '),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _colorEstado(tarea.estado),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Cliente
                      Row(
                        children: [
                          const Icon(
                            Icons.business,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tarea.cliente,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Hora programada
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatearHora(tarea.horaProgramada),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Barra de progreso
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: tarea.progreso / 100,
                              backgroundColor: Colors.grey.shade200,
                              color: _colorEstado(tarea.estado),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${tarea.progreso}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
