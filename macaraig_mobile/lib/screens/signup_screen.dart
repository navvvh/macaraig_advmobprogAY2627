import 'package:flutter/material.dart';

import '../services/user_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _age = TextEditingController();
  final _contactNo = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    for (final controller in [_firstName, _lastName, _age, _contactNo, _username, _email, _password]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await UserService().createAccount(
        firstName: _firstName.text.trim(), lastName: _lastName.text.trim(),
        age: _age.text.trim(), contactNo: _contactNo.text.trim(),
        username: _username.text.trim(), emailAddress: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false, arguments: user.toJson());
    } catch (error) {
      if (mounted) _show(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  String? _required(String? value, String label) => value == null || value.trim().isEmpty ? '$label is required.' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: const Color(0xFF1E1E1E)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E))),
              const SizedBox(height: 6),
              const Text('Enter your details to sign up with Firebase.'),
              const SizedBox(height: 24),
              _field(_firstName, 'First name'), _field(_lastName, 'Last name'),
              _field(_age, 'Age', keyboardType: TextInputType.number, validator: (value) {
                final required = _required(value, 'Age');
                if (required != null) return required;
                return int.tryParse(value!.trim()) == null ? 'Enter a valid age.' : null;
              }),
              _field(_contactNo, 'Contact number', keyboardType: TextInputType.phone),
              _field(_username, 'Username'),
              _field(_email, 'Email address', keyboardType: TextInputType.emailAddress, validator: (value) {
                final required = _required(value, 'Email address');
                if (required != null) return required;
                return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim()) ? null : 'Enter a valid email address.';
              }),
              _field(_password, 'Password', obscureText: true, validator: (value) {
                final required = _required(value, 'Password');
                if (required != null) return required;
                return value!.length < 6 ? 'Password must be at least 6 characters.' : null;
              }),
              const SizedBox(height: 8),
              SizedBox(height: 52, child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3840A2), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _loading ? null : _signUp,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              )),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {TextInputType? keyboardType, bool obscureText = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller, keyboardType: keyboardType, obscureText: obscureText,
        validator: validator ?? (value) => _required(value, label),
        decoration: InputDecoration(labelText: label, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }
}
