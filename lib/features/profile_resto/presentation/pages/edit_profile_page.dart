import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:carimakan/core/services/cloudinary_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _waController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _imageFile;
  String? _currentPhotoUrl;
  String? _currentPhotoBase64;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        _namaController.text = data['nama'] ?? '';
        _emailController.text = data['email'] ?? '';
        _waController.text = data['phone'] ?? '';
        _currentPhotoUrl = data['photoUrl'] as String?;
        _currentPhotoBase64 = data['photoBase64'] as String?;
      }
    } catch (e) {
      // Ignore
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e')),
      );
    }
  }

  Future<void> _saveUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama lengkap tidak boleh kosong!')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 1. Update password if filled
      if (_passwordController.text.trim().isNotEmpty) {
        await user.updatePassword(_passwordController.text.trim());
      }

      // 2. Upload image to Cloudinary if picked
      String? cloudinaryUrl;
      if (_imageFile != null) {
        cloudinaryUrl = await CloudinaryService.uploadImage(_imageFile!);
        if (cloudinaryUrl == null) {
          throw Exception('Gagal mengunggah foto profil ke Cloudinary');
        }
      }

      if (!mounted) return;

      // 3. Update Firestore 'users' collection
      final Map<String, dynamic> updateData = {
        'nama': _namaController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _waController.text.trim(),
      };

      if (cloudinaryUrl != null) {
        updateData['photoUrl'] = cloudinaryUrl;
        updateData['photoBase64'] = FieldValue.delete(); // Bersihkan base64 lama
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        updateData,
        SetOptions(merge: true),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil berhasil disimpan! 🎉', style: GoogleFonts.outfit()),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan profil: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _waController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1C1C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profil',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C1C1C),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD33400)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Foto Profil Upload
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFD33400), width: 2),
                        image: DecorationImage(
                          image: _imageFile != null 
                              ? FileImage(_imageFile!) as ImageProvider
                              : (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty
                                  ? NetworkImage(_currentPhotoUrl!) as ImageProvider
                                  : (_currentPhotoBase64 != null && _currentPhotoBase64!.isNotEmpty
                                      ? MemoryImage(base64Decode(_currentPhotoBase64!)) as ImageProvider
                                      : const AssetImage('assets/images/Icon/icon_carimakan.png'))),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD33400),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Form Fields
            _buildTextField(
              label: 'Nama Lengkap',
              controller: _namaController,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Email',
              controller: _emailController,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Password Baru',
              controller: _passwordController,
              icon: Icons.lock_outline,
              isPassword: true,
              hintText: 'Biarkan kosong jika tidak ingin mengubah',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'No WhatsApp Pribadi',
              controller: _waController,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            
            const SizedBox(height: 40),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD33400),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Simpan Perubahan',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          keyboardType: keyboardType,
          style: GoogleFonts.outfit(fontSize: 16),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF)),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF9CA3AF),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFF3F4F6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFD33400)),
            ),
          ),
        ),
      ],
    );
  }
}
