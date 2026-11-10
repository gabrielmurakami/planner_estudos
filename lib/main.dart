import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'pages/home_page.dart';
import 'theme/cores.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Aula 09: inicialização do Firebase antes do runApp.
  Object? erroFirebase;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    erroFirebase = e;
  }

  runApp(PlannerApp(erroFirebase: erroFirebase));
}

class PlannerApp extends StatelessWidget {
  const PlannerApp({super.key, this.erroFirebase});

  final Object? erroFirebase;

  @override
  Widget build(BuildContext context) {
    final bordaCampo = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Cores.bordaCampo),
    );

    return MaterialApp(
      title: 'Planner de Estudos',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Cores.royal,
          primary: Cores.royal,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Cores.fundo,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: bordaCampo,
          enabledBorder: bordaCampo,
          focusedBorder: bordaCampo.copyWith(
            borderSide: const BorderSide(color: Cores.royal, width: 2),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      home: erroFirebase == null
          ? const HomePage()
          : _TelaErroFirebase(erro: erroFirebase!),
    );
  }
}

/// Mostrada quando o firebase_options.dart ainda é o provisório.
class _TelaErroFirebase extends StatelessWidget {
  const _TelaErroFirebase({required this.erro});

  final Object erro;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner de Estudos'),
        centerTitle: true,
        backgroundColor: Cores.royal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48, color: Cores.royal),
              const SizedBox(height: 12),
              const Text(
                'Falta configurar o Firebase',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Cores.texto),
              ),
              const SizedBox(height: 8),
              Text(
                '$erro',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Cores.textoSuave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
