import 'package:flutter_riverpod/flutter_riverpod.dart';
/// Almacena la cadena de texto de búsqueda compartida para filtrar aplicaciones
final appSearchQueryHomeProvider = StateProvider<String>((ref) => '');
final appSearchQueryConfigProvider = StateProvider<String>((ref) => '');