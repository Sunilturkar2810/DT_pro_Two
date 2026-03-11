import 'package:d_table_delegate_system/provider/auth_provider.dart';
import 'package:d_table_delegate_system/widget/app_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final designationController = TextEditingController();
  final departmentController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  String _selectedRole = 'User';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    designationController.dispose();
    departmentController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF20E19F);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Gradient
            Container(
              height: MediaQuery.of(context).size.height * 0.25,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryColor,
                    primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(80),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fill the details to get started',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: firstNameController,
                            label: 'First Name',
                            hint: 'John',
                            icon: Icons.person_outline,
                            primaryColor: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildTextField(
                            controller: lastNameController,
                            label: 'Last Name',
                            hint: 'Doe',
                            icon: Icons.person_outline,
                            primaryColor: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: emailController,
                      label: 'Work Email',
                      hint: 'name@company.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: mobileController,
                      label: 'Mobile Number',
                      hint: '+1 234 567 890',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: designationController,
                            label: 'Designation',
                            hint: 'Manager',
                            icon: Icons.work_outline,
                            primaryColor: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildTextField(
                            controller: departmentController,
                            label: 'Department',
                            hint: 'Sales',
                            icon: Icons.business_outlined,
                            primaryColor: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Role Dropdown
                    _buildDropdown(primaryColor),

                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: passwordController,
                      label: 'Password',
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      primaryColor: primaryColor,
                      onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: confirmController,
                      label: 'Confirm Password',
                      hint: '••••••••',
                      icon: Icons.lock_reset_outlined,
                      isPassword: true,
                      obscureText: _obscureConfirm,
                      primaryColor: primaryColor,
                      onTogglePassword: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v != passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),

                    const SizedBox(height: 30),

                    // Sign Up Button
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : () async {
                              if (!_formKey.currentState!.validate()) return;

                              final success = await auth.register(
                                firstName: firstNameController.text.trim(),
                                lastName: lastNameController.text.trim(),
                                workEmail: emailController.text.trim(),
                                password: passwordController.text,
                                mobileNumber: mobileController.text.trim(),
                                role: _selectedRole,
                                designation: designationController.text.trim(),
                                department: departmentController.text.trim(),
                              );

                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Registration Successful! Please Login.'), backgroundColor: Colors.green)
                                );
                                Navigator.pop(context);
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(auth.errorMessage ?? 'Signup Failed'), backgroundColor: Colors.redAccent)
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                              shadowColor: primaryColor.withOpacity(0.4),
                            ),
                            child: auth.isLoading
                                ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                                : const Text(
                              'SIGN UP',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 25),

                    // Login Navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            "Login",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
    required Color primaryColor,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator ?? (v) => v == null || v.isEmpty ? 'Required' : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(icon, color: primaryColor, size: 22),
              suffixIcon: isPassword
                  ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey[400], size: 20),
                onPressed: onTogglePassword,
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              errorStyle: const TextStyle(height: 0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(Color primaryColor) {
    return AppDropdown<String>(
      isCompact: false,
      value: _selectedRole,
      items: const ['User', 'Admin', 'Manager'],
      labelBuilder: (v) => v,
      label: 'ROLE',
      prefixIcon: Icons.security_outlined,
      accentColor: primaryColor,
      onChanged: (v) {
        if (v != null) setState(() => _selectedRole = v);
      },
    );
  }
}