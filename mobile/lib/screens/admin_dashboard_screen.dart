import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/password_prompt_dialog.dart';
import '../widgets/password_change_dialog.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _overview;
  bool _loading = false;
  String? _error;
  String? _adminPassword;

  @override
  void dispose() {
    _adminPassword = null;
    super.dispose();
  }

  Future<void> _unlock() async {
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PasswordPromptDialog(
        title: 'Admin verification',
        hint: 'Enter your ReSender password',
        confirmLabel: 'View dashboard',
      ),
    );
    if (password == null || password.isEmpty || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ApiService.getAdminOverview(password);
      if (mounted) {
        setState(() {
          _overview = result;
          _adminPassword = password;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _overview;
    final users = data?['users'] as Map<String, dynamic>?;
    final cloudinary = data?['cloudinary'] as Map<String, dynamic>?;
    final atlas = data?['atlas'] as Map<String, dynamic>?;
    final policy = data?['passwordPolicy'] as Map<String, dynamic>? ?? {};
    final pending = policy['pendingRequests'] as List<dynamic>? ?? const [];
    final accounts = users?['accounts'] as List<dynamic>? ?? const [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Admin dashboard'),
        actions: [
          if (data != null)
            IconButton(
              tooltip: 'Refresh dashboard',
              onPressed: _loading ? null : _refreshOverview,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: data == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined,
                        size: 56, color: Color(0xFFFF7A00)),
                    const SizedBox(height: 12),
                    const Text('Sensitive project information',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text(
                      'Confirm your account password to view storage usage and account details.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _loading ? null : _unlock,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.lock_open),
                      label: Text(_loading ? 'Checking…' : 'Verify password'),
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A00)),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshOverview,
              color: const Color(0xFFFF7A00),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: Colors.white,
                    child: Column(children: [
                      SwitchListTile.adaptive(
                        value: policy['allowUserPasswordChange'] == true,
                        activeColor: const Color(0xFFFF7A00),
                        title: const Text('Allow users to change passwords'),
                        subtitle: const Text('The first change is immediate; later changes need your approval.'),
                        onChanged: _loading ? null : _setPasswordPolicy,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.password, color: Color(0xFFFF7A00)),
                        title: const Text('Change admin password'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _changeAdminPassword,
                      ),
                    ]),
                  ),
                  if (pending.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Password change requests (${pending.length})', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          for (final item in pending.whereType<Map>())
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item['name']?.toString() ?? 'User'),
                              subtitle: Text(item['email']?.toString() ?? ''),
                              trailing: Wrap(spacing: 2, children: [
                                IconButton(tooltip: 'Approve', icon: const Icon(Icons.check_circle_outline, color: Colors.green), onPressed: () => _reviewRequest(item, true)),
                                IconButton(tooltip: 'Deny', icon: const Icon(Icons.cancel_outlined, color: Colors.red), onPressed: () => _reviewRequest(item, false)),
                              ]),
                            ),
                        ]),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _metricCard(
                    icon: Icons.cloud_outlined,
                    title: 'Cloudinary storage',
                    used: cloudinary?['storageUsedBytes'],
                    limit: cloudinary?['storageLimitBytes'],
                    remaining: cloudinary?['storageRemainingBytes'],
                    unavailable: cloudinary?['available'] != true,
                    detail: cloudinary?['resources'] == null
                        ? null
                        : '${cloudinary!['resources']} media resources',
                  ),
                  const SizedBox(height: 12),
                  _metricCard(
                    icon: Icons.storage_outlined,
                    title: 'MongoDB Atlas · ${atlas?['databaseName'] ?? 'database'}',
                    used: atlas?['storageUsedBytes'],
                    limit: atlas?['storageLimitBytes'],
                    remaining: atlas?['storageRemainingBytes'],
                    detail:
                        '${_formatBytes(_asInt(atlas?['dataBytes']))} data · ${_formatBytes(_asInt(atlas?['indexBytes']))} indexes · ${atlas?['collections'] ?? '—'} collections · ${atlas?['documents'] ?? '—'} documents',
                    setupHint: atlas?['storageLimitBytes'] == null
                        ? 'Add ATLAS_STORAGE_LIMIT_GB to the server environment to show remaining storage.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.people_outline,
                                color: Color(0xFFFF7A00)),
                            const SizedBox(width: 8),
                            const Expanded(
                                child: Text('App accounts',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700))),
                            Text('${users?['count'] ?? 0}',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF7A00))),
                          ]),
                          const Divider(height: 24),
                          const Text('All app accounts',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54)),
                          const SizedBox(height: 8),
                          for (final entry in accounts)
                            if (entry is Map) _accountTile(entry),
                          const SizedBox(height: 8),
                          const Text(
                            'Passwords are never shown. ReSender stores password hashes, which cannot be used to recover the original passwords.',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Updated ${data['generatedAt'] ?? ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _accountTile(Map entry) {
    final name = entry['name']?.toString() ?? 'User';
    final email = entry['email']?.toString() ?? '';
    final userId = entry['id']?.toString() ?? '';
    final isAdmin = entry['isAdmin'] == true;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFFFF0E4),
        child: Icon(Icons.person_outline, color: Color(0xFFFF7A00)),
      ),
      title: Text(name),
      subtitle: Text(email),
      dense: true,
      trailing: Wrap(spacing: 0, children: [
        IconButton(
          tooltip: 'Message as admin',
          icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFFFF7A00)),
          onPressed: userId.isEmpty || isAdmin
              ? null
              : () => _composeAdminMessage(entry),
        ),
        IconButton(
          tooltip: 'Remove account',
          icon: const Icon(Icons.person_remove_outlined, color: Colors.red),
          onPressed: isAdmin || userId.isEmpty ? null : () => _confirmRemoveAccount(entry),
        ),
      ]),
    );
  }

  Future<void> _composeAdminMessage(Map entry) async {
    final userId = entry['id']?.toString();
    final name = entry['name']?.toString() ?? 'user';
    final password = _adminPassword;
    if (userId == null || password == null) return;
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _AdminMessageDialog(userName: name),
    );
    if (text == null || !mounted) return;
    try {
      await ApiService.sendAdminMessage(
        adminPassword: password,
        userId: userId,
        text: text,
      );
      _showMessage('Message sent from your admin account.');
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _confirmRemoveAccount(Map entry) async {
    final userId = entry['id']?.toString();
    final email = entry['email']?.toString() ?? '';
    final password = _adminPassword;
    if (userId == null || password == null || email.isEmpty) return;
    final confirmation = await showDialog<String>(
      context: context,
      builder: (_) => _RemoveAccountDialog(email: email),
    );
    if (confirmation == null || !mounted) return;
    try {
      final result = await ApiService.removeUserAccount(
        adminPassword: password,
        userId: userId,
        confirmEmail: confirmation,
      );
      await _reloadOverview(password);
      _showMessage(result['mediaCleanupFailed'] == true
          ? 'Account and chat history removed, but some uploaded files could not be deleted.'
          : 'Account, chat history, and uploaded files were removed.');
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _setPasswordPolicy(bool allow) async {
    final password = _adminPassword;
    if (password == null) return;
    setState(() => _loading = true);
    try {
      await ApiService.updateAdminPasswordPolicy(password, allow);
      await _reloadOverview(password);
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reviewRequest(Map request, bool approve) async {
    final password = _adminPassword;
    final id = request['id']?.toString() ?? request['_id']?.toString();
    if (password == null || id == null) return;
    try {
      await ApiService.reviewPasswordRequest(password, id, approve);
      await _reloadOverview(password);
      _showMessage(approve ? 'Password change approved.' : 'Password change denied.');
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _changeAdminPassword() async {
    final values = await showPasswordChangeDialog(context, title: 'Change admin password');
    if (values == null || !mounted) return;
    try {
      await ApiService.changeAdminPassword(currentPassword: values.currentPassword, newPassword: values.newPassword);
      _adminPassword = values.newPassword;
      await _reloadOverview(values.newPassword);
      _showMessage('Admin password changed.');
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _reloadOverview(String password) async {
    final result = await ApiService.getAdminOverview(password);
    if (mounted) setState(() => _overview = result);
  }

  Future<void> _refreshOverview() async {
    final password = _adminPassword;
    if (password == null) return;
    setState(() => _loading = true);
    try {
      await _reloadOverview(password);
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message.replaceFirst('Exception: ', ''))));
  }

  Widget _metricCard({
    required IconData icon,
    required String title,
    required dynamic used,
    required dynamic limit,
    required dynamic remaining,
    String? detail,
    String? setupHint,
    bool unavailable = false,
  }) {
    final usedBytes = _asInt(used);
    final limitBytes = _asInt(limit);
    final remainingBytes = _asInt(remaining);
    final percent = usedBytes != null && limitBytes != null && limitBytes > 0
        ? (usedBytes / limitBytes).clamp(0.0, 1.0).toDouble()
        : null;
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: const Color(0xFFFF7A00)),
            const SizedBox(width: 8),
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 14),
          Text(unavailable
              ? 'Usage report unavailable'
              : 'Used: ${_formatBytes(usedBytes)}'),
          const SizedBox(height: 4),
          Text('Limit: ${_formatBytes(limitBytes)}'),
          Text('Remaining: ${_formatBytes(remainingBytes)}'),
          if (percent != null) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: percent,
              color: const Color(0xFFFF7A00),
              backgroundColor: const Color(0xFFFFE0C7),
              borderRadius: BorderRadius.circular(8),
            ),
          ],
          if (detail != null) ...[
            const SizedBox(height: 8),
            Text(detail, style: const TextStyle(color: Colors.black54)),
          ],
          if (setupHint != null) ...[
            const SizedBox(height: 8),
            Text(setupHint,
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ]),
      ),
    );
  }

  int? _asInt(dynamic value) => value is num ? value.toInt() : null;

  String _formatBytes(int? bytes) {
    if (bytes == null) return 'Not available';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var amount = bytes.toDouble();
    var unit = 0;
    while (amount >= 1024 && unit < units.length - 1) {
      amount /= 1024;
      unit++;
    }
    return '${amount.toStringAsFixed(unit == 0 ? 0 : 2)} ${units[unit]}';
  }
}

class _AdminMessageDialog extends StatefulWidget {
  final String userName;
  const _AdminMessageDialog({required this.userName});

  @override
  State<_AdminMessageDialog> createState() => _AdminMessageDialogState();
}

class _AdminMessageDialogState extends State<_AdminMessageDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Message ${widget.userName}'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(
              'This sends a normal message from your admin account. It does not open or show the user’s existing chat history.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = _controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(context, text);
            },
            child: const Text('Send'),
          ),
        ],
      );
}

class _RemoveAccountDialog extends StatefulWidget {
  final String email;
  const _RemoveAccountDialog({required this.email});

  @override
  State<_RemoveAccountDialog> createState() => _RemoveAccountDialogState();
}

class _RemoveAccountDialogState extends State<_RemoveAccountDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Permanently remove account?'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(
              'This permanently deletes the account, server chat history, and associated uploaded files. Copies already saved on users’ devices cannot be removed. Type the account email to confirm.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            SelectableText(widget.email,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Confirm account email',
                border: OutlineInputBorder(),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _controller.text.trim().toLowerCase() ==
                    widget.email.trim().toLowerCase()
                ? () => Navigator.pop(context, _controller.text.trim())
                : null,
            child: const Text('Remove permanently'),
          ),
        ],
      );
}
