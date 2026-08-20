import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();

  void _logout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9F9FF),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.transparent,
                    backgroundImage: widget.user.image.isNotEmpty
                        ? NetworkImage(widget.user.image)
                        : null,
                    child: widget.user.image.isEmpty
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.user.firstName} ${widget.user.lastName}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${widget.user.username}',
                    style: const TextStyle(
                      color: Color(0xFFF1C40F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildRow(Icons.email_outlined, 'Email', widget.user.email),
                  const Divider(height: 1),
                  _buildRow(Icons.wc_outlined, 'Gender', widget.user.gender),
                  const Divider(height: 1),
                  _buildRow(Icons.badge_outlined, 'User ID', '#${widget.user.id}'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5252),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF1C40F), size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}