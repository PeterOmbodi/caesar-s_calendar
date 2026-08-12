import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PublicProfileCubit registration uses its default operation timeout', () {
    final config = File('lib/injection.config.dart').readAsStringSync();

    expect(config, contains('gh.factory<_i783.PublicProfileCubit>'));
    expect(config, isNot(contains('operationTimeout: gh<Duration>()')));
  });
}
