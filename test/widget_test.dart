import 'package:flutter_test/flutter_test.dart';
import 'package:fieldtrack_1/main.dart'; // Importamos nuestro main actual

void main() {
  testWidgets('La pantalla de Login se muestra correctamente', (
    WidgetTester tester,
  ) async {
    // Construimos nuestra app FieldTrackApp
    await tester.pumpWidget(const FieldTrackApp());

    // Verificamos que el título "FieldTrack" esté en pantalla
    expect(find.text('FieldTrack'), findsOneWidget);

    // Verificamos que el texto "Iniciar sesión" esté en pantalla
    expect(find.text('Iniciar sesión'), findsOneWidget);

    // Verificamos que el botón "INGRESAR" esté en pantalla
    expect(find.text('INGRESAR'), findsOneWidget);
  });
}
