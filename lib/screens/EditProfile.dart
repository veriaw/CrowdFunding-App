import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_tpm/models/user.dart';
import 'package:project_tpm/screens/MainMenu.dart';
import 'package:project_tpm/services/user_service.dart';
import 'package:project_tpm/shared/color_palette.dart';
import 'package:project_tpm/utils/handle_image_profile.dart'; // Ganti dengan path sesuai proyekmu

class EditProfilePage extends StatefulWidget {
  final User user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  File? _profileImage;
  final _usernameController = TextEditingController();
  String _gender = 'Laki-laki';
  DateTime? _birthDate;
  final userService = UserService();

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.user.username;
    _gender = widget.user.gender ?? 'Laki-laki';
    _birthDate = widget.user.dateOfBirth;
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final image = await ProfileImageHelper.loadProfileImage(widget.user.id!);
    setState(() => _profileImage = image);
  }

  Future<void> _pickImageFromCamera() async {
    final image = await ProfileImageHelper.pickAndSaveProfileImageFromCamera(
        widget.user.id!);
    if (image != null) {
      setState(() => _profileImage = image);
    }
  }

  Future<void> _pickBirthDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selected != null) {
      setState(() => _birthDate = selected);
    }
  }

  void _submitProfile() async {
    final username = _usernameController.text;
    if (username.isEmpty || _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lengkapi semua data terlebih dahulu.")),
      );
      return;
    }

    userService.updateUser(
        widget.user.id!,
        User(
            id: widget.user.id,
            username: username,
            password: widget.user.password,
            gender: _gender,
            dateOfBirth: _birthDate,
            publicKey: widget.user.publicKey));

    final userUpdated = await userService.getUserById(widget.user.id!);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainMenu(
          user: userUpdated!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Profil"), backgroundColor: Colors.teal),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImageFromCamera,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : AssetImage('assets/placeholder.png') as ImageProvider,
                child: _profileImage == null
                    ? Icon(Icons.camera_alt, size: 30, color: Colors.white)
                    : null,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Username"),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _gender,
              items: ['Male', 'Female']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (val) => setState(() => _gender = val!),
              decoration: InputDecoration(labelText: "Gender"),
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text(
                _birthDate == null
                    ? "Birth Date"
                    : DateFormat('dd MMMM yyyy').format(_birthDate!),
              ),
              trailing: Icon(Icons.calendar_today),
              onTap: _pickBirthDate,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitProfile,
              child: Text("Simpan"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            )
          ],
        ),
      ),
    );
  }
}
