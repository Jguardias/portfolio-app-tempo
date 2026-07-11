import 'dart:math';
import 'package:tempo/config/constants/quotes_constants.dart';

class QuoteService {
  String getRandomQuote() {
    return QuotesConstants.wellnessQuotes[Random().nextInt(QuotesConstants.wellnessQuotes.length)];
  }
}