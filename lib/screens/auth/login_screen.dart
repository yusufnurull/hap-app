// Layar masuk pengguna.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import '../role_home.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'yusuf@kampus.ac.id');
  final _password = TextEditingController(text: 'kantin123');
  bool _showPassword = false;
  String _error = '';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_email.text.trim().isEmpty || _password.text.trim().isEmpty) {
      setState(() => _error = 'Isi email dan password terlebih dahulu.');
      return;
    }
    setState(() => _error = '');
    final role = context.read<AuthProvider>().login(_email.text.trim());
    goToRoleHome(context, role);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hap!',
                  style: hapText(22,
                      weight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.5)),
              const SizedBox(height: 20),
              Text('Masuk ke akunmu',
                  style: hapText(24, weight: FontWeight.w800, height: 1.2)),
              const SizedBox(height: 6),
              Text(
                'Pesan makanan dari kelas dan ambil pas jam istirahat.',
                style: hapText(14, color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 28),
              LabeledField(
                label: 'Email kampus',
                child: HapField(
                  controller: _email,
                  hint: 'nama@kampus.ac.id',
                  keyboardType: TextInputType.emailAddress,
                  vertical: 14,
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Password',
                child: HapField(
                  controller: _password,
                  hint: 'Masukkan password',
                  obscure: !_showPassword,
                  vertical: 14,
                  suffix: IconButton(
                    tooltip: _showPassword
                        ? 'Sembunyikan password'
                        : 'Lihat password',
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                ErrorText(_error),
              ],
              const SizedBox(height: 24),
              PrimaryButton(label: 'Masuk', onPressed: _submit),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Belum punya akun?',
                      style: hapText(14, color: AppColors.textSoft)),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RegisterScreen(),
                      ),
                    ),
                    child: Text('Daftar',
                        style: hapText(14,
                            weight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
