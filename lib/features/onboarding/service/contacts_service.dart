import 'dart:developer' as developer;
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactWithEmails {
  final String name;
  final List<String> emails;
  final String? phoneNumber;

  ContactWithEmails({
    required this.name,
    required this.emails,
    this.phoneNumber,
  });
}

class ContactsService {
  static Future<bool> requestContactsPermission() async {
    try {
      developer.log('ContactsService: Requesting contacts permission...');

      // Request permission with write access (some systems require this)
      final hasPermission = await FlutterContacts.requestPermission(
        readonly: false,
      );
      developer.log('ContactsService: Permission result = $hasPermission');

      if (!hasPermission) {
        // Try with readonly access as fallback
        developer.log('ContactsService: Trying readonly permission...');
        final readonlyPermission = await FlutterContacts.requestPermission(
          readonly: true,
        );
        developer.log(
          'ContactsService: Readonly permission result = $readonlyPermission',
        );
        return readonlyPermission;
      }

      return hasPermission;
    } catch (error) {
      developer.log('ContactsService: Error requesting permission: $error');
      return false;
    }
  }

  static Future<List<ContactWithEmails>> getAllContactsWithEmails() async {
    try {
      developer.log('ContactsService: Starting to get contacts...');

      // Check permission first
      final hasPermission = await requestContactsPermission();
      if (!hasPermission) {
        developer.log(
          'ContactsService: No contacts permission, cannot proceed',
        );
        return [];
      }

      developer.log(
        'ContactsService: Permission confirmed, fetching contacts...',
      );

      // Get all contacts with properties (emails, phones, etc.)
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false, // We don't need photos for now
      );

      developer.log(
        'ContactsService: Raw contacts fetched: ${contacts.length}',
      );

      final contactsWithEmails = <ContactWithEmails>[];

      for (var contact in contacts) {
        // Get the display name
        String displayName = '';
        if (contact.name.first.isNotEmpty) {
          displayName = contact.name.first;
          if (contact.name.last.isNotEmpty) {
            displayName += ' ${contact.name.last}';
          }
        } else if (contact.displayName.isNotEmpty) {
          displayName = contact.displayName;
        }

        // Skip contacts without names
        if (displayName.isEmpty) {
          developer.log('ContactsService: Skipping contact with no name');
          continue;
        }

        // Get all email addresses
        final emails = contact.emails
            .map((e) => e.address)
            .where((email) => email.isNotEmpty)
            .toList();

        // Get primary phone number (optional)
        String? phoneNumber;
        if (contact.phones.isNotEmpty) {
          phoneNumber = contact.phones.first.number;
        }

        // Log contact info for debugging
        if (emails.isNotEmpty) {
          developer.log(
            'ContactsService: ✅ $displayName - Emails: ${emails.join(", ")}${phoneNumber != null ? " - Phone: $phoneNumber" : ""}',
          );
        } else {
          developer.log(
            'ContactsService: ❌ $displayName - No emails${phoneNumber != null ? " - Phone: $phoneNumber" : ""}',
          );
        }

        // Add to list (even if no emails - we want to show all contacts)
        contactsWithEmails.add(
          ContactWithEmails(
            name: displayName,
            emails: emails,
            phoneNumber: phoneNumber,
          ),
        );
      }

      // Sort by name
      contactsWithEmails.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      final contactsWithEmailCount = contactsWithEmails
          .where((c) => c.emails.isNotEmpty)
          .length;
      developer.log(
        'ContactsService: 📊 SUMMARY: $contactsWithEmailCount contacts with emails out of ${contactsWithEmails.length} total contacts',
      );

      return contactsWithEmails;
    } catch (error) {
      developer.log('ContactsService: ❗ Error getting contacts: $error');
      return [];
    }
  }

  static Future<List<ContactWithEmails>> getContactsWithEmailsOnly() async {
    final allContacts = await getAllContactsWithEmails();
    return allContacts.where((contact) => contact.emails.isNotEmpty).toList();
  }

  static void printAllContactsWithEmails(List<ContactWithEmails> contacts) {
    developer.log('=== CONTACTS WITH EMAILS ===');
    for (var i = 0; i < contacts.length; i++) {
      final contact = contacts[i];
      developer.log('${i + 1}. Name: ${contact.name}');
      if (contact.emails.isNotEmpty) {
        developer.log('   Emails: ${contact.emails.join(", ")}');
      } else {
        developer.log('   No emails');
      }
      if (contact.phoneNumber != null) {
        developer.log('   Phone: ${contact.phoneNumber}');
      }
      developer.log('---');
    }
    developer.log('=== END CONTACTS ===');
  }
}
