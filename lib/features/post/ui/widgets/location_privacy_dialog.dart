import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

enum LocationPrivacyLevel {
  none,
  country,
  state,
  city,
  neighborhood,
  street,
  exact,
}

class LocationPrivacyOption {
  final LocationPrivacyLevel level;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? locationText;

  LocationPrivacyOption({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.locationText,
  });
}

class LocationPrivacyDialog extends StatefulWidget {
  final Placemark? placemark;
  final LocationPrivacyLevel currentLevel;
  final String? currentLocationText;

  const LocationPrivacyDialog({
    super.key,
    required this.placemark,
    required this.currentLevel,
    this.currentLocationText,
  });

  @override
  State<LocationPrivacyDialog> createState() => _LocationPrivacyDialogState();
}

class _LocationPrivacyDialogState extends State<LocationPrivacyDialog> {
  late LocationPrivacyLevel _selectedLevel;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.currentLevel;
  }

  List<LocationPrivacyOption> _buildLocationOptions() {
    final options = <LocationPrivacyOption>[];

    // No location
    options.add(
      LocationPrivacyOption(
        level: LocationPrivacyLevel.none,
        title: 'Don\'t share location',
        subtitle: 'Your post won\'t include any location',
        icon: Icons.location_off,
        locationText: null,
      ),
    );

    if (widget.placemark == null) return options;

    final placemark = widget.placemark!;

    // Helper function to build hierarchical location text
    String buildLocationText({
      String? houseNumber,
      String? street,
      String? neighborhood,
      String? city,
      String? state,
      String? country,
    }) {
      final parts = <String>[];

      if (houseNumber != null && houseNumber.isNotEmpty) {
        if (street != null && street.isNotEmpty) {
          parts.add('$houseNumber, $street');
        } else {
          parts.add(houseNumber);
        }
      } else if (street != null && street.isNotEmpty) {
        parts.add(street);
      }

      if (neighborhood != null &&
          neighborhood.isNotEmpty &&
          neighborhood != city) {
        parts.add(neighborhood);
      }

      if (city != null && city.isNotEmpty) {
        parts.add(city);
      }

      if (state != null && state.isNotEmpty) {
        parts.add(state);
      }

      if (country != null && country.isNotEmpty) {
        parts.add(country);
      }

      return parts.join(', ');
    }

    // Country level
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      options.add(
        LocationPrivacyOption(
          level: LocationPrivacyLevel.country,
          title: 'Country only',
          subtitle: 'Share only your country',
          icon: Icons.public,
          locationText: placemark.country!,
        ),
      );
    }

    // State level
    if (placemark.administrativeArea != null &&
        placemark.administrativeArea!.isNotEmpty) {
      options.add(
        LocationPrivacyOption(
          level: LocationPrivacyLevel.state,
          title: 'State/Province',
          subtitle: 'Share your state or province',
          icon: Icons.map,
          locationText: buildLocationText(
            state: placemark.administrativeArea,
            country: placemark.country,
          ),
        ),
      );
    }

    // City level
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      options.add(
        LocationPrivacyOption(
          level: LocationPrivacyLevel.city,
          title: 'City',
          subtitle: 'Share your city',
          icon: Icons.location_city,
          locationText: buildLocationText(
            city: placemark.locality,
            state: placemark.administrativeArea,
            country: placemark.country,
          ),
        ),
      );
    }

    // Neighborhood level
    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      options.add(
        LocationPrivacyOption(
          level: LocationPrivacyLevel.neighborhood,
          title: 'Neighborhood',
          subtitle: 'Share your neighborhood',
          icon: Icons.home_work,
          locationText: buildLocationText(
            neighborhood: placemark.subLocality,
            city: placemark.locality,
            state: placemark.administrativeArea,
            country: placemark.country,
          ),
        ),
      );
    }

    // Street level
    if (placemark.thoroughfare != null && placemark.thoroughfare!.isNotEmpty) {
      options.add(
        LocationPrivacyOption(
          level: LocationPrivacyLevel.street,
          title: 'Street',
          subtitle: 'Share your street (no house number)',
          icon: Icons.route,
          locationText: buildLocationText(
            street: placemark.thoroughfare,
            neighborhood: placemark.subLocality,
            city: placemark.locality,
            state: placemark.administrativeArea,
            country: placemark.country,
          ),
        ),
      );
    }

    // Exact location (full address including house number)
    final hasStreetInfo =
        (placemark.thoroughfare != null &&
            placemark.thoroughfare!.isNotEmpty) ||
        (placemark.subThoroughfare != null &&
            placemark.subThoroughfare!.isNotEmpty);

    if (hasStreetInfo ||
        (placemark.locality != null && placemark.locality!.isNotEmpty)) {
      // Use the original location text if available, otherwise build from placemark
      final exactLocationText = widget.currentLocationText?.isNotEmpty == true
          ? widget.currentLocationText!
          : buildLocationText(
              houseNumber: placemark.subThoroughfare,
              street: placemark.thoroughfare,
              neighborhood: placemark.subLocality,
              city: placemark.locality,
              state: placemark.administrativeArea,
              country: placemark.country,
            );

      options.add(
        LocationPrivacyOption(
          level: LocationPrivacyLevel.exact,
          title: 'Exact location',
          subtitle: 'Share your complete address',
          icon: Icons.my_location,
          locationText: exactLocationText,
        ),
      );
    }

    return options;
  }

  @override
  Widget build(BuildContext context) {
    final options = _buildLocationOptions();
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDialogHeight = screenHeight * 0.8; // 80% of screen height

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxDialogHeight, maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Choose location privacy',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select how much of your location you want to share',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),

              // Scrollable Options
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: options
                        .map((option) => _buildOptionTile(option))
                        .toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final selectedOption = options.firstWhere(
                        (option) => option.level == _selectedLevel,
                      );
                      Navigator.of(context).pop({
                        'level': _selectedLevel,
                        'locationText': selectedOption.locationText,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3620B3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(LocationPrivacyOption option) {
    final isSelected = _selectedLevel == option.level;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLevel = option.level;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF3620B3) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? const Color(0xFF3620B3).withValues(alpha: 0.05)
              : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              option.icon,
              color: isSelected ? const Color(0xFF3620B3) : Colors.grey[600],
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF3620B3)
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    option.subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  if (option.locationText != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      option.locationText!,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? const Color(0xFF3620B3)
                            : Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF3620B3),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
