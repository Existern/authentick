import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mvvm_riverpod/features/onboarding/service/contacts_service.dart';

void main() {
  group('ContactsService Tests', () {
    test('ContactWithEmails model should work correctly', () {
      final contact = ContactWithEmails(
        name: 'John Doe',
        emails: ['john@example.com', 'john.doe@work.com'],
        phoneNumber: '+1234567890',
      );

      expect(contact.name, equals('John Doe'));
      expect(contact.emails.length, equals(2));
      expect(contact.emails.contains('john@example.com'), isTrue);
      expect(contact.phoneNumber, equals('+1234567890'));
    });

    test('ContactWithEmails can handle empty emails', () {
      final contact = ContactWithEmails(name: 'Jane Smith', emails: []);

      expect(contact.name, equals('Jane Smith'));
      expect(contact.emails.isEmpty, isTrue);
      expect(contact.phoneNumber, isNull);
    });
  });
}
