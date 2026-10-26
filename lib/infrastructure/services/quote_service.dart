import 'dart:math';
import 'package:tempo/config/constants/category_quotes.dart';
import 'package:tempo/config/constants/quotes_constants.dart';

class QuoteService {
  final Random _random = Random();

  /// Frase de la categoría si existe; si no, una general.
  String getRandomQuote({String? category}) {
    final byCategory = category == null ? null : CategoryQuotes.byCategory[category];
    final pool = (byCategory != null && byCategory.isNotEmpty)
        ? byCategory
        : QuotesConstants.wellnessQuotes;
    return pool[_random.nextInt(pool.length)];
  }
}