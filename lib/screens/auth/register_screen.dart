// Layar pendaftaran pengguna.

import 'package:flutter/material.dart';

import '../../core/constants/app_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _standName = TextEditingController();
  UserRole _role = UserRole.pembeli;
  bool _isLoading = false;
  String _error = '';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _standName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _password.text.trim().isEmpty) {
      setState(() => _error = 'Lengkapi nama, email, nomor HP, dan password.');
      return;
    }
    if (_role == UserRole.penjual && _standName.text.trim().isEmpty) {
      setState(() => _error = 'Masukkan nama stand kamu.');
      return;
    }
    setState(() {
      _error = '';
      _isLoading = true;
    });

    try {
      await _authService.daftar(
        nama: _name.text,
        email: _email.text,
        noHp: _phone.text,
        password: _password.text,
        role: _role,
        namaStand: _role == UserRole.penjual ? _standName.text : '',
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSeller = _role == UserRole.penjual;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Daftar Akun'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Daftar sebagai'),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          for (final option in const [
                            UserRole.pembeli,
                            UserRole.penjual,
                          ])
                            Expanded(
                              child: Material(
                                color: _role == option
                                    ? AppColors.accent
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => setState(() => _role = option),
                                  child: SizedBox(
                                    height: 40,
                                    child: Center(
                                      child: Text(
                                        option.label,
                                        style: hapText(
                                          13,
                                          weight: FontWeight.w700,
                                          color: _role == option
                                              ? AppColors.textDark
                                              : AppColors.textSoft,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Nama lengkap',
                      child: HapField(
                        controller: _name,
                        hint: 'Contoh: Yusuf Ramadhan',
                      ),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Email',
                      child: HapField(
                        controller: _email,
                        hint: 'nama@kampus.ac.id',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Nomor HP',
                      child: HapField(
                        controller: _phone,
                        hint: '0812-3456-7890',
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    if (isSeller) ...[
                      const SizedBox(height: 16),
                      LabeledField(
                        label: 'Nama stand',
                        child: HapField(
                          controller: _standName,
                          hint: 'Contoh: Warung Mbak Siti',
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Password',
                      child: HapField(
                        controller: _password,
                        hint: 'Minimal 6 karakter',
                        obscure: true,
                      ),
                    ),
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ErrorText(_error),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: _isLoading ? 'Sedang mendaftar...' : 'Daftar',
                      onPressed: _isLoading ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
