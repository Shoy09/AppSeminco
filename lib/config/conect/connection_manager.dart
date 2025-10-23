import 'dart:async';
import 'package:app_seminco/config/conect/connectivity_monitor_mina1.dart';
import 'package:app_seminco/config/conect/connectivity_monitor_mina2.dart';
import 'package:app_seminco/database/database_helper.dart';
import 'package:app_seminco/database/database_helper_mina_2.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectionManager {
  static StreamSubscription<ConnectivityResult>? _subscription;
  static bool _isDialogVisible = false; // evita mostrar muchos diálogos seguidos

  /// Se inicia una sola vez al abrir sesión
  static void startMonitoring(BuildContext context) {
    // Evita múltiples suscripciones
    _subscription?.cancel();

    _subscription = Connectivity().onConnectivityChanged.listen((result) async {
      if (result == ConnectivityResult.none) return; // sin conexión

      // 🔹 Si ya se está mostrando un diálogo, no mostrar otro
      if (_isDialogVisible) return;
      _isDialogVisible = true;

      // 🔹 Determinar mina activa
      final dniMina1 = await DatabaseHelper_Mina1().getCurrentUserDni();
      final dniMina2 = await DatabaseHelper_Mina2().getCurrentUserDni();

      // 🔹 Usamos un contexto global seguro
      final navigator = Navigator.of(context, rootNavigator: true);

      if (dniMina1 != null) {
         await ConnectivityAutoSyncMina1.tryAutoSync(context, dniMina1);
      } else if (dniMina2 != null) {
        ConnectivityAutoSyncMina2.tryAutoSync(navigator.context, dniMina2);
      }

      // Espera a que se cierre el diálogo antes de permitir otro
      await Future.delayed(const Duration(seconds: 2));
      _isDialogVisible = false;
    });
  }

  static void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
  }
}
