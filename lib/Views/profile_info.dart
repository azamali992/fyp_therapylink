// profile_info_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:therapylink/utils/colors.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';

class ProfileInfoPage extends StatefulWidget {
  const ProfileInfoPage({super.key});

  @override
  State<ProfileInfoPage> createState() => _ProfileInfoPageState();
}

class _ProfileInfoPageState extends State<ProfileInfoPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String _gender = 'Male';
  String _selectedCountryCode = '+92';
  String _countryName = 'Pakistan';
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['fullName'] ?? '';
          _emailController.text = user.email ?? '';
          _dobController.text = data['dob'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _gender = data['gender'] ?? 'Male';
          _userRole = data['role'] ?? '';
          _countryName = data['country'] ?? 'Pakistan';
          if (_dobController.text.isNotEmpty) {
            DateTime dob = DateTime.parse(_dobController.text);
            _ageController.text = (DateTime.now().year - dob.year).toString();
          }
        });
      }
    }
  }

  Future<void> _pickDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dobController.text) ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.bgpurple),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = picked.toIso8601String().split('T').first;
        _ageController.text = (DateTime.now().year - picked.year).toString();
      });
    }
  }

  void _pickCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        setState(() => _countryName = country.name);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgpurple,
      appBar: AppBar(
        backgroundColor: AppColors.bgpurple,
        title: const Text("Profile Info",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit,
                color: Colors.white),
            onPressed: () async {
              if (_isEditing && _formKey.currentState!.validate()) {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({
                    'fullName': _nameController.text.trim(),
                    'dob': _dobController.text.trim(),
                    'gender': _gender,
                    'phone': _phoneController.text.trim(),
                    'country': _countryName,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Profile updated!")));
                }
              }
              setState(() => _isEditing = !_isEditing);
            },
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionHeader("Personal Details"),
            _buildTextField('Full Name', _nameController,
                validator: (value) => value!.isEmpty ? 'Required' : null),
            const SizedBox(height: 16),
            _buildTextField('Email', _emailController,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _isEditing ? _pickDOB : null,
                    child: AbsorbPointer(
                      child: _buildTextField('Date of Birth', _dobController),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child:
                        _buildTextField('Age', _ageController, readOnly: true)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: _inputDecoration('Gender'),
                    items: ['Male', 'Female', 'Other']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: _isEditing
                        ? (val) => setState(() => _gender = val!)
                        : null,
                    dropdownColor: AppColors.bgpurple,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _isEditing ? _pickCountry : null,
                    child: AbsorbPointer(
                      child: _buildTextField(
                          'Country', TextEditingController(text: _countryName),
                          readOnly: true),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            IntlPhoneField(
              controller: _phoneController,
              initialCountryCode: 'PK',
              style: const TextStyle(color: Colors.white),
              dropdownTextStyle: const TextStyle(color: Colors.black),
              cursorColor: Colors.white,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _inputDecoration('Phone Number').copyWith(
                hintText: '3001234567',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
              onChanged: (phone) => _selectedCountryCode = phone.countryCode,
            ),
            const SizedBox(height: 16),
            if (_userRole.isNotEmpty)
              Text("Role: $_userRole",
                  style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.white),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
      bool readOnly = false,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      readOnly: !_isEditing || readOnly,
      validator: validator,
      decoration: _inputDecoration(label),
    );
  }
}
