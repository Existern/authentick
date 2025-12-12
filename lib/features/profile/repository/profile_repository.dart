import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/constants.dart';
import '../model/confirm_upload_request.dart';
import '../model/presigned_upload_request.dart';

import '../model/profile.dart';
import '../model/profile_update_request.dart';
import '../model/profile_update_response.dart';
import '../service/profile_service.dart';

part 'profile_repository.g.dart';

@riverpod
ProfileRepository profileRepository(Ref ref) {
  final profileService = ref.watch(profileServiceProvider);
  return ProfileRepository(profileService);
}

class ProfileRepository {
  final ProfileService _profileService;
  static const String _profileKey = 'profile';
  static const String _showPremiumKey = 'show_premium';

  const ProfileRepository(this._profileService);

  /// Update user profile
  /// Calls the PUT /users/profile endpoint
  Future<ProfileUpdateResponse> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? gender,
    String? bio,
    String? location,
    String? phoneNumber,
    String? profileImage,
    String? coverImage,
    String? invitedByCode,
  }) async {
    try {
      debugPrint('${Constants.tag} [ProfileRepository] 🔄 Updating profile...');

      if (dateOfBirth != null) {
        debugPrint(
          '${Constants.tag} [ProfileRepository] Date of Birth: $dateOfBirth',
        );
      }

      final request = ProfileUpdateRequest(
        username: username,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        bio: bio,
        location: location,
        phoneNumber: phoneNumber,
        profileImage: profileImage,
        coverImage: coverImage,
        invitedByCode: invitedByCode,
      );

      final response = await _profileService.updateProfile(request);

      debugPrint('${Constants.tag} [ProfileRepository] 📦 Response received');
      debugPrint(
        '${Constants.tag} [ProfileRepository] Success: ${response.success}',
      );
      debugPrint(
        '${Constants.tag} [ProfileRepository] Updated DOB: ${response.data.dateOfBirth}',
      );
      debugPrint(
        '${Constants.tag} [ProfileRepository] Username: ${response.data.username}',
      );
      debugPrint(
        '${Constants.tag} [ProfileRepository] Request ID: ${response.meta.requestId}',
      );

      return response;
    } catch (error, stackTrace) {
      debugPrint('${Constants.tag} [ProfileRepository] ❌ EXCEPTION CAUGHT ❌');
      debugPrint(
        '${Constants.tag} [ProfileRepository] Error Type: ${error.runtimeType}',
      );
      debugPrint('${Constants.tag} [ProfileRepository] Error Details: $error');
      debugPrint('${Constants.tag} [ProfileRepository] Stack Trace:');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  /// Get local profile from SharedPreferences
  Future<Profile?> get() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);

      if (profileJson == null) {
        debugPrint(
          '${Constants.tag} [ProfileRepository] No profile found in local storage',
        );
        return null;
      }

      final profileMap = jsonDecode(profileJson) as Map<String, dynamic>;
      final profile = Profile.fromJson(profileMap);

      debugPrint(
        '${Constants.tag} [ProfileRepository] Profile loaded from local storage',
      );
      return profile;
    } catch (error, stackTrace) {
      debugPrint(
        '${Constants.tag} [ProfileRepository] Error loading profile: $error',
      );
      debugPrint('$stackTrace');
      return null;
    }
  }

  /// Update local profile in SharedPreferences
  Future<void> update(Profile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(profile.toJson());
      await prefs.setString(_profileKey, profileJson);

      debugPrint(
        '${Constants.tag} [ProfileRepository] Profile saved to local storage',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '${Constants.tag} [ProfileRepository] Error saving profile: $error',
      );
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  /// Check if premium dialog should be shown
  Future<bool> isShowPremium() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_showPremiumKey) ?? true;
    } catch (error) {
      debugPrint(
        '${Constants.tag} [ProfileRepository] Error checking premium flag: $error',
      );
      return true;
    }
  }

  /// Set that premium dialog has been shown
  Future<void> setIsShowPremium() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showPremiumKey, false);

      debugPrint('${Constants.tag} [ProfileRepository] Premium flag set');
    } catch (error) {
      debugPrint(
        '${Constants.tag} [ProfileRepository] Error setting premium flag: $error',
      );
    }
  }

  /// Upload profile picture using presigned URL flow
  /// 1. Get presigned URL
  /// 2. Upload image to S3
  /// 3. Confirm upload
  Future<String> uploadProfilePicture(
    String filePath,
    String contentType,
  ) async {
    try {
      debugPrint(
        '${Constants.tag} [ProfileRepository] 🔄 Starting profile picture upload...',
      );

      // Step 1: Get presigned URL
      final presignedRequest = PresignedUploadRequest(
        contentType: contentType,
        imageType: 'profile',
      );

      final presignedResponse = await _profileService.getPresignedUploadUrl(
        presignedRequest,
      );

      debugPrint('${Constants.tag} [ProfileRepository] ✅ Got presigned URL');
      debugPrint(
        '${Constants.tag} [ProfileRepository] Image URL: ${presignedResponse.data.imageUrl}',
      );

      // Step 2: Upload to S3 using presigned URL
      if (presignedResponse.data.presignedUrl == null) {
        throw Exception('Presigned URL is null');
      }

      await _profileService.uploadImageToPresignedUrl(
        presignedResponse.data.presignedUrl!,
        filePath,
        contentType,
      );

      debugPrint('${Constants.tag} [ProfileRepository] ✅ Image uploaded to S3');

      // Step 3: Confirm upload
      final confirmRequest = ConfirmUploadRequest(
        imageUrl: presignedResponse.data.imageUrl,
      );

      final confirmResponse = await _profileService.confirmUpload(
        confirmRequest,
        'profile',
      );

      debugPrint('${Constants.tag} [ProfileRepository] ✅ Upload confirmed');
      debugPrint(
        '${Constants.tag} [ProfileRepository] Final Image URL: ${confirmResponse.data.imageUrl}',
      );

      return confirmResponse.data.imageUrl;
    } catch (error, stackTrace) {
      debugPrint('${Constants.tag} [ProfileRepository] ❌ UPLOAD FAILED ❌');
      debugPrint(
        '${Constants.tag} [ProfileRepository] Error Type: ${error.runtimeType}',
      );
      debugPrint('${Constants.tag} [ProfileRepository] Error Details: $error');
      debugPrint('${Constants.tag} [ProfileRepository] Stack Trace:');
      debugPrint('$stackTrace');
      rethrow;
    }
  }
}
