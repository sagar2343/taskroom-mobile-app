class NumberToWordsConverter {
  static String convert(num number) {
    int integerPart = number.floor();
    int decimalPart = ((number - integerPart) * 100).round();

    String integerWords = _convertIntegerToWords(integerPart);
    String decimalWords = _convertDecimalToWords(decimalPart);

    String result = integerWords;
    if (decimalPart > 0) {
      result += ' and $decimalWords' ' Only';
    }

    return result;
  }

  static String _convertIntegerToWords(int number) {
    if (number == 0) {
      return 'Zero';
    }

    List<String> units = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine'
    ];

    List<String> teens = [
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen'
    ];

    List<String> tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety'
    ];

    String word = '';

    if (number < 10) {
      word = units[number];
    } else if (number < 20) {
      word = teens[number - 10];
    } else if (number < 100) {
      word = tens[number ~/ 10] +
          (number % 10 != 0 ? ' ${units[number % 10]}' : '');
    } else if (number < 1000) {
      word = '${units[number ~/ 100]} Hundred ${convert(number % 100)}';
    } else if (number < 1000000) {
      word = '${convert(number ~/ 1000)} Thousand ${convert(number % 1000)}';
    } else if (number < 1000000000) {
      word =
          '${convert(number ~/ 1000000)} Million ${convert(number % 1000000)}';
    } else {
      word = 'Number too large';
    }

    return word;
  }

  static String _convertDecimalToWords(int number) {
    if (number == 0) {
      return 'Zero';
    }

    List<String> units = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine'
    ];

    List<String> tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety'
    ];

    String word = '';

    if (number < 10) {
      word = units[number];
    } else if (number < 20) {
      word = 'One${units[number - 10]}';
    } else if (number < 100) {
      word = tens[number ~/ 10] +
          (number % 10 != 0 ? ' ${units[number % 10]}' : '');
    }

    return word;
  }
}
