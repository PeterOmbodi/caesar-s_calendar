import 'dart:convert';

import 'package:crypto/crypto.dart';

String configIdFor(final String configJson) => sha256.convert(utf8.encode(configJson)).toString();
