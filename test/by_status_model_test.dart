import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/data/models/project_models.dart';

void main() {
  group('ByStatus.fromJson', () {
    test('parses numeric status by coercing to string', () {
      final json = {'status': 1, 'label': 'active', 'count': 5};

      final model = ByStatus.fromJson(json);
      expect(model.status, '1');
      expect(model.label, 'active');
      expect(model.count, 5);
    });

    test('parses string status', () {
      final json = {'status': 'completed', 'label': 'Completed', 'count': 3};

      final model = ByStatus.fromJson(json);
      expect(model.status, 'completed');
      expect(model.label, 'Completed');
      expect(model.count, 3);
    });
  });
}
