import 'package:flutter_test/flutter_test.dart';
import 'package:quickfire_student/models/student.dart';

void main() {
  group('Student Model Tests', () {
    test('Student.fromJson should create a valid Student object', () {
      final json = {
        'id': 1,
        'registration_number': 'KIU/2019/2001',
        'first_name': 'John',
        'last_name': 'Doe',
        'email': 'john.doe@example.com',
        'is_active': true,
        'college_id': 101,
        'college_name': 'Engineering'
      };

      final student = Student.fromJson(json);

      expect(student.id, 1);
      expect(student.registrationNumber, 'KIU/2019/2001');
      expect(student.fullName, 'John Doe');
      expect(student.collegeName, 'Engineering');
    });

    test('Student.toJson should return a valid map', () {
      final student = Student(
        id: 2,
        registrationNumber: 'KIU/2019/P001',
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane@example.com',
        isActive: true,
      );

      final json = student.toJson();

      expect(json['id'], 2);
      expect(json['registration_number'], 'KIU/2019/P001');
      expect(json['first_name'], 'Jane');
    });

    test('Student.copyWith should update fields correctly', () {
      final student = Student(
        id: 3,
        registrationNumber: 'KIU/2019/P002',
        firstName: 'Alice',
        lastName: 'Wand',
        email: 'alice@example.com',
        isActive: true,
      );

      final updated = student.copyWith(collegeName: 'Science');

      expect(updated.collegeName, 'Science');
      expect(updated.firstName, 'Alice'); // Should be preserved
    });
  });
}
