import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/user_avatar.dart';
import '../widgets/password_prompt_dialog.dart';
import '../widgets/animated_page_route.dart';
import '../widgets/password_change_dialog.dart';
import 'admin_dashboard_screen.dart';

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
  bool _chatPasswordEnabled = false;
  List<UserModel> _chatAccessUsers = [];
  bool _loadingChatAccess = true;
  bool _notificationsEnabled = true;
  bool _updatingNotifications = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user!;
    _nameCtrl = TextEditingController(text: user.name);
    _bioCtrl = TextEditingController(text: user.bio);
    _statusCtrl = TextEditingController(text: user.status);
    _loadChatPrivacyStatus();
    _loadNotificationPreference();
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
    final success = await auth.updateProfile(
      name: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      status: _statusCtrl.text.trim(),
      profilePicFile: _selectedImage,
    );
    if (mounted && success) {
      setState(() {
        _saving = false;
        _editing = false;
        _selectedImage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated!'),
          backgroundColor: Color(0xFF237A45),
          duration: Duration(seconds: 3),
        ),
      );
    } else if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Profile update failed. Check your connection and try again.'),
            backgroundColor: Color(0xFF9B2525)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2C2C2C)),
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
                        strokeWidth: 2,
                        color: Color(0xFFFF7A00),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Color(0xFFFF7A00),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF2C2C2C)),
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
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF7A00),
                        width: 4,
                      ),
                    ),
                    child: _selectedImage != null
                        ? CircleAvatar(
                            radius: 56, // 112 diameter + 4 border * 2 = 120
                            backgroundImage: FileImage(_selectedImage!),
                          )
                        : UserAvatar(
                            url: user.profilePic,
                            name: user.name,
                            radius: 56,
                          ),
                  ),
                  if (_editing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7A00),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 18),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!_editing) ...[
              Text(
                user.name,
                style: const TextStyle(
                  color: Color(0xFF2C2C2C),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x1AFF7A00),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.status,
                  style: const TextStyle(
                    color: Color(0xFFFF7A00),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.bio,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF2C2C2C), fontSize: 14),
              ),
            ] else ...[
              const SizedBox(height: 20),
              _editField('Name', _nameCtrl),
              const SizedBox(height: 16),
              _editField('Status', _statusCtrl),
              const SizedBox(height: 16),
              _editField('Bio', _bioCtrl, maxLines: 3),
            ],
            const SizedBox(height: 40),

            if (user.email.trim().toLowerCase() ==
                'alexmareyamrenny@gmail.com') ...[
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined,
                      color: Color(0xFFFF7A00)),
                  title: const Text('Admin dashboard'),
                  subtitle: const Text('Storage usage and app accounts'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    animatedPageRoute(const AdminDashboardScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Card(
              color: Colors.white,
              child: ListTile(
                leading: const Icon(Icons.key_outlined, color: Color(0xFFFF7A00)),
                title: const Text('Change account password'),
                subtitle: const Text('Password changes may require admin approval'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _changeOwnPassword,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              color: Colors.white,
              child: SwitchListTile(
                secondary: const Icon(Icons.notifications_active_outlined,
                    color: Color(0xFFFF7A00)),
                title: const Text('Message notifications'),
                subtitle: Text(_notificationsEnabled
                    ? 'Show notifications when new messages arrive'
                    : 'Notifications are turned off on this device'),
                value: _notificationsEnabled,
                activeThumbColor: const Color(0xFFFF7A00),
                onChanged: _updatingNotifications ? null : _changeNotifications,
              ),
            ),
            const SizedBox(height: 16),

            // The web app's chat password protects the owner's incoming chats.
            Card(
              color: Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_outline,
                        color: Color(0xFFFF7A00)),
                    title: const Text('Chat privacy password'),
                    subtitle: Text(_chatPasswordEnabled
                        ? 'Other accounts need this password to open your chats'
                        : 'Require a password before others can open your chats'),
                    trailing: Switch(
                      value: _chatPasswordEnabled,
                      activeThumbColor: const Color(0xFFFF7A00),
                      onChanged: (_) => _changeChatPassword(),
                    ),
                    onTap: _changeChatPassword,
                  ),
                  if (_chatPasswordEnabled) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(children: [
                        const Expanded(
                            child: Text('Accounts allowed to open your chats',
                                style: TextStyle(fontWeight: FontWeight.w600))),
                        if (!_loadingChatAccess)
                          Text('${_chatAccessUsers.length}'),
                      ]),
                    ),
                    if (_loadingChatAccess)
                      const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator())
                    else if (_chatAccessUsers.isEmpty)
                      const Padding(
                          padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                  'No other accounts have unlocked your chats yet.',
                                  style: TextStyle(color: Colors.grey))))
                    else
                      ..._chatAccessUsers.map((allowedUser) => ListTile(
                            leading: UserAvatar(
                                url: allowedUser.profilePic,
                                name: allowedUser.name,
                                radius: 18),
                            title: Text(allowedUser.name),
                            subtitle: Text(allowedUser.email),
                            trailing: IconButton(
                              tooltip: 'Remove access',
                              icon: const Icon(Icons.person_remove_outlined,
                                  color: Colors.red),
                              onPressed: () => _revokeChatAccess(allowedUser),
                            ),
                          )),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.black12),
            const SizedBox(height: 24),

            // Info cards
            _infoCard(Icons.email_outlined, 'Email', user.email),
            _infoCard(Icons.access_time, 'Last Seen',
                user.lastSeen?.toLocal().toString() ?? '—'),

            const SizedBox(height: 40),

            // Save button when editing (optional bottom button as well)
            if (_editing) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'SAVE CHANGES',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Logout button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await auth.logout();
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'SIGN OUT',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // rounded-xl
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeChatPassword() async {
    if (_chatPasswordEnabled) {
      final remove = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove chat password?'),
          content: const Text(
              'Anyone with access to your account can open your chats.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remove')),
          ],
        ),
      );
      if (remove == true) {
        final removed = await ApiService.removeChatPassword();
        if (!mounted) return;
        if (removed) {
          setState(() {
            _chatPasswordEnabled = false;
            _chatAccessUsers = [];
          });
          _showProfileMessage('Chat password removed.');
        } else {
          _showProfileMessage('Could not remove the chat password.',
              error: true);
        }
      }
      return;
    }
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const PasswordPromptDialog(
        title: 'Set chat password',
        hint: 'At least 4 characters',
        confirmLabel: 'Save',
      ),
    );
    if (password == null) return;
    final saved = await ApiService.setChatPassword(password);
    if (saved && mounted) {
      await _loadChatPrivacyStatus();
      if (mounted) _showProfileMessage('Chat password enabled.');
    } else if (mounted) {
      _showProfileMessage('Password must be at least 4 characters.',
          error: true);
    }
  }

  Future<void> _changeOwnPassword() async {
    final values = await showPasswordChangeDialog(
      context,
      title: 'Change account password',
    );
    if (values == null || !mounted) return;
    try {
      final result = await ApiService.changeOwnPassword(
        currentPassword: values.currentPassword,
        newPassword: values.newPassword,
      );
      if (!mounted) return;
      final approvalRequired = result['approvalRequired'] == true;
      _showProfileMessage(
        approvalRequired
            ? 'Request sent. Your admin must approve this password change.'
            : 'Your password has been changed.',
      );
    } catch (error) {
      if (mounted) {
        _showProfileMessage(
          error.toString().replaceFirst('Exception: ', ''),
          error: true,
        );
      }
    }
  }

  Future<void> _loadChatPrivacyStatus() async {
    try {
      final status = await ApiService.getChatPasswordStatus();
      if (!mounted) return;
      setState(() {
        _chatPasswordEnabled = status['enabled'] as bool;
        _chatAccessUsers = status['users'] as List<UserModel>;
        _loadingChatAccess = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingChatAccess = false);
    }
  }

  Future<void> _revokeChatAccess(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove chat access?'),
        content: Text(
            '${user.name} will need the password again to open your chats.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final removed = await ApiService.removeChatAccess(user.id);
    if (!mounted) return;
    if (removed) {
      setState(
          () => _chatAccessUsers.removeWhere((item) => item.id == user.id));
      _showProfileMessage('Access removed for ${user.name}.');
    } else {
      _showProfileMessage('Could not remove access. Try again.', error: true);
    }
  }

  void _showProfileMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor:
            error ? const Color(0xFF9B2525) : const Color(0xFF237A45),
        duration: const Duration(seconds: 3),
      ));
  }

  Future<void> _loadNotificationPreference() async {
    final enabled = await NotificationService.isEnabled();
    if (mounted) setState(() => _notificationsEnabled = enabled);
  }

  Future<void> _changeNotifications(bool enabled) async {
    setState(() => _updatingNotifications = true);
    final permissionGranted = await NotificationService.setEnabled(enabled);
    if (!mounted) return;

    if (enabled && !permissionGranted) {
      await NotificationService.setEnabled(false);
      if (!mounted) return;
      setState(() {
        _notificationsEnabled = false;
        _updatingNotifications = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: const Text('Allow notifications for ReSender in Android settings to turn them on.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: NotificationService.openSystemSettings,
          ),
          duration: const Duration(seconds: 6),
        ));
      return;
    }

    setState(() {
      _notificationsEnabled = enabled;
      _updatingNotifications = false;
    });
    _showProfileMessage(enabled
        ? 'Message notifications are on.'
        : 'Message notifications are off.');
  }

  Widget _editField(String label, TextEditingController ctrl,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.grey, // gray-400
            fontSize: 12, // xs
            fontWeight: FontWeight.w600, // semibold
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(color: Color(0xFF2C2C2C)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8F9FA), // bg #F8F9FA
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Colors.grey.shade200, width: 1), // border gray-200
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFFFF7A00), width: 1.5), // focus border #FF7A00
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFFF7A00), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF2C2C2C),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
