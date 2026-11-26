import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'mi_jornada_screen.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para leer lo que el usuario escribe
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();

  // Servicio de autenticación
  final AuthService _authService = AuthService();

  // Estado de carga (para mostrar spinner)
  bool _cargando = false;

  @override
  void dispose() {
    _usuarioController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  // ============================================
  // FUNCIÓN DE INICIO DE SESIÓN
  // ============================================
  Future<void> _iniciarSesion() async {
    final email = _usuarioController.text.trim();
    final password = _contrasenaController.text;

    // Validaciones básicas
    if (email.isEmpty || password.isEmpty) {
      _mostrarMensaje('Por favor completa todos los campos.');
      return;
    }

    if (!email.contains('@')) {
      _mostrarMensaje('Ingresa un correo electrónico válido.');
      return;
    }

    // Activar estado de carga
    setState(() => _cargando = true);

    try {
      // Intentar iniciar sesión con Firebase
      await _authService.iniciarSesion(email, password);

      // Si llegamos aquí, el login fue exitoso
      if (mounted) {
        // Navegar a Mi jornada
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MiJornadaScreen()),
        );
      }
    } catch (e) {
      // Si hay error, mostrarlo
      if (mounted) {
        _mostrarMensaje(e.toString());
      }
    } finally {
      // Desactivar estado de carga (siempre, haya error o no)
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  // ============================================
  // MOSTRAR MENSAJE EMERGENTE
  // ============================================
  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // PARTE SUPERIOR: Azul con el logo
          Container(
            width: double.infinity,
            height: 300,
            decoration: const BoxDecoration(
              color: Color(0xFF0D1B5E),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.location_on, size: 80, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'FieldTrack',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Gestión de trabajadores de campo',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),

          // PARTE INFERIOR: Formulario de Login
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Iniciar sesión',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Campo de usuario
                  TextField(
                    controller: _usuarioController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_cargando,
                    decoration: InputDecoration(
                      labelText: 'Usuario o correo',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campo de contraseña
                  TextField(
                    controller: _contrasenaController,
                    obscureText: true,
                    enabled: !_cargando,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón de ingresar (con spinner)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _cargando ? null : _iniciarSesion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A859),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _cargando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'INGRESAR',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botón para ir a la pantalla de registro
                  Center(
                    child: TextButton(
                      onPressed: _cargando
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegistroScreen(),
                                ),
                              );
                            },
                      child: const Text(
                        '¿No tienes cuenta? Regístrate aquí',
                        style: TextStyle(
                          color: Color(0xFF0D1B5E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      '¿Problemas para ingresar? Contacta a tu administrador',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
