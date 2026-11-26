import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../models/jornada.dart';
import '../models/tarea.dart';
import '../services/auth_service.dart';
import '../services/jornada_service.dart';
import '../services/tarea_service.dart';
import 'detalle_tarea_screen.dart';
import 'login_screen.dart';
import 'mis_tareas_screen.dart';
import 'mi_progreso_screen.dart';
import 'notificaciones_screen.dart';

class MiJornadaScreen extends StatefulWidget {
  const MiJornadaScreen({super.key});

  @override
  State<MiJornadaScreen> createState() => _MiJornadaScreenState();
}

class _MiJornadaScreenState extends State<MiJornadaScreen> {
  int _indiceSeleccionado = 0;
  final AuthService _authService = AuthService();

  final List<Widget> _pantallas = [
    const _PantallaInicio(),
    const MisTareasScreen(),
    const MiProgresoScreen(),
    const NotificacionesScreen(),
  ];

  void _cambiarPestana(int index) {
    setState(() => _indiceSeleccionado = index);
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _authService.cerrarSesion();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi jornada'),
        backgroundColor: const Color(0xFF0D1B5E),
        foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: _pantallas[_indiceSeleccionado],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _indiceSeleccionado,
        onTap: _cambiarPestana,
        selectedItemColor: const Color(0xFF00A859),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Progreso',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alertas',
          ),
        ],
      ),
    );
  }
}

// ============================================
// CONTENIDO DE LA PESTAÑA "INICIO"
// ============================================
class _PantallaInicio extends StatefulWidget {
  const _PantallaInicio();

  @override
  State<_PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<_PantallaInicio> {
  final JornadaService _jornadaService = JornadaService();
  final TareaService _tareaService = TareaService();

  Timer? _reloj;
  DateTime _ahora = DateTime.now();
  Jornada? _jornadaActiva;
  bool _cargando = false;

  // Variables para el mapa y la ubicación
  LatLng? _miUbicacion;
  bool _cargandoUbicacion = true;

  // Controlador del mapa (para moverlo programáticamente)
  final MapController _mapController = MapController();

  // Suscripción al stream de ubicación
  StreamSubscription<Position>? _posicionSubscription;

  // ¿El mapa debe seguir al usuario automáticamente?
  bool _siguiendoUsuario = true;

  // Lista de tareas para mostrar en el mapa
  List<Tarea> _tareas = [];
  StreamSubscription<List<Tarea>>? _tareasSubscription;

  @override
  void initState() {
    super.initState();
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _ahora = DateTime.now());
    });
    _cargarJornadaActiva();
    _obtenerUbicacion();
    _escucharTareas();
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _tareasSubscription?.cancel();
    _posicionSubscription?.cancel();
    super.dispose();
  }

  // ============================================
  // ESCUCHAR LAS TAREAS EN TIEMPO REAL
  // ============================================
  void _escucharTareas() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _tareasSubscription = _tareaService
        .obtenerTareasDelUsuario(user.uid)
        .listen((tareas) {
          if (mounted) {
            setState(() => _tareas = tareas);
          }
        });
  }

  // ============================================
  // HORA Y FECHA FORMATEADAS
  // ============================================
  String get _horaFormateada {
    final hora = _ahora.hour;
    final minuto = _ahora.minute.toString().padLeft(2, '0');
    final periodo = hora >= 12 ? 'p. m.' : 'a. m.';
    final hora12 = hora > 12 ? hora - 12 : (hora == 0 ? 12 : hora);
    return '$hora12:$minuto $periodo';
  }

  String get _fechaFormateada {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return '${dias[_ahora.weekday - 1]}, ${_ahora.day} de ${meses[_ahora.month - 1]}';
  }

  String _formatearHora(DateTime fecha) {
    final hora = fecha.hour;
    final minuto = fecha.minute.toString().padLeft(2, '0');
    final periodo = hora >= 12 ? 'p. m.' : 'a. m.';
    final hora12 = hora > 12 ? hora - 12 : (hora == 0 ? 12 : hora);
    return '$hora12:$minuto $periodo';
  }

  // ============================================
  // COLOR SEGÚN EL ESTADO DE LA TAREA
  // ============================================
  Color _colorEstado(String estado) {
    switch (estado) {
      case 'completada':
        return const Color(0xFF00A859);
      case 'en_progreso':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  IconData _iconoEstado(String estado) {
    switch (estado) {
      case 'completada':
        return Icons.check_circle;
      case 'en_progreso':
        return Icons.pending;
      default:
        return Icons.flag;
    }
  }

  // ============================================
  // CARGAR JORNADA ACTIVA AL INICIAR
  // ============================================
  Future<void> _cargarJornadaActiva() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final jornada = await _jornadaService.obtenerJornadaActiva(user.uid);
      if (mounted) setState(() => _jornadaActiva = jornada);
    } catch (e) {
      debugPrint('Error al cargar jornada: $e');
    }
  }

  // ============================================
  // ESCUCHAR LA UBICACIÓN EN TIEMPO REAL
  // ============================================
  Future<void> _obtenerUbicacion() async {
    setState(() => _cargandoUbicacion = true);

    try {
      // 1. Verificar servicio de ubicación
      final servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivo) {
        if (mounted) {
          _mostrarMensaje('Por favor activa el GPS de tu teléfono.');
          setState(() => _cargandoUbicacion = false);
        }
        return;
      }

      // 2. Verificar permisos
      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) {
          if (mounted) {
            _mostrarMensaje('Permiso de ubicación denegado.');
            setState(() => _cargandoUbicacion = false);
          }
          return;
        }
      }

      if (permiso == LocationPermission.deniedForever) {
        if (mounted) {
          _mostrarMensaje(
            'Permiso denegado permanentemente. Actívalo en ajustes.',
          );
          setState(() => _cargandoUbicacion = false);
        }
        return;
      }

      // 3. Configuración del stream de ubicación
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Notificar cada 5 metros de movimiento
      );

      // 4. Primera ubicación inmediata (para no esperar al primer movimiento)
      final posicionInicial = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      if (mounted) {
        setState(() {
          _miUbicacion = LatLng(
            posicionInicial.latitude,
            posicionInicial.longitude,
          );
          _cargandoUbicacion = false;
        });
      }

      // 5. Suscribirse al stream de ubicación
      _posicionSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen((Position posicion) {
            if (!mounted) return;
            final nuevaUbicacion = LatLng(
              posicion.latitude,
              posicion.longitude,
            );
            setState(() => _miUbicacion = nuevaUbicacion);

            // Si estamos siguiendo al usuario, mover el mapa
            if (_siguiendoUsuario) {
              _mapController.move(nuevaUbicacion, _mapController.camera.zoom);
            }
          });
    } catch (e) {
      debugPrint('Error al obtener ubicación: $e');
      if (mounted) {
        _mostrarMensaje('Error al obtener ubicación: $e');
        setState(() => _cargandoUbicacion = false);
      }
    }
  }

  // ============================================
  // REGISTRAR ENTRADA / SALIDA
  // ============================================
  Future<void> _registrarEntrada() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _cargando = true);
    try {
      final id = await _jornadaService.iniciarJornada(user.uid);
      final nueva = Jornada(
        id: id,
        usuarioId: user.uid,
        horaInicio: DateTime.now(),
        estado: 'activa',
      );
      if (mounted) {
        setState(() => _jornadaActiva = nueva);
        _mostrarMensaje('¡Jornada iniciada correctamente!');
      }
    } catch (e) {
      if (mounted) _mostrarMensaje('Error al iniciar jornada: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _registrarSalida() async {
    if (_jornadaActiva == null) return;
    setState(() => _cargando = true);
    try {
      await _jornadaService.finalizarJornada(_jornadaActiva!.id);
      if (mounted) {
        setState(() => _jornadaActiva = null);
        _mostrarMensaje('Jornada finalizada. ¡Buen trabajo!');
      }
    } catch (e) {
      if (mounted) _mostrarMensaje('Error al finalizar: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), duration: const Duration(seconds: 3)),
    );
  }

  // ============================================
  // CONSTRUIR LOS MARCADORES DE LAS TAREAS
  // ============================================
  List<Marker> _construirMarcadoresTareas() {
    final marcadores = <Marker>[];

    for (final tarea in _tareas) {
      if (tarea.latitud == null || tarea.longitud == null) continue;

      marcadores.add(
        Marker(
          point: LatLng(tarea.latitud!, tarea.longitud!),
          width: 60,
          height: 60,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetalleTareaScreen(tarea: tarea),
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                    border: Border.all(
                      color: _colorEstado(tarea.estado),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _iconoEstado(tarea.estado),
                    color: _colorEstado(tarea.estado),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return marcadores;
  }

  @override
  Widget build(BuildContext context) {
    final bool jornadaActiva = _jornadaActiva != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hora y fecha
          Text(
            _horaFormateada,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1B5E),
            ),
          ),
          Text(
            _fechaFormateada,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // ============================================
          // MAPA CON UBICACIÓN Y TAREAS
          // ============================================
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: _cargandoUbicacion
                      ? const Center(child: CircularProgressIndicator())
                      : FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter:
                                _miUbicacion ?? const LatLng(7.1193, -73.1227),
                            initialZoom: 14,
                            onMapEvent: (event) {
                              // Si el usuario mueve el mapa manualmente, dejar de seguirlo
                              if (event is MapEventMoveStart &&
                                  event.source !=
                                      MapEventSource.mapController) {
                                if (mounted) {
                                  setState(() => _siguiendoUsuario = false);
                                }
                              }
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.fieldtrack_1',
                            ),
                            // Marcadores de las tareas
                            MarkerLayer(markers: _construirMarcadoresTareas()),
                            // Marcador de la ubicación del usuario
                            if (_miUbicacion != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _miUbicacion!,
                                    width: 50,
                                    height: 50,
                                    child: const Icon(
                                      Icons.my_location,
                                      color: Colors.blue,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                ),
              ),
              // Botón flotante para recentrar al usuario
              if (!_siguiendoUsuario && _miUbicacion != null)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'recenterBtn',
                    backgroundColor: Colors.white,
                    onPressed: () {
                      setState(() => _siguiendoUsuario = true);
                      _mapController.move(_miUbicacion!, 16);
                    },
                    child: const Icon(Icons.my_location, color: Colors.blue),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Banner de ubicación
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade200, blurRadius: 5),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF00A859)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ubicación detectada',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _miUbicacion != null
                            ? '${_miUbicacion!.latitude.toStringAsFixed(4)}, ${_miUbicacion!.longitude.toStringAsFixed(4)}'
                            : 'Obteniendo ubicación...',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Indicador de seguimiento activo
                Icon(
                  _siguiendoUsuario ? Icons.gps_fixed : Icons.gps_not_fixed,
                  color: _siguiendoUsuario
                      ? const Color(0xFF00A859)
                      : Colors.grey,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Botón entrada/salida
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: jornadaActiva ? Colors.red : const Color(0xFF00A859),
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: (jornadaActiva ? Colors.red : const Color(0xFF00A859))
                      .withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _cargando
                    ? null
                    : (jornadaActiva ? _registrarSalida : _registrarEntrada),
                child: _cargando
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00A859),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            jornadaActiva ? Icons.stop : Icons.play_arrow,
                            size: 50,
                            color: jornadaActiva
                                ? Colors.red
                                : const Color(0xFF00A859),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            jornadaActiva
                                ? 'REGISTRAR\nSALIDA'
                                : 'REGISTRAR\nENTRADA',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: jornadaActiva
                                  ? Colors.red
                                  : const Color(0xFF00A859),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Estado de la jornada
          if (jornadaActiva)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00A859).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF00A859),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Jornada iniciada a las ${_formatearHora(_jornadaActiva!.horaInicio)}',
                    style: const TextStyle(
                      color: Color(0xFF00A859),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            const Text(
              'Jornada no iniciada',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
