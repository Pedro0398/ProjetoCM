import 'package:flutter/material.dart';

/// Notificador para a página selecionada na NavBar
ValueNotifier<int> selectedPageNotifier = ValueNotifier<int>(0);

/// Notificador para alternar entre modo claro e escuro
ValueNotifier<bool> darkModeNotifier = ValueNotifier<bool>(false);

