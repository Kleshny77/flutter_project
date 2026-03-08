import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/auth_service.dart';
import '../../auth/screens/forgot_password_email_screen.dart';
import '../../home/data/home_preferences.dart';
import '../data/user_profile_repository.dart';
import '../models/user_profile.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.userId,
    required this.onSignOut,
    this.fallbackEmail,
    this.repository,
  });

  final String userId;
  final String? fallbackEmail;
  final Future<void> Function() onSignOut;
  final UserProfileRepository? repository;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final UserProfileRepository _repository =
      widget.repository ?? UserProfileRepository();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  UserProfile _originalProfile = const UserProfile.empty();
  Uint8List? _avatarBytes;
  bool _loading = true;
  bool _saving = false;
  bool _showLogoutDialog = false;

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_handleFormChanged);
    _lastNameController.addListener(_handleFormChanged);
    _emailController.addListener(_handleFormChanged);
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_handleFormChanged);
    _lastNameController.removeListener(_handleFormChanged);
    _emailController.removeListener(_handleFormChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FBFF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              if (_loading)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0773F1)),
                )
              else
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _ProfileCircleActionButton(
                          assetPath: 'assets/images/auth/back_button.png',
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildAvatarSection(),
                      const SizedBox(height: 22),
                      _ProfileOutlineButton(
                        label: 'Изменить фотографию',
                        iconPath: 'assets/images/profile/camera.png',
                        onTap: _pickAvatar,
                      ),
                      const SizedBox(height: 22),
                      _buildNameCard(),
                      const SizedBox(height: 14),
                      _ProfileTextField(
                        controller: _emailController,
                        hintText: 'E-mail',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _ProfileOutlineButton(
                        label: 'Сменить пароль',
                        iconPath: 'assets/images/profile/lock_vitamins.png',
                        trailingPath: 'assets/images/profile/chevron.png',
                        onTap: _openPasswordReset,
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: 134,
                        height: 42,
                        child: ElevatedButton(
                          onPressed: _hasChanges && !_saving ? _saveProfile : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasChanges
                                ? const Color(0xFF0E75F2)
                                : const Color.fromRGBO(105, 105, 105, 0.5),
                            disabledBackgroundColor: const Color.fromRGBO(
                              105,
                              105,
                              105,
                              0.5,
                            ),
                            foregroundColor: Colors.white,
                            elevation: _hasChanges ? 10 : 0,
                            shadowColor: const Color(0xFF0E75F2).withValues(
                              alpha: 0.3,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(80.67),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Готово',
                                  style: TextStyle(
                                    fontFamily: 'Commissioner',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ProfileOutlineButton(
                        label: 'Выйти из аккаунта',
                        textColor: Colors.red,
                        onTap: () {
                          setState(() {
                            _showLogoutDialog = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              if (_showLogoutDialog) ...[
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.75),
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: _LogoutDialog(
                      onCancel: () {
                        setState(() {
                          _showLogoutDialog = false;
                        });
                      },
                      onConfirm: _signOut,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    final imageProvider = _avatarBytes != null
        ? MemoryImage(_avatarBytes!)
        : const AssetImage('assets/images/home/profile.png') as ImageProvider;

    return Column(
      children: [
        Container(
          width: 184,
          height: 184,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            ),
          ),
        ),
        IgnorePointer(
          child: Container(
            width: 184,
            height: 184,
            margin: const EdgeInsets.only(top: -184),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                width: 4,
                color: const Color(0xFF88A4FF),
              ),
              gradient: const LinearGradient(
                colors: [
                  Color.fromRGBO(231, 240, 255, 0.82),
                  Color(0xFF88A4FF),
                  Color.fromRGBO(180, 210, 255, 0.55),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameCard() {
    return Container(
      width: 318,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _ProfileTextField(
            controller: _firstNameController,
            hintText: 'Имя',
            underline: false,
          ),
          Container(
            height: 2,
            margin: const EdgeInsets.only(top: 4, bottom: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromRGBO(90, 129, 255, 0.49),
                  Color.fromRGBO(86, 125, 255, 0.53),
                  Color.fromRGBO(78, 120, 255, 0.49),
                ],
              ),
            ),
          ),
          _ProfileTextField(
            controller: _lastNameController,
            hintText: 'Фамилия',
            underline: false,
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: const Color(0xFF88A4FF), width: 1.6),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  Future<void> _loadProfile() async {
    final profile = await _repository.loadProfile(
      userId: widget.userId,
      fallbackEmail: widget.fallbackEmail,
    );

    if (!mounted) {
      return;
    }

    _firstNameController.text = profile.firstName;
    _lastNameController.text = profile.lastName;
    _emailController.text = profile.email;

    setState(() {
      _originalProfile = profile;
      _avatarBytes = profile.avatarBytes;
      _loading = false;
    });
  }

  Future<void> _pickAvatar() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _avatarBytes = bytes;
    });
  }

  void _handleFormChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openPasswordReset() async {
    final authService = AuthService();
    final initialEmail = _emailController.text.trim();

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ForgotPasswordEmailScreen(
          authService: authService,
          initialEmail: initialEmail,
          onSendCode: authService.sendPasswordResetEmail,
          onBack: () => Navigator.of(context).pop(),
          onSent: (email) async {
            if (!mounted) {
              return;
            }
            await showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text(
                  'Проверьте почту',
                  style: TextStyle(
                    fontFamily: 'Commissioner',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                content: Text(
                  'Мы отправили письмо для сброса пароля на\n$email',
                  style: const TextStyle(fontFamily: 'Commissioner'),
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text(
                      'Ок',
                      style: TextStyle(
                        fontFamily: 'Commissioner',
                        color: Color(0xFF0773F1),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() {
      _saving = true;
    });

    final profile = UserProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      avatarBytes: _avatarBytes,
    );

    try {
      await _repository.saveProfile(userId: widget.userId, profile: profile);
      if (!mounted) {
        return;
      }

      setState(() {
        _originalProfile = profile;
        _saving = false;
      });
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
      });
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(
            'Не удалось сохранить',
            style: TextStyle(
              fontFamily: 'Commissioner',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            error.toString(),
            style: const TextStyle(fontFamily: 'Commissioner'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Ок',
                style: TextStyle(
                  fontFamily: 'Commissioner',
                  color: Color(0xFF0773F1),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await _repository.clearLocalProfile(widget.userId);
    await PostRegistrationOnboardingStorage().markCompleted();
    if (!mounted) {
      return;
    }
    await widget.onSignOut();
  }

  bool get _hasChanges {
    return _firstNameController.text.trim() != _originalProfile.firstName ||
        _lastNameController.text.trim() != _originalProfile.lastName ||
        _emailController.text.trim() != _originalProfile.email ||
        !_sameAvatar(_avatarBytes, _originalProfile.avatarBytes);
  }

  bool _sameAvatar(Uint8List? left, Uint8List? right) {
    if (left == null && right == null) {
      return true;
    }
    if (left == null || right == null || left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.underline = true,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool underline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 318,
      height: underline ? 63 : null,
      decoration: underline
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFF88A4FF), width: 1.6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : null,
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: 'Commissioner',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFF5F5F5F),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontFamily: 'Commissioner',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5F5F5F),
          ),
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: underline ? 18 : 0,
            vertical: underline ? 18 : 0,
          ),
        ),
      ),
    );
  }
}

class _ProfileOutlineButton extends StatelessWidget {
  const _ProfileOutlineButton({
    required this.label,
    required this.onTap,
    this.iconPath,
    this.trailingPath,
    this.textColor = const Color(0xFF0773F1),
  });

  final String label;
  final VoidCallback onTap;
  final String? iconPath;
  final String? trailingPath;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: 318,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFF88A4FF), width: 1.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            if (iconPath != null) ...[
              Image.asset(iconPath!, width: 24, height: 20, fit: BoxFit.contain),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            if (trailingPath != null)
              Image.asset(
                trailingPath!,
                width: 12,
                height: 18,
                fit: BoxFit.contain,
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCircleActionButton extends StatelessWidget {
  const _ProfileCircleActionButton({
    required this.assetPath,
    required this.onTap,
  });

  final String assetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Image.asset(assetPath, width: 22, height: 22),
      ),
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog({
    required this.onCancel,
    required this.onConfirm,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 318,
      height: 229,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF88A4FF), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Выйти?',
            style: TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 29,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0773F1),
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              'При выходе из аккаунта ваши\nнастройки и добавленные\nвитамины не будут удалены,\nтак что вы сможете вернуться',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7A7A7A),
                height: 1.2,
              ),
            ),
          ),
          const Spacer(),
          Container(height: 2, color: const Color(0xFF7A8BFF).withValues(alpha: 0.25)),
          SizedBox(
            height: 48,
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel,
                    child: const Text(
                      'Отмена',
                      style: TextStyle(
                        fontFamily: 'Commissioner',
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0773F1),
                      ),
                    ),
                  ),
                ),
                Container(width: 2, color: const Color(0xFF7A8BFF).withValues(alpha: 0.25)),
                Expanded(
                  child: TextButton(
                    onPressed: onConfirm,
                    child: const Text(
                      'Выйти',
                      style: TextStyle(
                        fontFamily: 'Commissioner',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0773F1),
                      ),
                    ),
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
