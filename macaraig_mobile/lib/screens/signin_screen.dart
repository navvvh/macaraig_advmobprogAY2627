import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/user.dart';
import '../services/user_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _useFirebase = true;

  @override
  void dispose() { _emailController.dispose(); _passwordController.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final service = UserService();
      final User user;
      if (_useFirebase) {
        user = await service.signIn(_emailController.text.trim(), _passwordController.text);
      } else {
        final result = await service.loginUser(_emailController.text.trim(), _passwordController.text);
        user = User.fromJson(result);
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false, arguments: user.toJson());
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Center(child: SingleChildScrollView(child: Form(
          key: _formKey,
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SvgPicture.asset('assets/images/NU_shield.svg', width: 45, height: 45),
              const SizedBox(width: 12), const Text('Welcome', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12), const Text('Choose a sign-in method.'), const SizedBox(height: 20),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Firebase')),
                ButtonSegment(value: false, label: Text('DummyJSON')),
              ],
              selected: {_useFirebase},
              onSelectionChanged: _isLoading ? null : (selection) => setState(() => _useFirebase = selection.first),
            ),
            const SizedBox(height: 8),
            Text(_useFirebase ? 'Use your Firebase email account.' : 'Use a sample DummyJSON username and password.'),
            const SizedBox(height: 24),
            _field(_emailController, _useFirebase ? 'Email address' : 'Username', keyboardType: _useFirebase ? TextInputType.emailAddress : TextInputType.text, validator: (value) {
              if (value == null || value.trim().isEmpty) return _useFirebase ? 'Enter your email address.' : 'Enter your username.';
              if (_useFirebase && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) return 'Enter a valid email address.';
              return null;
            }),
            const SizedBox(height: 16), _field(_passwordController, 'Password', obscureText: true, validator: (value) => value == null || value.isEmpty ? 'Please enter password.' : null),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3840A2), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: _isLoading ? null : _login,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )),
            if (_useFirebase) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: _isLoading ? null : () => Navigator.pushNamed(context, '/signup'), child: const Text('No account yet? Sign Up')),
            ] else ...[
              const SizedBox(height: 12),
              const Text('Sample: emilys / emilyspass', style: TextStyle(color: Colors.black54)),
            ],
          ]),
        ))),
      )),
    );
  }

  Widget _field(TextEditingController controller, String label, {TextInputType? keyboardType, bool obscureText = false, required String? Function(String?) validator}) => TextFormField(
    controller: controller, keyboardType: keyboardType, obscureText: obscureText, validator: validator,
    decoration: InputDecoration(labelText: label, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3840A2), width: 2))),
  );
}
