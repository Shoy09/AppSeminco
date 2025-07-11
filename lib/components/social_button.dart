import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class SignInOneSocialButton extends StatelessWidget {
  final Size size; // Marked as final
  final String iconPath; // Marked as final
  final String text; // Marked as final

  SignInOneSocialButton({
    Key? key,
    required this.size,
    required this.iconPath,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size.height / 12,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40.0),
        border: Border.all(
          width: 1.0,
          color: const Color(0xFF134140),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            flex: 1,
            child: SvgPicture.asset(iconPath),
          ),
          Expanded(
            flex: 2,
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 16.0,
                color: const Color(0xFF134140),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
