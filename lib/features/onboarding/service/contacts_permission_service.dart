import 'package:permission_handler/permission_handler.dart';

class ContactsPermissionService {
  static Future<bool> requestContactsPermission() async {
    final permission = Permission.contacts;
    final status = await permission.request();

    return status.isGranted;
  }

  static Future<bool> checkContactsPermission() async {
    final permission = Permission.contacts;
    final status = await permission.status;

    return status.isGranted;
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
}
