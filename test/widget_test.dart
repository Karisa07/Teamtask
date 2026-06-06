import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// =============================================================
// TeamTask - Widget Tests
// Estos tests validan componentes visuales de forma aislada,
// sin necesidad de conexión a Supabase ni providers externos.
// =============================================================

void main() {
  // -------------------------------------------------------
  // TEST 1: Login page renderiza los campos correctamente
  // -------------------------------------------------------
  testWidgets('Login page muestra campos de email, contraseña y botón de ingreso', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('TeamTask', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                TextFormField(
                  key: const Key('email_field'),
                  decoration: const InputDecoration(labelText: 'Correo electrónico'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('password_field'),
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  key: const Key('login_button'),
                  onPressed: () {},
                  child: const Text('Ingresar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('email_field')), findsOneWidget);
    expect(find.byKey(const Key('password_field')), findsOneWidget);
    expect(find.byKey(const Key('login_button')), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('TeamTask'), findsOneWidget);
  });

  // -------------------------------------------------------
  // TEST 2: Validación de campos vacíos en formulario
  // -------------------------------------------------------
  testWidgets('Formulario muestra error si se envía con campos vacíos', (tester) async {
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    key: const Key('email_field'),
                    decoration: const InputDecoration(labelText: 'Correo electrónico'),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'El correo es requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('password_field'),
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'La contraseña es requerida' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    key: const Key('login_button'),
                    onPressed: () => formKey.currentState?.validate(),
                    child: const Text('Ingresar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pump();

    expect(find.text('El correo es requerido'), findsOneWidget);
    expect(find.text('La contraseña es requerida'), findsOneWidget);
  });

  // -------------------------------------------------------
  // TEST 3: Tarjeta de tarea renderiza título y estado
  // -------------------------------------------------------
  testWidgets('Tarjeta de tarea muestra título, descripción y chip de estado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: ListTile(
                title: const Text(
                  'Diseñar pantalla de inicio',
                  key: Key('task_title'),
                ),
                subtitle: const Text(
                  'Crear mockups en Figma para revisión del cliente',
                  key: Key('task_description'),
                ),
                trailing: Chip(
                  key: const Key('task_status_chip'),
                  label: const Text('En progreso'),
                  backgroundColor: Colors.orange.shade100,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('task_title')), findsOneWidget);
    expect(find.byKey(const Key('task_description')), findsOneWidget);
    expect(find.byKey(const Key('task_status_chip')), findsOneWidget);
    expect(find.text('Diseñar pantalla de inicio'), findsOneWidget);
    expect(find.text('En progreso'), findsOneWidget);
  });
}