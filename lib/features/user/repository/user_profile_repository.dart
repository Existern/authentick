import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/update_profile_request.dart';
import '../model/user_profile_response.dart';
import '../service/user_service.dart';

part 'user_profile_repository.g.dart';

const String _userProfileKey = 'user_profile_cache';

@riverpod
class UserProfileRepository extends _$UserProfileRepository {
  @override
  Future<UserProfileData?> build() async {
    // Always fetch fresh profile data first to ensure we have the latest image URLs
    // This prevents loading stale image URLs from cache
    try {
      return await _fetchAndCacheProfile();
    } catch (e) {
      // If fetch fails, fall back to cached profile if available
      final cachedProfile = await _loadCachedProfile();
      if (cachedProfile != null) {
        // Still try to fetch fresh data in background for next time
        _fetchAndCacheProfile();
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
}
