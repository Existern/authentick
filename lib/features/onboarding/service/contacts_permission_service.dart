import 'dart:developer' as developer;
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsPermissionService {
  static Future<bool> requestContactsPermission() async {
    try {
      developer.log('Requesting contacts permission...');

      // First check current permission status
      final currentPermission = await FlutterContacts.requestPermission(
        readonly: false,
      );
      developer.log(
        'FlutterContacts.requestPermission result: $currentPermission',
      );

      if (currentPermission) {
        developer.log('Contacts permission GRANTED via flutter_contacts');
        return true;
      }

      // If flutter_contacts didn't work, try permission_handler as fallback
      developer.log(
        'Flutter contacts permission failed, trying permission_handler...',
      );
      final permission = Permission.contacts;
      final status = await permission.request();

      developer.log('Permission handler status: $status');
      final granted = status.isGranted;
      developer.log('Permission handler granted: $granted');

      if (granted) {
        developer.log('Contacts permission GRANTED via permission_handler');
      } else {
        developer.log('Contacts permission DENIED by both methods');
      }

      return granted;
    } catch (error) {
      developer.log('Error requesting contacts permission: $error');
      return false;
    }
  }

  static Future<bool> checkContactsPermission() async {
    try {
      // Check with both methods
      final flutterContactsHasPermission =
          await FlutterContacts.requestPermission(readonly: true);
      developer.log(
        'Flutter contacts permission check: $flutterContactsHasPermission',
      );

      final permission = Permission.contacts;
      final status = await permission.status;
      final permissionHandlerGranted = status.isGranted;
      developer.log('Permission handler check: $permissionHandlerGranted');

      return flutterContactsHasPermission || permissionHandlerGranted;
    } catch (error) {
      developer.log('Error checking contacts permission: $error');
      return false;
    }
  }

  static Future<bool> isContactsPermissionDenied() async {
    final permission = Permission.contacts;
    final status = await permission.status;

    return status.isDenied;
  }

  static Future<bool> isContactsPermissionPermanentlyDenied() async {
    final permission = Permission.contacts;
    final status = await permission.status;

    return status.isPermanentlyDenied;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }

  // Debug method to check all permission states
  static Future<void> debugPermissionStates() async {
    try {
      developer.log('=== PERMISSION DEBUG INFO ===');

      // Check flutter_contacts permission
      final flutterContactsPermission = await FlutterContacts.requestPermission(
        readonly: true,
      );
      developer.log(
        'FlutterContacts permission (readonly): $flutterContactsPermission',
      );

      // Check permission_handler states
      final permission = Permission.contacts;
      final status = await permission.status;
      developer.log('PermissionHandler status: $status');
      developer.log('PermissionHandler isGranted: ${status.isGranted}');
      developer.log('PermissionHandler isDenied: ${status.isDenied}');
      developer.log(
        'PermissionHandler isPermanentlyDenied: ${status.isPermanentlyDenied}',
      );
      developer.log('PermissionHandler isRestricted: ${status.isRestricted}');
      developer.log('PermissionHandler isLimited: ${status.isLimited}');

      developer.log('=== END PERMISSION DEBUG ===');
    } catch (error) {
      developer.log('Error in permission debug: $error');
    }
  }
}
