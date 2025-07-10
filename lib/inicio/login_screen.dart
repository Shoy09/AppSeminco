import 'package:app_seminco/database/database_helper.dart';
import 'package:app_seminco/database/database_helper_mina_2.dart';
import 'package:app_seminco/mina%201/screens/Dash/reporte_sreen.dart';
import 'package:app_seminco/mina%201/services/Enviar%20nube/ExploracionService_service.dart';
import 'package:app_seminco/mina%201/services/api_service.dart';
import 'package:app_seminco/mina%201/services/ingreso%20nube/ApiServiceExploracion.dart';
import 'package:app_seminco/mina%201/services/user_service.dart';
import 'package:app_seminco/mina%202/screens/Dash/reporte_sreen.dart';
import 'package:app_seminco/mina%202/services/api_service.dart';
import 'package:app_seminco/mina%202/services/ingreso%20nube/ApiServiceExploracion.dart';
import 'package:app_seminco/mina%202/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/svg.dart';

class SignInFive extends StatefulWidget {
  const SignInFive({Key? key}) : super(key: key);

  @override
  State<SignInFive> createState() => _SignInFiveState();
}

class _SignInFiveState extends State<SignInFive> {
  TextEditingController dniController = TextEditingController();
  TextEditingController passController = TextEditingController();

  bool isLoading = false;
  bool rememberMe = false;
  bool obscureText = true;
String? selectedMina;
  void toggleObscureText() {
    setState(() {
      obscureText = !obscureText;
    });
  }

Future<void> fetchExploracionesMina1(String token) async {
  try {
    final apiService = ApiServiceExploracion_Mina1();
    await apiService.fetchExploracionesMina1(token);
  } catch (e) {
    throw Exception('Error al obtener exploraciones: $e');
  }
}

Future<void> fetchExploracionesMina2(String token) async {
  try {
    final apiService = ApiServiceExploracion_Mina2();
    await apiService.fetchExploracionesMina2(token);
  } catch (e) {
    throw Exception('Error al obtener exploraciones: $e');
  }
}

Future<void> handleLogin() async {
  setState(() {
    isLoading = true;
  });

  final dni = dniController.text;
  final pass = passController.text;

  try {
    // 👉 Intentar login online en Mina 1
    final apiServiceMina1 = ApiService_Mina1();
    final userServiceMina1 = UserService_mina1();
    final tokenMina1 = await apiServiceMina1.login(dni, pass);

    final userDataMina1 = await userServiceMina1.getUserProfile(tokenMina1);

    await DatabaseHelper_Mina1().setCurrentUserDni(dni);
    await DatabaseHelper_Mina1().saveUser(userDataMina1, pass);

    await fetchExploracionesMina1(tokenMina1);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ReporteScreenMina1(token: tokenMina1, dni: dni)),
    );
    return; // 👈 Terminar si fue exitoso

  } catch (e1) {
    print("Login online Mina 1 fallido: $e1");

    // 👉 Intentar login online en Mina 2
    try {
      final apiServiceMina2 = ApiService_Mina2();
      final userServiceMina2 = UserService_mina2();
      final tokenMina2 = await apiServiceMina2.login(dni, pass);

      final userDataMina2 = await userServiceMina2.getUserProfile(tokenMina2);

      await DatabaseHelper_Mina2().setCurrentUserDni(dni);
      await DatabaseHelper_Mina2().saveUser(userDataMina2, pass);

      await fetchExploracionesMina2(tokenMina2);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ReporteScreenMina1(token: tokenMina2, dni: dni)),
      );
      return;

    } catch (e2) {
      print("Login online Mina 2 fallido: $e2");

      // 👉 Intentar login offline Mina 1
      await DatabaseHelper_Mina1().setCurrentUserDni(dni);
      bool offlineLoginMina1 = await DatabaseHelper_Mina1().loginOffline(dni, pass);

      if (offlineLoginMina1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ReporteScreenMina1(token: "offline", dni: dni)),
        );
        return;
      }

      // 👉 Intentar login offline Mina 2
      await DatabaseHelper_Mina2().setCurrentUserDni(dni);
      bool offlineLoginMina2 = await DatabaseHelper_Mina2().loginOffline(dni, pass);

      if (offlineLoginMina2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ReporteScreenMina2(token: "offline", dni: dni)),
        );
        return;
      }

      // ❌ Si todo falla
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
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF21899C),
      body: SafeArea(
        child: SizedBox(
          height: size.height,
          child: Stack(
            children: <Widget>[
              //left side background design. I use a svg image here
              Positioned(
                left: -34,
                top: 181.0,
                child: SvgPicture.string(
                  // Group 3178
                  '<svg viewBox="-34.0 181.0 99.0 99.0" ><path transform="translate(-34.0, 181.0)" d="M 74.25 0 L 99 49.5 L 74.25 99 L 24.74999618530273 99 L 0 49.49999618530273 L 24.7500057220459 0 Z" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(-26.57, 206.25)" d="M 0 0 L 42.07500076293945 16.82999992370605 L 84.15000152587891 0" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(15.5, 223.07)" d="M 0 56.42999649047852 L 0 0" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                  width: 99.0,
                  height: 99.0,
                ),
              ),

              //right side background design. I use a svg image here
              Positioned(
                right: -52,
                top: 45.0,
                child: SvgPicture.string(
                  // Group 3177
                  '<svg viewBox="288.0 45.0 139.0 139.0" ><path transform="translate(288.0, 45.0)" d="M 104.25 0 L 139 69.5 L 104.25 139 L 34.74999618530273 139 L 0 69.5 L 34.75000762939453 0 Z" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(298.42, 80.45)" d="M 0 0 L 59.07500076293945 23.63000106811523 L 118.1500015258789 0" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /><path transform="translate(357.5, 104.07)" d="M 0 79.22999572753906 L 0 0" fill="none" stroke="#ffffff" stroke-width="1" stroke-opacity="0.25" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
                  width: 139.0,
                  height: 139.0,
                ),
              ),

              //content ui
              Positioned(
                top: 8.0,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: size.width * 0.06),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        //logo section
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              logo(size.height / 8, size.height / 8),
                              const SizedBox(
                                height: 16,
                              ),
                              richText(23.12),
                            ],
                          ),
                        ),

                        //continue with Dni for sign in app text
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Continuar con su usuario para iniciar sesión en la aplicación',
                            style: GoogleFonts.inter(
                              fontSize: 14.0,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        Expanded(
  flex: 1, // Ajusta el flex según necesidad
  child: DropdownButtonFormField<String>(
    decoration: InputDecoration(
      labelText: 'Seleccione mina',
      labelStyle: GoogleFonts.inter(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white54),
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
    ),
    style: GoogleFonts.inter(color: Colors.white),
    dropdownColor: Colors.grey[850], // Fondo del menú desplegable
    value: selectedMina, // Variable donde guardas la selección
    items: [
      'Mina 1',
      'Mina 2',
      'Mina 3',
    ].map((mina) {
      return DropdownMenuItem<String>(
        value: mina,
        child: Text(mina),
      );
    }).toList(),
    onChanged: (newValue) {
      setState(() {
        selectedMina = newValue!;
      });
    },
  ),
),

                        //Dni and password TextField here
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              DniTextField(
                                size: size,
                                controller:
                                    dniController, // Pasar el controlador
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              PasswordTextField(
                                size: size,
                                controller:
                                    passController, // Pasar el controlador de la contraseña
                                obscureText: obscureText,
                                toggleObscureText: toggleObscureText,
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                              buildRemember(size),
                            ],
                          ),
                        ),

                        //sign in button & continue with text here
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 4,
                              ),
                              buildContinueText(),
                            ],
                          ),
                        ),

                        //footer section. google, facebook button and sign up text here
                        Expanded(
                          flex: 3,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              signInGoogleFacebookButton(size),
                              const SizedBox(
                                height: 12,
                              ),
                              buildFooter(size),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget logo(double height_, double width_) {
    return SvgPicture.asset(
      'assets/images/logo.png',
      height: height_,
      width: width_,
    );
  }

  Widget richText(double fontSize) {
    return Text.rich(
      TextSpan(
        style: GoogleFonts.inter(
          fontSize: 23.12,
          color: Colors.white,
          letterSpacing: 1.999999953855673,
        ),
        children: [
          WidgetSpan(
            child: Image.asset(
              'assets/images/logo.png', // Replace with your image path
              height: 70, // Adjust height as needed
              width: 70, // Adjust width as needed
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget DniTextField({
    required Size size,
    required TextEditingController controller,
  }) {
    return Container(
      alignment: Alignment.center,
      height: size.height / 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: const Color(0xFF4DA1B0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Mail icon
            const Icon(
              Icons.mail_rounded,
              color: Colors.white70,
            ),
            const SizedBox(
              width: 16,
            ),
            // Divider SVG
            SvgPicture.string(
              '<svg viewBox="99.0 332.0 1.0 15.5" ><path transform="translate(99.0, 332.0)" d="M 0 0 L 0 15.5" fill="none" fill-opacity="0.6" stroke="#ffffff" stroke-width="1" stroke-opacity="0.6" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
              width: 1.0,
              height: 15.5,
            ),
            const SizedBox(
              width: 16,
            ),
            // DNI textField
            Expanded(
              child: TextField(
                controller: controller, // Asignar el controlador
                maxLines: 1,
                cursorColor: Colors.white70,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(
                  fontSize: 14.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Ingrese Usuario o id',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14.0,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget PasswordTextField({
    required Size size,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback toggleObscureText,
  }) {
    return Container(
      alignment: Alignment.center,
      height: size.height / 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: const Color(0xFF4DA1B0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Lock icon
            const Icon(
              Icons.lock,
              color: Colors.white70,
            ),
            const SizedBox(
              width: 16,
            ),
            // Divider SVG
            SvgPicture.string(
              '<svg viewBox="99.0 332.0 1.0 15.5" ><path transform="translate(99.0, 332.0)" d="M 0 0 L 0 15.5" fill="none" fill-opacity="0.6" stroke="#ffffff" stroke-width="1" stroke-opacity="0.6" stroke-miterlimit="4" stroke-linecap="butt" /></svg>',
              width: 1.0,
              height: 15.5,
            ),
            const SizedBox(
              width: 16,
            ),
            // Password textField
            Expanded(
              child: TextField(
                controller: controller, // Asignar el controlador
                maxLines: 1,
                cursorColor: Colors.white70,
                keyboardType: TextInputType.visiblePassword,
                obscureText: obscureText, // Control de visibilidad
                style: GoogleFonts.inter(
                  fontSize: 14.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Ingrese la contraseña',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14.0,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  suffixIcon: GestureDetector(
                    onTap: toggleObscureText, // Alternar visibilidad
                    child: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white70,
                    ),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRemember(Size size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment
          .center, // Asegura que el checkbox y el texto estén alineados
      children: <Widget>[
        Container(
          alignment: Alignment.center,
          width: 17.0,
          height: 17.0,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            shape: BoxShape.rectangle,
          ),
          child: const Icon(Icons.check, size: 12.0, color: Colors.white),
        ),
        const SizedBox(width: 8), // Reduce este valor (por ejemplo, a 4)
        Text(
          'Recordarme',
          style: GoogleFonts.inter(
            fontSize: 14.0,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget buildContinueText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const Expanded(
            child: Divider(
          color: Colors.white,
        )),
        Expanded(
          child: Text(
            'SELECCIONE',
            style: GoogleFonts.inter(
              fontSize: 12.0,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const Expanded(
            child: Divider(
          color: Colors.white,
        )),
      ],
    );
  }

  Widget signInGoogleFacebookButton(Size size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        //sign in google button
        Container(
          alignment: Alignment.center,
          width: size.width / 2.8,
          height: size.height / 13,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              width: 1.0,
              color: Colors.white,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Salir',
                style: GoogleFonts.inter(
                  fontSize: 14.0,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(
          width: 16,
        ),

        //sign in facebook button
        GestureDetector(
          onTap: isLoading
              ? null
              : () {
                  handleLogin();
                },
          child: Container(
            alignment: Alignment.center,
            width: size.width / 2.8,
            height: size.height / 13,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0), // Mismo radio
              border: Border.all(
                width: 1.0,
                color: Colors.white, // Borde blanco como el diseño inicial
              ),
              // Sin color de fondo para que sea transparente
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Ingresar',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14.0,
                      color: Colors.white, // Color del texto
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget buildFooter(Size size) {
    return Align(
      alignment: Alignment.center,
      child: Text.rich(
        TextSpan(
          style: GoogleFonts.nunito(
            fontSize: 16.0,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
