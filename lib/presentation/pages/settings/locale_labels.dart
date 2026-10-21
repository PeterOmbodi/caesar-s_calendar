import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:flutter/widgets.dart';

typedef LocaleLabel = ({String native, String english});

const Map<String, LocaleLabel> localeLabels = {
  'bg': (native: 'Български', english: 'Bulgarian'),
  'cs': (native: 'Čeština', english: 'Czech'),
  'da': (native: 'Dansk', english: 'Danish'),
  'de': (native: 'Deutsch', english: 'German'),
  'en': (native: 'English', english: 'English'),
  'es': (native: 'Español', english: 'Spanish'),
  'et': (native: 'Eesti', english: 'Estonian'),
  'fi': (native: 'Suomi', english: 'Finnish'),
  'fr': (native: 'Français', english: 'French'),
  'hr': (native: 'Hrvatski', english: 'Croatian'),
  'hu': (native: 'Magyar', english: 'Hungarian'),
  'is': (native: 'Íslenska', english: 'Icelandic'),
  'it': (native: 'Italiano', english: 'Italian'),
  'lt': (native: 'Lietuvių', english: 'Lithuanian'),
  'lv': (native: 'Latviešu', english: 'Latvian'),
  'mk': (native: 'Македонски', english: 'Macedonian'),
  'nb': (native: 'Norsk Bokmal', english: 'Norwegian Bokmal'),
  'nl': (native: 'Nederlands', english: 'Dutch'),
  'pl': (native: 'Polski', english: 'Polish'),
  'pt': (native: 'Português', english: 'Portuguese'),
  'ro': (native: 'Română', english: 'Romanian'),
  'sk': (native: 'Slovenčina', english: 'Slovak'),
  'sl': (native: 'Slovenščina', english: 'Slovenian'),
  'sq': (native: 'Shqip', english: 'Albanian'),
  'sv': (native: 'Svenska', english: 'Swedish'),
  'uk': (native: 'Українська', english: 'Ukrainian'),
};

String languageSectionTitle(final Locale currentLocale) =>
    currentLocale.languageCode == 'en' ? S.current.language : '${S.current.language} (Language)';
