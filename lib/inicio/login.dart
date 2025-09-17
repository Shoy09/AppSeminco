import 'package:app_seminco/database/database_helper.dart';
import 'package:app_seminco/database/database_helper_mina_2.dart';
import 'package:app_seminco/mina%201/screens/Dash/reporte_sreen.dart';
import 'package:app_seminco/mina%201/services/api_service.dart';
import 'package:app_seminco/mina%201/services/user_service.dart';
import 'package:app_seminco/mina%202/screens/Dash/reporte_sreen.dart';
import 'package:app_seminco/mina%202/services/api_service.dart';
import 'package:app_seminco/mina%202/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController dniController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  bool isLoading = false;

Future<void> handleLogin() async {
  setState(() {
    isLoading = true;
  });

  final dni = dniController.text;
  final pass = passController.text;

  try {
    // 1. Intento de login online en Mina 1
    try {
      final tokenMina1 = await ApiService_Mina1().login(dni, pass);
      final userDataMina1 = await UserService_mina1().getUserProfile(tokenMina1);
print("userDataMina1: $userDataMina1");
      // Configurar base de datos MINA 1 primero
      await DatabaseHelper_Mina1().setCurrentUserDni(dni);
      await DatabaseHelper_Mina1().saveUser(userDataMina1, pass);

final savedUser = await DatabaseHelper_Mina1().getUserByDni(dniController.text);
    print("Usuario guardado en DB: $savedUser");
    
//       final connectivityService = ConnectivityService();
// final backgroundSyncService = BackgroundSyncService(
//   connectivityService: connectivityService,
// );

// Navigator.pushReplacement(
//   context,
//   MaterialPageRoute(
//     builder: (context) => MultiProvider(
//       providers: [
//         // ChangeNotifierProvider(create: (_) => connectivityService),
//         // Provider.value(value: backgroundSyncService),
//       ],
//       child: ReporteScreenMina1(
//         token: tokenMina1,
//         dni: dni,
//       ),
//     ),
//   ),
// );

Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => ReporteScreenMina1(
      token: tokenMina1,
      dni: dni,
    ),
  ),
);

      return;
    } catch (e1) {
      print("Login online Mina 1 fallido: $e1");
    }

    // 2. Intento de login online en Mina 2
    try {
      final tokenMina2 = await ApiService_Mina2().login(dni, pass);
      final userDataMina2 = await UserService_mina2().getUserProfile(tokenMina2);

      // Configurar base de datos MINA 2
      await DatabaseHelper_Mina2().setCurrentUserDni(dni);
      await DatabaseHelper_Mina2().saveUser(userDataMina2, pass);

// final connectivityServiceMina2 = ConnectivityServiceMina2();
// final backgroundSyncServiceMina2 = BackgroundSyncServiceMina2(
//   connectivityServiceMina2: connectivityServiceMina2,
// );
//       Navigator.pushReplacement(
//   context,
//   MaterialPageRoute(
//     builder: (context) => MultiProvider(
//       providers: [
//         // ChangeNotifierProvider(create: (_) => connectivityServiceMina2),
//         // Provider.value(value: backgroundSyncServiceMina2),
//       ],
//       child: ReporteScreenMina2(
//         token: tokenMina2,
//         dni: dni,
//       ),
//     ),
//   ),
// );
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => ReporteScreenMina2(
      token: tokenMina2,
      dni: dni,
    ),
  ),
);
      return;
    } catch (e2) {
      print("Login online Mina 2 fallido: $e2");
    }

    // 3. Intento de login offline en ambas minas
    try {
      // Mina 1 offline
      await DatabaseHelper_Mina1().setCurrentUserDni(dni);
      final offlineLoginMina1 = await DatabaseHelper_Mina1().loginOffline(dni, pass);
      
      if (offlineLoginMina1) {
//               final connectivityService = ConnectivityService();
// final backgroundSyncService = BackgroundSyncService(
//   connectivityService: connectivityService,
// );

// Navigator.pushReplacement(
//   context,
//   MaterialPageRoute(
//     builder: (context) => MultiProvider(
//       providers: [
//         // ChangeNotifierProvider(create: (_) => connectivityService),
//         // Provider.value(value: backgroundSyncService),
//       ],
//       child: ReporteScreenMina1(
//         token: "offline",
//         dni: dni,
//       ),
//     ),
//   ),
// );
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => ReporteScreenMina1(
      token: "offline",
      dni: dni,
    ),
  ),
);
        return;
      }

      // Mina 2 offline
      await DatabaseHelper_Mina2().setCurrentUserDni(dni);
      final offlineLoginMina2 = await DatabaseHelper_Mina2().loginOffline(dni, pass);
      
      if (offlineLoginMina2) {
//        final connectivityServiceMina2 = ConnectivityServiceMina2();
// final backgroundSyncServiceMina2 = BackgroundSyncServiceMina2(
//   connectivityServiceMina2: connectivityServiceMina2,
// );
//       Navigator.pushReplacement(
//   context,
//   MaterialPageRoute(
//     builder: (context) => MultiProvider(
//       providers: [
//         // ChangeNotifierProvider(create: (_) => connectivityServiceMina2),
//         // Provider.value(value: backgroundSyncServiceMina2),
//       ],
//       child: ReporteScreenMina2(
//         token: "offline",
//         dni: dni,
//       ),
//     ),
//   ),
// );
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => ReporteScreenMina2(
      token: "offline",
      dni: dni,
    ),
  ),
);
        return;
      }
    } catch (offlineError) {
      print("Error en login offline: $offlineError");
    }

    // Si todo falla
    _showLoginError();
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

void _showLoginError() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Error"),
      content: const Text("Inicio de sesión fallido. Verifique sus credenciales por favor."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cerrar"),
        ),
      ],
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Iniciar Sesión"),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: dniController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "DNI",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: handleLogin,
                      child: const Text("Iniciar Sesión"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
