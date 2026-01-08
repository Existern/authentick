import '../../features/profile/model/profile.dart';

extension ProfileExtension on Profile? {
  bool get isPremium {
    // Premium feature removed - always return false
    return false;
  }
}
