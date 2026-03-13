import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/app_dialog.dart';
import '../../../domain/repositories/auth_repository.dart';
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
    this.authRepository,
  });

  final String userId;
  final String? fallbackEmail;
  final Future<void> Function() onSignOut;
  final UserProfileRepository? repository;
  final AuthRepository? authRepository;

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
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final compactLayout = viewportHeight <= 860;
    const contentWidth = 320.0;
    final topSpacing = compactLayout ? 6.0 : 10.0;
    final sectionSpacing = compactLayout ? 18.0 : 24.0;
    final fieldSpacing = compactLayout ? 14.0 : 18.0;
    final primarySpacing = compactLayout ? 20.0 : 28.0;
    final logoutSpacing = compactLayout ? 18.0 : 26.0;

    return Scaffold(
      backgroundColor: Colors.white,
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
                  padding: EdgeInsets.fromLTRB(
                    20,
                    compactLayout ? 10 : 12,
                    20,
                    compactLayout ? 20 : 30,
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _ProfileCircleActionButton(
                          assetPath: 'assets/images/home/back_button.png',
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      SizedBox(height: topSpacing),
                      _buildAvatarSection(compactLayout),
                      SizedBox(height: sectionSpacing),
                      SizedBox(
                        width: contentWidth,
                        child: _ProfileOutlineButton(
                          label: 'Изменить фотографию',
                          iconPath: 'assets/images/profile/camera.png',
                          onTap: _pickAvatar,
                          compact: compactLayout,
                        ),
                      ),
                      SizedBox(height: sectionSpacing),
                      _buildNameCard(compactLayout),
                      SizedBox(height: fieldSpacing),
                      SizedBox(
                        width: contentWidth,
                        child: _ProfileTextField(
                          controller: _emailController,
                          hintText: 'E-mail',
                          keyboardType: TextInputType.emailAddress,
                          compact: compactLayout,
                        ),
                      ),
                      SizedBox(height: fieldSpacing),
                      SizedBox(
                        width: contentWidth,
                        child: _ProfileOutlineButton(
                          label: 'Сменить пароль',
                          iconPath: 'assets/images/profile/lock_vitamins.png',
                          trailingPath: 'assets/images/profile/chevron.png',
                          onTap: _openPasswordReset,
                          compact: compactLayout,
                        ),
                      ),
                      SizedBox(height: primarySpacing),
                      SizedBox(
                        width: compactLayout ? 150 : 164,
                        height: compactLayout ? 54 : 62,
                        child: FilledButton(
                          onPressed: _hasChanges && !_saving
                              ? _saveProfile
                              : null,
                          style: FilledButton.styleFrom(
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
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
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
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: logoutSpacing),
                      SizedBox(
                        width: contentWidth,
                        child: _ProfileOutlineButton(
                          label: 'Выйти из аккаунта',
                          textColor: const Color(0xFFEA3E3E),
                          compact: compactLayout,
                          onTap: () {
                            setState(() {
                              _showLogoutDialog = true;
                            });
                          },
                        ),
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

  Widget _buildAvatarSection(bool compact) {
    final imageProvider = _avatarBytes != null
        ? MemoryImage(_avatarBytes!)
        : const AssetImage('assets/images/profile/profile.png')
              as ImageProvider;

    final outerSize = compact ? 168.0 : 196.0;
    final borderWidth = compact ? 5.0 : 6.0;
    final padding = compact ? 8.0 : 10.0;

    return Container(
      width: outerSize,
      height: outerSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(width: borderWidth, color: const Color(0xFF4567C4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF88A4FF).withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(padding),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: Image(image: imageProvider, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildNameCard(bool compact) {
    return Container(
      width: 320,
      padding: EdgeInsets.fromLTRB(
        18,
        compact ? 14 : 18,
        18,
        compact ? 12 : 16,
      ),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _ProfileTextField(
            controller: _firstNameController,
            hintText: 'Имя',
            standalone: false,
            compact: compact,
          ),
          Container(
            height: 3,
            margin: EdgeInsets.only(
              top: compact ? 8 : 10,
              bottom: compact ? 8 : 10,
            ),
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
            standalone: false,
            compact: compact,
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
    final auth = widget.authRepository;
    if (auth == null) {
      return;
    }
    final initialEmail = _emailController.text.trim();

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ForgotPasswordEmailScreen(
          authRepository: auth,
          initialEmail: initialEmail,
          onSendCode: auth.sendPasswordResetEmail,
          onBack: () => Navigator.of(context).pop(),
          onSent: (email) async {
            if (!mounted) {
              return;
            }
            await AppDialog.showInfo(
              context,
              title: 'Проверьте почту',
              message: 'Мы отправили письмо для сброса пароля на\n$email',
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
      await AppDialog.showInfo(
        context,
        title: 'Не удалось сохранить',
        message: error.toString(),
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
    this.standalone = true,
    this.compact = false,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool standalone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 22.0 : 26.0;
    return Container(
      width: double.infinity,
      constraints: standalone
          ? BoxConstraints(minHeight: compact ? 76 : 92)
          : BoxConstraints(minHeight: compact ? 44 : 54),
      decoration: standalone
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
        cursorColor: const Color(0xFF0773F1),
        style: const TextStyle(
          fontFamily: 'Commissioner',
          fontWeight: FontWeight.w700,
          color: Color(0xFF5F5F5F),
        ).copyWith(fontSize: fontSize),
        decoration: InputDecoration(
          hintText: hintText,
          filled: false,
          fillColor: Colors.transparent,
          hintStyle: const TextStyle(
            fontFamily: 'Commissioner',
            fontWeight: FontWeight.w700,
            color: Color(0xFF5F5F5F),
          ).copyWith(fontSize: fontSize),
          isCollapsed: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: standalone ? 22 : 4,
            vertical: standalone ? (compact ? 20 : 24) : (compact ? 2 : 4),
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
    this.compact = false,
  });

  final String label;
  final VoidCallback onTap;
  final String? iconPath;
  final String? trailingPath;
  final Color textColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: compact ? 52 : 58,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF88A4FF), width: 1.6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (iconPath != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    iconPath!,
                    width: compact ? 26 : 28,
                    height: compact ? 22 : 24,
                    fit: BoxFit.contain,
                  ),
                ),
              Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Commissioner',
                    fontSize: compact ? 15 : 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              if (trailingPath != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Image.asset(
                    trailingPath!,
                    width: compact ? 13 : 14,
                    height: compact ? 20 : 22,
                    fit: BoxFit.contain,
                  ),
                ),
            ],
          ),
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
        width: 54,
        height: 54,
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
        child: Image.asset(assetPath, width: 26, height: 23),
      ),
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog({required this.onCancel, required this.onConfirm});

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
          Container(
            height: 2,
            color: const Color(0xFF7A8BFF).withValues(alpha: 0.25),
          ),
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
                Container(
                  width: 2,
                  color: const Color(0xFF7A8BFF).withValues(alpha: 0.25),
                ),
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
