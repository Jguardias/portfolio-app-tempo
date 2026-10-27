import 'dart:math';
import 'package:tempo/config/constants/category_quotes.dart';
import 'package:tempo/config/constants/quotes_constants.dart';

class QuoteService {
  static final Random _random = Random();
  static String? _lastQuote;

  /// Elige una frase según categoría, modo, hora y datos de uso.
  /// Si no hay nada específico, usa las frases generales.
  String getRandomQuote({
    String? category,
    bool onOpen = false,
    String? appName,
    int minutes = 0,
    DateTime? now,
  }) {
    final hour = (now ?? DateTime.now()).hour;
    final isNight = hour >= 22 || hour < 5;

    final categoryPool =
        category == null ? null : CategoryQuotes.byCategory[category];

    final pool = <String>[
      if (categoryPool != null && categoryPool.isNotEmpty)
        ...categoryPool
      else
        ...QuotesConstants.wellnessQuotes,
      ...(onOpen ? CategoryQuotes.onOpen : CategoryQuotes.byTime),
      if (isNight) ...CategoryQuotes.night,
    ];

    final candidates = pool.where((q) {
      if (q.contains('{min}') && minutes <= 0) return false;
      if (q.contains('{app}') && (appName == null || appName.isEmpty)) {
        return false;
      }
      return true;
    }).toList();

    final source =
        candidates.isEmpty ? QuotesConstants.wellnessQuotes : candidates;

    // Evita repetir la misma frase dos veces seguidas
    String pick = source[_random.nextInt(source.length)];
    for (var i = 0; i < 3 && source.length > 1 && pick == _lastQuote; i++) {
      pick = source[_random.nextInt(source.length)];
    }
    _lastQuote = pick;

    return pick
        .replaceAll('{app}', appName ?? '')
        .replaceAll('{min}', _formatMinutes(minutes));
  }

  String _formatMinutes(int m) {
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final rest = m % 60;
    return rest == 0 ? '$h h' : '$h h $rest min';
  }
}