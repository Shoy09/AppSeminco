// import 'package:app_seminco/mina%201/screens/inicio/splash_screen.dart';
// import 'package:app_seminco/mina%201/services/conexion%20I/ConnectivityService.dart';
// import 'package:app_seminco/mina%201/services/conexion%20I/background_sync_service.dart';
// import 'package:flutter/material.dart';
// import 'package:app_seminco/mina%201/screens/pruebas/login.dart';
// import 'package:provider/provider.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   final connectivityService = ConnectivityService();
//   final backgroundSyncService = BackgroundSyncService(connectivityService: connectivityService);

//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => connectivityService),
//         Provider.value(value: backgroundSyncService),
//       ],
//       child: MyApp(),
//     ),
//   );
// }


// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final connectivity = Provider.of<ConnectivityService>(context);

    
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'I-MINER',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       // home: SplashScreen(),
//       home: LoginScreen(),
      
//     );
//   }
// }

import 'dart:io'; // 👈 necesario para HttpOverrides
import 'package:app_seminco/mina%201/screens/Mediciones/horizontal/horizontal.dart';
import 'package:app_seminco/mina%201/screens/Mediciones/largo/largo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_seminco/inicio/login.dart';
import 'package:app_seminco/mina%201/services/conexion I/ConnectivityService.dart';
import 'package:app_seminco/mina%201/services/conexion I/background_sync_service.dart';
import 'package:app_seminco/inicio/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👇 IGNORAR CERTIFICADO NO VÁLIDO (SOLO PARA DESARROLLO)
  HttpOverrides.global = MyHttpOverrides();

runApp(MyApp());

}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'I-MINER',
      theme: ThemeData(primarySwatch: Colors.blue),
      //  home: SplashScreen(),
      home: LoginScreen(),
    );
  }
}

// 👇 Esta clase ignora los errores de certificado
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}  
//76161414