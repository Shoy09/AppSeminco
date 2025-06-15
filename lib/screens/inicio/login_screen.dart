import 'package:app_seminco/database/database_helper.dart';
import 'package:app_seminco/screens/Dash/reporte_sreen.dart';
import 'package:app_seminco/services/api_service.dart';
import 'package:app_seminco/services/user_service.dart';
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

  void toggleObscureText() {
    setState(() {
      obscureText = !obscureText;
    });
  }

Future<void> handleLogin() async {
  setState(() {
    isLoading = true;
  });

  try {
    final apiService = ApiService();
    final userService = UserService();
    final token = await apiService.login(dniController.text, passController.text);

    final userData = await userService.getUserProfile(token);
    
    // 👉 Establecer el DNI antes de usar la base de datos
    await DatabaseHelper().setCurrentUserDni(dniController.text);

    await DatabaseHelper().saveUser(userData, passController.text);
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ReporteScreen(token: token, dni: dniController.text)),
    );
  } catch (e) {
    print("Error en el login online: $e");

    // Login offline
    await DatabaseHelper().setCurrentUserDni(dniController.text); // 👈 También aquí
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
