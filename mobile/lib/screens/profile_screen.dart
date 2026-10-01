import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/user_avatar.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _statusCtrl;
  File? _selectedImage;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user!;
    _nameCtrl = TextEditingController(text: user.name);
    _bioCtrl = TextEditingController(text: user.bio);
    _statusCtrl = TextEditingController(text: user.status);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _statusCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (xfile != null) setState(() => _selectedImage = File(xfile.path));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    await auth.updateProfile(
      name: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      status: _statusCtrl.text.trim(),
      profilePicFile: _selectedImage,
    );
    if (mounted) {
      setState(() {
        _saving = false;
        _editing = false;
        _selectedImage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F23),
        title: const Text('Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_editing)
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF7C3AED)))
                  : const Text('Save',
                      style: TextStyle(
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.bold)),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white70),
              onPressed: () => setState(() => _editing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            GestureDetector(
              onTap: _editing ? _pickImage : null,
              child: Stack(
                children: [
                  _selectedImage != null
                      ? CircleAvatar(
                          radius: 56,
                          backgroundImage: FileImage(_selectedImage!),
                        )
                      : UserAvatar(
                          url: user.profilePic,
                          name: user.name,
                          radius: 56,
                        ),
                  if (_editing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF7C3AED),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 16),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (!_editing) ...[
              Text(
                user.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(user.email,
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(user.status,
                    style: const TextStyle(
                        color: Color(0xFF7C3AED), fontSize: 12)),
              ),
              const SizedBox(height: 12),
              Text(
                user.bio,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ] else ...[
              const SizedBox(height: 20),
              _editField('Name', _nameCtrl),
              const SizedBox(height: 12),
              _editField('Status', _statusCtrl),
              const SizedBox(height: 12),
              _editField('Bio', _bioCtrl, maxLines: 3),
            ],
            const SizedBox(height: 40),
            const Divider(color: Colors.white12),
            const SizedBox(height: 16),

            // Info cards
            _infoCard(Icons.email_outlined, 'Email', user.email),
            _infoCard(Icons.access_time, 'Last Seen',
                user.lastSeen?.toLocal().toString() ?? '—'),

            const SizedBox(height: 32),

            // Logout button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  auth.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text('Sign Out',
                    style: TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editField(String label, TextEditingController ctrl,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF1A1A2E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111124),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7C3AED), size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 11)),
              Text(value,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
