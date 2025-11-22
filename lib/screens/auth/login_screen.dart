import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../tasks/task_list_screen.dart';
import '../../widgets/error_chip.dart';
import '../../widgets/success_snackbar.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;
  bool _isLoginMode = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success =
          _isLoginMode
              ? await authProvider.login(email: email, password: password)
              : await authProvider.register(email: email, password: password);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        _emailController.clear();
        _passwordController.clear();
        setState(() => _errorMessage = null);

        SuccessSnackbar.show(
          context,
          message:
              _isLoginMode ? 'Login successful!' : 'Registration successful!',
        );

        await Future.delayed(const Duration(milliseconds: 200));

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const TaskListScreen()),
            (route) => false,
          );
        }
      } else {
        setState(() => _errorMessage = _formatErrorMessage(authProvider.error));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _formatErrorMessage(e.toString());
      });
    }
  }

  String _formatErrorMessage(String? error) {
    if (error == null) return 'Operation failed. Please try again.';

    final errorMsg = error.replaceAll('Exception: ', '');

    if (errorMsg.contains('already exists') || errorMsg.contains('duplicate')) {
      return 'This email is already registered. Please use a different email.';
    }
    if (errorMsg.contains('Connection refused') ||
        errorMsg.contains('Failed host lookup')) {
      return 'Cannot connect to server. Please check if the backend is running.';
    }
    if (errorMsg.contains('401') || errorMsg.contains('Unauthorized')) {
      return 'Invalid email or password. Please try again.';
    }

    return errorMsg;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.appBlack,
      body: SafeArea(
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildHeader(screenHeight),
            _buildContentCard(screenHeight, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double screenHeight) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: screenHeight * 0.35,
      child: Container(
        decoration: const BoxDecoration(color: AppTheme.appBlack),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
                onPressed: () => _showExitDialog(),
              ),
              const SizedBox(height: 20),
              const Text(
                'Go ahead and set up\nyour account',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in-up to enjoy the best managing experience',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard(double screenHeight, ThemeData theme) {
    return Positioned(
      top: screenHeight * 0.28,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildToggleSwitch(),
                const SizedBox(height: 32),
                _buildEmailField(theme),
                const SizedBox(height: 20),
                _buildPasswordField(theme),
                const SizedBox(height: 16),
                _buildRememberMeAndForgot(theme),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  ErrorChip(
                    message: _errorMessage!,
                    onRetry: () {
                      setState(() => _errorMessage = null);
                      _handleSubmit();
                    },
                  ),
                ],
                const SizedBox(height: 24),
                _buildSubmitButton(theme),
                const SizedBox(height: 32),
                _buildDivider(theme),
                const SizedBox(height: 24),
                _buildSocialButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSwitch() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor =
        isDark ? theme.cardColor.withOpacity(0.1) : Colors.grey.shade100;
    final selectedBg = isDark ? theme.cardColor : Colors.white;
    final selectedTextColor =
        isDark ? theme.textTheme.titleLarge?.color : theme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildToggleSegment(
            label: 'Login',
            isSelected: _isLoginMode,
            isDark: isDark,
            selectedBg: selectedBg,
            selectedTextColor: selectedTextColor,
            onTap: () => setState(() => _isLoginMode = true),
          ),
          _buildToggleSegment(
            label: 'Register',
            isSelected: !_isLoginMode,
            isDark: isDark,
            selectedBg: selectedBg,
            selectedTextColor: selectedTextColor,
            onTap: () => setState(() => _isLoginMode = false),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSegment({
    required String label,
    required bool isSelected,
    required bool isDark,
    required Color selectedBg,
    required Color? selectedTextColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? selectedTextColor : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade800 : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: isDark ? Colors.grey.shade800 : Colors.black),
          decoration: _buildInputDecoration(
            theme: theme,
            isDark: isDark,
            hintText: 'Enter your email',
            prefixIcon: Icons.email_outlined,
          ),
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Please enter your email';
            if (!value.contains('@')) return 'Please enter a valid email';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade800 : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          style: TextStyle(color: isDark ? Colors.grey.shade800 : Colors.black),
          decoration: _buildInputDecoration(
            theme: theme,
            isDark: isDark,
            hintText: 'Enter your password',
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: theme.colorScheme.primary,
              ),
              onPressed:
                  () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Please enter your password';
            if (value.length < 6)
              return 'Password must be at least 6 characters';
            return null;
          },
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required ThemeData theme,
    required bool isDark,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    final borderColor =
        isDark
            ? theme.dividerColor.withOpacity(0.5)
            : AppTheme.lightText.withOpacity(0.6);

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade400,
      ),
      prefixIcon: Icon(prefixIcon, color: theme.colorScheme.primary),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
    );
  }

  Widget _buildRememberMeAndForgot(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _rememberMe,
                onChanged:
                    (value) => setState(() => _rememberMe = value ?? false),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
                checkColor: theme.primaryColor,
                fillColor: WidgetStateProperty.all(Colors.grey.shade100),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Remember me',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade700 : Colors.black,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            'Forgot Password?',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child:
            _isLoading
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Text(
                  _isLoginMode ? 'Login' : 'Register',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: Divider(color: theme.dividerColor.withOpacity(0.3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Or login with',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
          ),
        ),
        Expanded(child: Divider(color: theme.dividerColor.withOpacity(0.3))),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            icon: Icons.g_mobiledata_rounded,
            label: 'Google',
            onTap: () {},
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(
            icon: Icons.facebook_rounded,
            label: 'Facebook',
            onTap: () {},
            color: const Color(0xFF1877F2),
          ),
        ),
      ],
    );
  }

  Future<void> _showExitDialog() async {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder:
          (context) => _ExitDialog(theme: theme, screenHeight: screenHeight),
    );
  }
}

class _ExitDialog extends StatelessWidget {
  final ThemeData theme;
  final double screenHeight;

  const _ExitDialog({required this.theme, required this.screenHeight});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        height: screenHeight * 0.4,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          children: [_buildDialogHeader(), _buildDialogContent(context)],
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: screenHeight * 0.15,
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.appBlack,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Exit Application',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Positioned(
      top: screenHeight * 0.1,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.exit_to_app_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Do you want to exit the application? This action will terminate the app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppTheme.lightText.withOpacity(0.6),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => SystemNavigator.pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Exit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isGoogle = label == 'Google';

    return Material(
      color: isGoogle ? Colors.white : color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isGoogle ? Colors.grey.shade300 : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isGoogle)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      'G',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                )
              else
                Icon(icon, size: 24, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isGoogle ? Colors.black87 : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
