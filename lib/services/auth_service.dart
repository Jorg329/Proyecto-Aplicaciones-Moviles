import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================
  // REGISTRAR USUARIO
  // ============================================
  Future<User?> registrarUsuario(String email, String password) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      // Convertimos el error de Firebase en un mensaje en español
      throw _traducirError(e);
    }
  }

  // ============================================
  // INICIAR SESIÓN
  // ============================================
  Future<User?> iniciarSesion(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _traducirError(e);
    }
  }

  // ============================================
  // CERRAR SESIÓN
  // ============================================
  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }

  // ============================================
  // OBTENER USUARIO ACTUAL
  // ============================================
  User? get usuarioActual => _auth.currentUser;

  // ============================================
  // TRADUCIR ERRORES DE FIREBASE
  // ============================================
  String _traducirError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres).';
      case 'user-not-found':
        return 'No existe un usuario con ese correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'user-disabled':
        return 'Este usuario ha sido deshabilitado.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta más tarde.';
      case 'network-request-failed':
        return 'Error de conexión. Revisa tu internet.';
      default:
        return 'Error: ${e.message ?? e.code}';
    }
  }
}
