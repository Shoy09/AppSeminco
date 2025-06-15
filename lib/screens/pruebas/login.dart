import 'package:app_seminco/database/database_helper.dart';
import 'package:app_seminco/screens/Dash/reporte_sreen.dart';
import 'package:app_seminco/services/api_service.dart';
import 'package:app_seminco/services/user_service.dart';
import 'package:flutter/material.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController dniController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  bool isLoading = false;

  // Tu función handleLogin ya va aquí 👇
  Future<void> handleLogin() async {
    setState(() {
      isLoading = true;
    });

    try {
      final apiService = ApiService();
      final userService = UserService();
      final token = await apiService.login(dniController.text, passController.text);

      final userData = await userService.getUserProfile(token);
      await DatabaseHelper().setCurrentUserDni(dniController.text);
      await DatabaseHelper().saveUser(userData, passController.text);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ReporteScreen(token: token, dni: dniController.text)),
      );
    } catch (e) {
      print("Error en el login online: $e");

      await DatabaseHelper().setCurrentUserDni(dniController.text);
      bool offlineLogin = await DatabaseHelper().loginOffline(dniController.text, passController.text);

      if (offlineLogin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ReporteScreen(token: "offline", dni: dniController.text)),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error"),
            content: const Text("Inicio de sesión fallido. Verifique sus credenciales."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cerrar"),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
