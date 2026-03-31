import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../provider/auth_provider.dart';
import '../../model/user_model.dart';
import '../../utils/phone_number_helper.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({Key? key}) : super(key: key);

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _workEmailController;
  late TextEditingController _mobileNumberController;
  
  bool _taskAccess = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _workEmailController = TextEditingController(text: user?.workEmail ?? '');
    _mobileNumberController = TextEditingController(
      text: extractIndianPhoneDigits(user?.mobileNumber),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _workEmailController.dispose();
    _mobileNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final mobileError =
        indianPhoneValidationMessage(_mobileNumberController.text.trim());
    if (mobileError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mobileError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    final authProvider = context.read<AuthProvider>();
    
    final updates = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'workEmail': _workEmailController.text.trim(),
      'mobileNumber': _mobileNumberController.text.trim(),
    };
    
    final success = await authProvider.updateProfile(updates);
    
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Profile updated successfully' : 'Failed to update profile'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  bool _isUploadingPhoto = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        if (!mounted) return;
        setState(() => _isUploadingPhoto = true);
        
        final authProvider = context.read<AuthProvider>();
        final success = await authProvider.uploadProfileImage(File(pickedFile.path));
        
        if (mounted) {
          setState(() => _isUploadingPhoto = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'Profile photo updated' : 'Failed to update photo'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Update Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF), // blue-50
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF3B82F6)),
                ),
                title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5), // emerald-50
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image, color: Color(0xFF10B981)),
                ),
                title: const Text('Browse Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "GENERAL",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: const Color(0xFF20E19F),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMyProfileCard(user),
              const SizedBox(height: 16),
              _buildCareerRoleCard(user),
              const SizedBox(height: 16),
              _buildPersonalInfoCard(user),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyProfileCard(UserModel? user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Image Area
          Stack(
            children: [
              Container(
                height: 140,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9), // slate-100
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: user?.profilePhotoUrl != null
                          ? ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                              child: Image.network(
                                user!.profilePhotoUrl!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.person_outline,
                              size: 60,
                              color: Color(0xFFCBD5E1),
                            ),
                    ),
                    if (_isUploadingPhoto)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 8),
                            Text(
                              'UPLOADING...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, size: 20, color: Color(0xFF475569)),
                    onPressed: _showPhotoOptions,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(10),
                  ),
                ),
              ),
            ],
          ),
          
          // Form Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Area
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "My profile",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "LAST UPDATE: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}",
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "STATUS",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: const [
                              CircleAvatar(radius: 4, backgroundColor: Color(0xFF10B981)),
                              SizedBox(width: 4),
                              Text(
                                "ACTIVE",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Text Fields
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField("FIRST NAME", _firstNameController),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField("LAST NAME", _lastNameController),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField("WORK EMAIL", _workEmailController, icon: Icons.mail_outline),
                  const SizedBox(height: 16),
                  _buildTextField(
                    "MOBILE NUMBER",
                    _mobileNumberController,
                    icon: Icons.phone_outlined,
                    isPhone: true,
                  ),
                  const SizedBox(height: 24),
                  
                  // Task Access Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Task Access activation", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFFB923C))),
                          Text("Allow user to manage and see assigned tasks", style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                        ],
                      ),
                      Switch(
                        value: _taskAccess,
                        onChanged: (val) => setState(() => _taskAccess = val),
                        activeColor: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        shadowColor: const Color(0xFFFB923C).withOpacity(0.3),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFB923C), Color(0xFFEC4899)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  "SAVE PROFILE",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    bool isPhone = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          inputFormatters: isPhone ? indianPhoneInputFormatters() : null,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          decoration: isPhone
              ? buildIndianPhoneDecoration(
                  context,
                  decoration: InputDecoration(
                    suffixIcon: icon != null ? Icon(icon, size: 18, color: const Color(0xFFCBD5E1)) : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    isDense: true,
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 2),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFB923C), width: 2),
                    ),
                  ),
                )
              : InputDecoration(
            suffixIcon: icon != null ? Icon(icon, size: 18, color: const Color(0xFFCBD5E1)) : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            isDense: true,
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 2),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFB923C), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCareerRoleCard(UserModel? user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.work_outline, color: Color(0xFF10B981), size: 22),
                const SizedBox(width: 8),
                const Text(
                  "Career & Role",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildInfoItem("DESIGNATION", user?.designation ?? "N/A")),
                    Expanded(child: _buildInfoItem("DEPARTMENT", user?.department ?? "N/A")),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("OFFICIAL ROLE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF), // blue-50
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (user?.role ?? "TEAM MEMBER").toUpperCase(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF3B82F6), letterSpacing: -0.2), // blue-500
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("REPORTING TO", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.account_circle_outlined, size: 16, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  user?.manager ?? "No Manager Assigned",
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC), // slate-50
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("JOINING DATE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Text(
                            user?.joiningDate != null 
                                ? DateFormat("d MMMM yyyy").format(DateTime.tryParse(user!.joiningDate!) ?? DateTime.now())
                                : "1 January 1970",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard(UserModel? user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.access_time_filled, color: Color(0xFFEC4899), size: 22),
                const SizedBox(width: 8),
                const Text(
                  "Personal Info",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "FILTER BY",
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF475569), letterSpacing: 1.0),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildPersonalItem(
                  "Personal Email",
                  user?.personalEmail ?? "Not Provided",
                  dotColor: const Color(0xFF10B981),
                  badgeText: "VERIFIED",
                  badgeColor: const Color(0xFF34D399),
                ),
                const SizedBox(height: 20),
                _buildPersonalItem(
                  "Birthday & Gender",
                  "${user?.dateOfBirth != null ? DateFormat('dd/MM/yyyy').format(DateTime.tryParse(user!.dateOfBirth!) ?? DateTime.now()) : 'Unknown'} ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ ${user?.gender ?? 'Unknown'}",
                  dotColor: const Color(0xFFEC4899),
                  badgeText: "PRIVATE",
                  badgeColor: const Color(0xFFEC4899),
                ),
                const SizedBox(height: 20),
                _buildPersonalItem(
                  "Current Location",
                  [user?.city, user?.state, user?.nationality].where((e) => e != null && e.isNotEmpty).join(", ").isEmpty 
                      ? "Not Provided" 
                      : [user?.city, user?.state, user?.nationality].where((e) => e != null && e.isNotEmpty).join(", "),
                  dotColor: const Color(0xFF10B981),
                  badgeText: "PUBLIC",
                  badgeColor: const Color(0xFF34D399),
                ),
                const SizedBox(height: 20),
                _buildPersonalItem(
                  "Marital Status",
                  user?.maritalStatus ?? "Not Provided",
                  dotColor: const Color(0xFF10B981),
                  badgeText: "ACTIVE",
                  badgeColor: const Color(0xFF34D399),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalItem(String title, String subtitle, {required Color dotColor, required String badgeText, required Color badgeColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  boxShadow: [
                    BoxShadow(color: dotColor.withOpacity(0.4), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: badgeColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            badgeText,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}
