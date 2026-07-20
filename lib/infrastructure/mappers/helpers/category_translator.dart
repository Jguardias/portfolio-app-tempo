class CategoryTranslator {
  static String mapCategory(int? categoryCode) {
    switch (categoryCode) {
      case 0: return 'Juegos';
      case 1: return 'Audio';
      case 2: return 'Video';
      case 3: return 'Imagen';
      case 4: return 'Redes Sociales';
      case 5: return 'Noticias';
      case 6: return 'Mapas';
      case 7: return 'Productividad';
      case 8: return 'Accesibilidad';
      default: return 'Otro'; 
    }
  }
}