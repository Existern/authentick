import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/delete_account_response.dart';
import '../model/update_profile_request.dart';
import '../model/user_profile_response.dart';
import '../service/user_service.dart';

part 'user_profile_repository.g.dart';

const String _userProfileKey = 'user_profile_cache';

@Riverpod(keepAlive: true)
class UserProfileRepository extends _$UserProfileRepository {
  @override
  Future<UserProfileData?> build() async {
    // Always fetch fresh profile data from API on build
    // This ensures profile image and other data are always up-to-date
    try {
      return await _fetchAndCacheProfile();
    } catch (e) {
      // If API fails, try to load from cache as fallback
      final cachedProfile = await _loadCachedProfile();
      if (cachedProfile != null) {
        return cachedProfile;
      }
      rethrow;
    }
  }

  /// Load profile from SharedPreferences cache
  Future<UserProfileData?> _loadCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_userProfileKey);
      if (cachedJson != null) {
        final Map<String, dynamic> json = jsonDecode(cachedJson);
        return UserProfileData.fromJson(json);
      }
    } catch (e) {
      // Ignore cache errors and fetch fresh data
    }
    return null;
  }

  /// Fetch profile from API and cache it
  Future<UserProfileData> _fetchAndCacheProfile() async {
    final userService = ref.read(userServiceProvider);
    final response = await userService.getProfile();

    // Cache the profile data
    await _cacheProfile(response.data);

    return response.data;
  }

  /// Save profile to SharedPreferences cache
  Future<void> _cacheProfile(UserProfileData profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(profile.toJson());
      await prefs.setString(_userProfileKey, jsonString);
    } catch (e) {
      // Ignore cache save errors
    }
  }

  /// Refresh profile from API
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _fetchAndCacheProfile();
    });
  }

  /// Clear cached profile
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userProfileKey);
    } catch (e) {
      // Ignore cache clear errors
    }
  }

  /// Get cached profile synchronously (if available)
  UserProfileData? getCachedProfileSync() {
    return state.value;
  }

  /// Update profile
  /// Throws exception if update fails (e.g., username already taken)
  Future<UserProfileData> updateProfile(UpdateProfileRequest request) async {
    final userService = ref.read(userServiceProvider);
    final response = await userService.updateProfile(request);

    // Update cache with new data
    await _cacheProfile(response.data);

    // Update state
    state = AsyncValue.data(response.data);

    return response.data;
  }

  /// Delete profile or cover image
  /// DELETE /users/image?type=profile
  Future<void> deleteImage(String imageType) async {
    final userService = ref.read(userServiceProvider);
    await userService.deleteImage(imageType);

    // Refresh profile to get updated data without the image
    await refresh();
  }

  /// Request account deletion
  /// DELETE /users/account
  /// 
  /// Initiates the account deletion process. The account will be hidden
  /// and scheduled for permanent deletion in 30 days.
  /// 
  /// After requesting deletion:
  /// - User's profile will be hidden from other users
  /// - User can still restore their account within 30 days
  /// - After 30 days, the account and all associated data will be permanently deleted
  /// 
  /// Returns [DeleteAccountResponse] with confirmation message.
  Future<DeleteAccountResponse> deleteAccount() async {
    final userService = ref.read(userServiceProvider);
    final response = await userService.deleteAccount();

    // Clear local cache since user is being deleted
    await clearCache();

    return response;
  }

  /// Restore account that was scheduled for deletion
  /// POST /users/account/restore
  /// 
  /// Cancels a pending account deletion request and reactivates the account.
  /// Can only be called during the 30-day grace period after deletion request.
  /// 
  /// After restoration:
  /// - User's profile will be visible again
  /// - All data will be retained
  /// - User can use the app normally
  /// 
  /// Returns [DeleteAccountResponse] with confirmation message.
  Future<DeleteAccountResponse> restoreAccount() async {
    final userService = ref.read(userServiceProvider);
    final response = await userService.restoreAccount();

    // Refresh profile to get restored account data
    await refresh();

    return response;
  }
}
