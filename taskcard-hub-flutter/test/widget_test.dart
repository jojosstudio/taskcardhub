import 'package:flutter_test/flutter_test.dart';

import 'package:taskcard_hub_flutter/main.dart';

void main() {
  test('creates the Taskcard Hub application', () {
    expect(const TaskcardHubApp(), isA<TaskcardHubApp>());
  });
}
