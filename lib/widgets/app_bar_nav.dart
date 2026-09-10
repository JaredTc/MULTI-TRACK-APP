import 'package:flutter/material.dart';
import 'package:multitracks/config/app_theme.dart';

class AppBarNav extends StatelessWidget implements PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Cuadro verde con bordes redondeados e ícono
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(
                10,
              ), // Bordes redondeados del contenedor
            ),
            child: const Icon(
              Icons.graphic_eq, // Ícono de ondas de audio
              color: Colors.black,
              size: 26,
            ),
          ),
          const SizedBox(width: 14), // Espacio entre el ícono y el texto
          // Texto en negrita
          const Text(
            'MULTITRACK',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight:
                  FontWeight.w900, // Extra negrita para igualar el diseño
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),

      backgroundColor: AppTheme.secondaryColor,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
