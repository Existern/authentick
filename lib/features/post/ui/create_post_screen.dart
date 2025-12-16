import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

import '../repository/post_repository.dart';
import 'widgets/privacy_selector.dart';
import 'widgets/location_privacy_dialog.dart';
import '../../onboarding/view_model/onboarding_view_model.dart';

/// Screen for creating a new post
/// This screen will be used both during onboarding and in the main app
/// Opens the camera by default when the screen is loaded
class CreatePostScreen extends ConsumerStatefulWidget {
  final bool isOnboarding;
  final VoidCallback? onComplete;

  const CreatePostScreen({
    super.key,
    this.isOnboarding = false,
    this.onComplete,
  });

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  XFile? _selectedImage;
  bool _isLoading = false;
  bool _isLocationLoading = false;
  String? _location;
  double? _latitude;
  double? _longitude;
  Placemark? _placemark; // Store placemark for privacy options
  LocationPrivacyLevel _locationPrivacyLevel = LocationPrivacyLevel.exact;
  PostPrivacy _privacy = PostPrivacy.everyone;

  @override
  void initState() {
    super.initState();
    // Open camera automatically when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCamera();
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  /// Get current device location automatically
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location services are disabled. Please enable them to auto-tag your location.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _location = null;
          _latitude = null;
          _longitude = null;
          _isLocationLoading = false;
        });
        return;
      }

      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permission denied. Your post will not include location information.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          setState(() {
            _location = null;
            _latitude = null;
            _longitude = null;
            _isLocationLoading = false;
          });
          return;
        }
      }

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Convert coordinates to readable address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;

        // Store the placemark for privacy options
        _placemark = placemark;

        // Create exact location string with all available details
        String exactLocationName = '';
        final locationParts = <String>[];

        // Add house number and street (exact address)
        if (placemark.subThoroughfare != null &&
            placemark.subThoroughfare!.isNotEmpty) {
          if (placemark.thoroughfare != null &&
              placemark.thoroughfare!.isNotEmpty) {
            // Both house number and street name available
            locationParts.add(
              '${placemark.subThoroughfare}, ${placemark.thoroughfare}',
            );
          } else {
            // Only house number available
            locationParts.add(placemark.subThoroughfare!);
          }
        } else if (placemark.thoroughfare != null &&
            placemark.thoroughfare!.isNotEmpty) {
          // Only street name available
          locationParts.add(placemark.thoroughfare!);
        } else if (placemark.name != null && placemark.name!.isNotEmpty) {
          // Fallback to place name
          locationParts.add(placemark.name!);
        }

        // Add neighborhood if available and different from city
        if (placemark.subLocality != null &&
            placemark.subLocality!.isNotEmpty &&
            placemark.subLocality != placemark.locality) {
          locationParts.add(placemark.subLocality!);
        }

        // Add locality (city/town)
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          locationParts.add(placemark.locality!);
        }

        // Add administrative area (state/province)
        if (placemark.administrativeArea != null &&
            placemark.administrativeArea!.isNotEmpty) {
          locationParts.add(placemark.administrativeArea!);
        }

        // Add country
        if (placemark.country != null && placemark.country!.isNotEmpty) {
          locationParts.add(placemark.country!);
        }

        // Create the exact location string
        exactLocationName = locationParts.isNotEmpty
            ? locationParts.join(', ')
            : 'Unknown Location';

        setState(() {
          _location = exactLocationName;
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationPrivacyLevel =
              LocationPrivacyLevel.exact; // Default to exact location
          _isLocationLoading = false;
        });
      } else {
        setState(() {
          _location = 'Location Found';
          _latitude = position.latitude;
          _longitude = position.longitude;
          _isLocationLoading = false;
        });
      }
    } catch (e) {
      // Handle specific error types
      String errorMessage = 'Could not get your location';
      if (e.toString().contains('timeout') ||
          e.toString().contains('TimeLimit')) {
        errorMessage =
            'Location request timed out. Your post will not include location information.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.orange),
        );
      }

      setState(() {
        _location = null;
        _latitude = null;
        _longitude = null;
        _isLocationLoading = false;
      });
    }
  }

  /// Get location automatically when image is selected
  Future<void> _extractLocationFromImage(String imagePath) async {
    // Always use current device location instead of EXIF data
    await _getCurrentLocation();
  }

  /// Handle location privacy selection
  Future<void> _showLocationPrivacyDialog() async {
    if (_placemark == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => LocationPrivacyDialog(
        placemark: _placemark,
        currentLevel: _locationPrivacyLevel,
        currentLocationText: _location,
      ),
    );

    if (result != null) {
      setState(() {
        _locationPrivacyLevel = result['level'] as LocationPrivacyLevel;
        _location = result['locationText'] as String?;
      });
    }
  }

  /// Get appropriate icon based on location privacy level
  IconData _getLocationIcon() {
    switch (_locationPrivacyLevel) {
      case LocationPrivacyLevel.none:
        return Icons.location_off;
      case LocationPrivacyLevel.country:
        return Icons.public;
      case LocationPrivacyLevel.state:
        return Icons.map;
      case LocationPrivacyLevel.city:
        return Icons.location_city;
      case LocationPrivacyLevel.neighborhood:
        return Icons.home_work;
      case LocationPrivacyLevel.street:
        return Icons.route;
      case LocationPrivacyLevel.exact:
        return Icons.my_location;
    }
  }

  Future<void> _openCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = photo;
        });
        // Extract location from image
        await _extractLocationFromImage(photo.path);
      } else {
        // User cancelled camera
        if (widget.isOnboarding && mounted) {
          // Go back to previous screen if in onboarding
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to open camera: $e')));
      }
    }
  }

  Future<void> _submitPost() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(postRepositoryProvider);

      // Determine content type from file extension
      final filePath = _selectedImage!.path;
      final extension = filePath.split('.').last.toLowerCase();
      String contentType = 'image/jpeg';
      if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        contentType = 'image/jpeg';
      }

      final postResponse = await repository.createPost(
        imagePath: filePath,
        contentType: contentType,
        caption: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
        privacy: _privacy,
        location: _locationPrivacyLevel == LocationPrivacyLevel.none
            ? null
            : _location,
        latitude: _locationPrivacyLevel == LocationPrivacyLevel.none
            ? null
            : _latitude,
        longitude: _locationPrivacyLevel == LocationPrivacyLevel.none
            ? null
            : _longitude,
      );

      if (!mounted) return;

      // If this is onboarding, store the post data for the share screen
      if (widget.isOnboarding) {
        final mediaUrl = postResponse.data.media.isNotEmpty
            ? postResponse.data.media.first.mediaUrl
            : null;

        // Format the time - convert from UTC to local timezone
        String? formattedTime;
        try {
          // Parse the UTC time from server
          final createdAtUtc = DateTime.parse(postResponse.data.createdAt);
          // Convert to local timezone
          final createdAtLocal = createdAtUtc.toLocal();
          // Format to "3:45 PM" format
          formattedTime = DateFormat('h:mm a').format(createdAtLocal);
        } catch (e) {
          // If time parsing fails, don't show time
          formattedTime = null;
        }

        ref
            .read(onboardingViewModelProvider.notifier)
            .updateFirstPostData(
              mediaUrl: mediaUrl,
              location: _location,
              time: formattedTime,
            );
      }

      setState(() {
        _isLoading = false;
      });

      // Show success message only if not onboarding
      // During onboarding, the "You posted your first moment!" popup will be shown instead
      if (!widget.isOnboarding) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Complete the flow
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        // Return true to indicate success
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: _selectedImage == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Header
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.black87,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              const Spacer(),
                              const Text(
                                'New moment',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(
                                width: 48,
                              ), // Balance the back button
                            ],
                          ),
                        ),
                      ),

                      // Image - Natural aspect ratio container
                      Container(
                        width: double.infinity,
                        child: Stack(
                          children: [
                            Image.file(
                              File(_selectedImage!.path),
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                            ),
                            // Location overlay on image (centered at bottom) - Auto-detected location
                            if ((_location != null &&
                                    _locationPrivacyLevel !=
                                        LocationPrivacyLevel.none) ||
                                _isLocationLoading)
                              Positioned(
                                bottom: 16,
                                left: 16,
                                right: 16,
                                child: Center(
                                  child: GestureDetector(
                                    onTap: _isLocationLoading
                                        ? null
                                        : _showLocationPrivacyDialog,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.9,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.7,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_isLocationLoading)
                                            const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          else
                                            Icon(
                                              _getLocationIcon(),
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              _isLocationLoading
                                                  ? 'Getting location...'
                                                  : _location!,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                height: 1.2,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          if (!_isLocationLoading)
                                            const SizedBox(width: 4),
                                          if (!_isLocationLoading)
                                            const Icon(
                                              Icons.edit,
                                              color: Colors.white70,
                                              size: 12,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Add location button when no location is shared
                            if (_placemark != null &&
                                _locationPrivacyLevel ==
                                    LocationPrivacyLevel.none &&
                                !_isLocationLoading)
                              Positioned(
                                bottom: 16,
                                right: 16,
                                child: GestureDetector(
                                  onTap: _showLocationPrivacyDialog,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.7,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add_location_alt,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Add location',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Caption - Flexible height
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Caption input
                            TextField(
                              controller: _captionController,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                hintText: 'Add a caption...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              maxLines: null,
                              minLines: 1,
                              maxLength: 500,
                            ),
                          ],
                        ),
                      ),

                      // Privacy selector - Fixed above button
                      Container(
                        color: Colors.white,
                        child: PrivacySelector(
                          currentPrivacy: _privacy,
                          onPrivacyChanged: (privacy) {
                            setState(() {
                              _privacy = privacy;
                            });
                          },
                        ),
                      ),

                      // Share button at the bottom
                      Container(
                        color: Colors.white,
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 8,
                          bottom: MediaQuery.of(context).padding.bottom + 16,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitPost,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3620B3),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Share this moment',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
