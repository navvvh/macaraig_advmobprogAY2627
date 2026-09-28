import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user});
  final User user;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = UserService();
  late User _user;
  @override
  void initState() { super.initState(); _user = widget.user; _load(); }
  Future<void> _load() async { final user = await _service.getUser(); if (mounted) setState(() => _user = user); }
  Future<void> _logout() async { await _service.signOut(); if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false); }

  Future<void> _usernameDialog() async {
    final controller = TextEditingController(text: _user.username);
    final value = await _dialog('Update username', controller, 'Username');
    if (value == null) return;
    try { await _service.updateUsername(value); await _load(); if (mounted) _message('Username updated.'); } catch (e) { _message(e.toString()); }
  }
  Future<void> _passwordDialog() async {
    final current = TextEditingController(); final next = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Change password'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: current, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')), TextField(controller: next, obscureText: true, decoration: const InputDecoration(labelText: 'New password (6+ characters)'))]), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Change'))]));
    if (confirmed != true) return;
    try { if (next.text.length < 6) throw Exception('New password must be at least 6 characters.'); await _service.resetPasswordFromCurrentPassword(currentPassword: current.text, newPassword: next.text); _message('Password changed.'); } catch (e) { _message(e.toString()); }
  }
  Future<void> _deleteDialog() async {
    final password = TextEditingController();
    final value = await _dialog('Delete account', password, 'Current password', obscureText: true, action: 'Delete');
    if (value == null) return;
    try { await _service.deleteAccount(value); if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false); } catch (e) { _message(e.toString()); }
  }
  Future<String?> _dialog(String title, TextEditingController controller, String label, {bool obscureText = false, String action = 'Save'}) => showDialog<String>(context: context, builder: (context) => AlertDialog(title: Text(title), content: TextField(controller: controller, obscureText: obscureText, decoration: InputDecoration(labelText: label)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(action))]));
  void _message(String message) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message.replaceFirst('Exception: ', '')))); }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(color: Theme.of(context).scaffoldBackgroundColor, child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 24), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)), child: Column(children: [
        CircleAvatar(radius: 40, backgroundImage: _user.image.isNotEmpty ? NetworkImage(_user.image) : null, child: _user.image.isEmpty ? const Icon(Icons.person, size: 40) : null), const SizedBox(height: 12),
        Text('${_user.firstName} ${_user.lastName}'.trim().isEmpty ? _user.username : '${_user.firstName} ${_user.lastName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('@${_user.username}', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600)),
      ])), const SizedBox(height: 16),
      _card([_row(Icons.email_outlined, 'Email', _user.email), _row(Icons.cake_outlined, 'Age', _user.age), _row(Icons.phone_outlined, 'Contact', _user.contactNo), _row(Icons.login_outlined, 'Login type', _user.loginType == 'firebase' ? 'Firebase' : 'DummyJSON')]), const SizedBox(height: 16),
      _card([
        _action(Icons.person_outline, 'Update username', _usernameDialog),
        if (_user.loginType == 'firebase') ...[
          _action(Icons.lock_outline, 'Change password', _passwordDialog),
          _action(Icons.delete_outline, 'Delete account', _deleteDialog, color: colors.error),
        ] else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('DummyJSON is a sample API; password and account changes are not available here.'),
          ),
      ]), const SizedBox(height: 24),
      SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), onPressed: _logout, icon: const Icon(Icons.logout), label: const Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
    ])));
  }
  Widget _card(List<Widget> children) => Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)), child: Column(children: children));
  Widget _row(IconData icon, String label, String value) => ListTile(contentPadding: EdgeInsets.zero, leading: Icon(icon), title: Text(label), trailing: SizedBox(width: 160, child: Text(value.isEmpty ? '—' : value, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)));
  Widget _action(IconData icon, String label, VoidCallback onTap, {Color? color}) => ListTile(contentPadding: EdgeInsets.zero, leading: Icon(icon, color: color), title: Text(label, style: TextStyle(color: color)), trailing: const Icon(Icons.chevron_right), onTap: onTap);
}
