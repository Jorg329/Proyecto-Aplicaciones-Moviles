import 'package:flutter/material.dart';

import '../models/tarea.dart';
import '../services/tarea_service.dart';

class DetalleTareaScreen extends StatefulWidget {
  final Tarea tarea;

  const DetalleTareaScreen({super.key, required this.tarea});

  @override
  State<DetalleTareaScreen> createState() => _DetalleTareaScreenState();
}

class _DetalleTareaScreenState extends State<DetalleTareaScreen> {
  final TareaService _tareaService = TareaService();
  late Tarea _tarea;
  double _progresoTemporal = 0;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _tarea = widget.tarea;
    _progresoTemporal = _tarea.progreso.toDouble();
  }

  // ============================================
  // FORMATEAR HORA
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
        return const Color(0xFF00A859);
      case 'en_progreso':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // ============================================
  // ACTUALIZAR PROGRESO Y ESTADO
  // ============================================
  Future<void> _actualizarProgreso() async {
    setState(() => _cargando = true);
    try {
      final nuevoProgreso = _progresoTemporal.round();
      await _tareaService.actualizarProgreso(_tarea.id, nuevoProgreso);

      // Actualizar el estado automáticamente según el progreso
      String nuevoEstado = 'pendiente';
      if (nuevoProgreso >= 100) {
        nuevoEstado = 'completada';
      } else if (nuevoProgreso > 0) {
        nuevoEstado = 'en_progreso';
      }
      await _tareaService.actualizarEstado(_tarea.id, nuevoEstado);

      if (mounted) {
        setState(() {
          _tarea = _tarea.copyWith(
            progreso: nuevoProgreso,
            estado: nuevoEstado,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progreso actualizado ✅'),
            backgroundColor: Color(0xFF00A859),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de la tarea'),
        backgroundColor: const Color(0xFF0D1B5E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              _tarea.titulo,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D1B5E),
              ),
            ),
            const SizedBox(height: 8),

            // Estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _colorEstado(_tarea.estado).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _tarea.estado.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _colorEstado(_tarea.estado),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Información del cliente
            _infoRow(Icons.business, 'Cliente', _tarea.cliente),
            const SizedBox(height: 12),
            _infoRow(Icons.location_on, 'Dirección', _tarea.direccion),
            const SizedBox(height: 12),
            _infoRow(
              Icons.access_time,
              'Hora programada',
              _formatearHora(_tarea.horaProgramada),
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.description, 'Descripción', _tarea.descripcion),
            const SizedBox(height: 30),

            // Barra de progreso actual
            const Text(
              'Progreso de la tarea',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _tarea.progreso / 100,
                    backgroundColor: Colors.grey.shade200,
                    color: _colorEstado(_tarea.estado),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_tarea.progreso}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Slider para actualizar progreso
            const Text(
              'Actualizar progreso',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _progresoTemporal,
              min: 0,
              max: 100,
              divisions: 10,
              label: '${_progresoTemporal.round()}%',
              activeColor: const Color(0xFF00A859),
              onChanged: _cargando
                  ? null
                  : (value) {
                      setState(() => _progresoTemporal = value);
                    },
            ),
            Center(
              child: Text(
                '${_progresoTemporal.round()}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00A859),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Botón de guardar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _cargando ? null : _actualizarProgreso,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A859),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'GUARDAR PROGRESO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icono, String etiqueta, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(valor, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }
}
