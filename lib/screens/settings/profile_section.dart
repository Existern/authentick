import 'package:flutter/material.dart';

class ProfileSection extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController usernameController;
  final bool isEditable;
  final VoidCallback onSave;

  const ProfileSection({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.usernameController,
    required this.isEditable,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            label: 'First Name',
            controller: firstNameController,
            enabled: isEditable,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Last Name',
            controller: lastNameController,
            enabled: isEditable,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Username',
            controller: usernameController,
            enabled: isEditable,
            prefix: '@',
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    String? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black, fontSize: 16)),
        const SizedBox(height: 5),
        SizedBox(
          height: 40,
          width: double.infinity,
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              prefixText: prefix,
              prefixStyle: TextStyle(
                fontSize: 16,
                color: enabled ? Colors.black : Colors.black54,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              filled: !enabled,
              fillColor: !enabled ? Colors.grey.shade100 : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Color(0xFF3620B3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
