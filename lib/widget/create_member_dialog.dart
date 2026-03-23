import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../provider/auth_provider.dart';
import '../../provider/user_provider.dart';
import '../../model/user_model.dart';
import '../../services/auth_service.dart';

class CreateMemberDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const CreateMemberDialog({Key? key, required this.onSuccess}) : super(key: key);

  @override
  State<CreateMemberDialog> createState() => _CreateMemberDialogState();
}

class _CreateMemberDialogState extends State<CreateMemberDialog> {
  final TextEditingController _fNameCtrl = TextEditingController();
  final TextEditingController _lNameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _desigCtrl = TextEditingController();
  final TextEditingController _deptCtrl = TextEditingController();
  final TextEditingController _customRoleCtrl = TextEditingController();

  String _selectedRole = "TEAM MEMBER";
  String _selectedManagerId = "";
  bool _taskAccess = true;
  bool _leaveAccess = true;
  bool _isLoading = false;

  List<dynamic> _roles = [];
  bool _isCustomRole = false;

  @override
  void initState() {
    super.initState();
    _fetchRoles();
  }

  Future<void> _fetchRoles() async {
    try {
      final roles = await AuthService().getRoles();
      final currentUser = context.read<AuthProvider>().currentUser;
      final isManager = currentUser?.role?.toUpperCase() == 'MANAGER';
      if (mounted) {
        setState(() {
          if (isManager) {
            _roles = roles.where((r) => r['name'].toString().toUpperCase() != 'ADMIN' && r['name'].toString().toUpperCase() != 'SUPERADMIN').toList();
          } else {
            _roles = roles;
          }
        });
      }
    } catch (e) {
      // Handle error gracefully silently or log
    }
  }

  Future<void> _submit() async {
    if (_fNameCtrl.text.isEmpty || _lNameCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
      _showSnackbar('Highlighted fields are required');
      return;
    }

    String finalRole = _isCustomRole ? _customRoleCtrl.text.trim() : _selectedRole;
    if (finalRole.isEmpty) {
      _showSnackbar('Role is required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // If custom role, create it first via API
      if (_isCustomRole && _customRoleCtrl.text.isNotEmpty) {
         try {
           final Map<String, dynamic> newRole = await AuthService().createRole({'name': finalRole});
           finalRole = newRole['name'] ?? finalRole;
         } catch(e) {
           // Might already exist, proceed
         }
      }

      // Add Member via AuthProvider
      final success = await context.read<AuthProvider>().register(
        firstName: _fNameCtrl.text.trim(),
        lastName: _lNameCtrl.text.trim(),
        workEmail: _emailCtrl.text.trim(),
        mobileNumber: _mobileCtrl.text.trim(),
        password: _passCtrl.text.trim().isNotEmpty ? _passCtrl.text.trim() : "Welcome@123",
        role: finalRole,
        designation: _desigCtrl.text.trim(),
        department: _deptCtrl.text.trim(),
      );

      // Warning: The flutter AuthProvider register doesn't officially send `reportingManagerId` or `taskAccess` inside its method call yet, so they are UI-only matching web for now unless API is updated.
      if (success) {
        if (mounted) {
          Navigator.pop(context);
          widget.onSuccess();
          _showSnackbar('Member added successfully', isSuccess: true);
        }
      } else {
        if (mounted) {
          final err = context.read<AuthProvider>().errorMessage ?? 'Failed to add member';
          _showSnackbar(err);
        }
      }
    } catch (e) {
      if (mounted) _showSnackbar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeBg = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white;
    final themeText = Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B);
    final users = context.read<UserProvider>().users;
    final currentUserInfo = context.read<AuthProvider>().currentUser;
    final bool canAddCustomRole = !(currentUserInfo?.role?.toUpperCase() == 'MANAGER');

    return Dialog(
      backgroundColor: themeBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF20E19F).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(LucideIcons.userPlus, color: Color(0xFF20E19F), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add New Team Member', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeText)),
                        const Text('Create a new user account', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context))
                ],
              ),
            ),
            
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildInput('First Name', _fNameCtrl, req: true, hint: "E.g. Aashish")),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInput('Last Name', _lNameCtrl, req: true, hint: "Yadav")),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInput('Work Email', _emailCtrl, req: true, hint: "example@company.com"),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildInput('Mobile Number', _mobileCtrl, hint: "+91 XXXXX XXXXX")),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInput('Password', _passCtrl, hint: "••••••••", helper: "Default: Welcome@123")),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Role
                    _buildLabel('Role'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _isCustomRole ? 'Custom' : (_roles.map((e)=>e['name'].toString()).contains(_selectedRole) || _roles.isEmpty ? _selectedRole : null),
                          hint: const Text("Select Role", style: TextStyle(fontSize: 13, color: Colors.grey)),
                          items: [
                            ..._roles.map((r) => DropdownMenuItem(value: r['name'].toString(), child: Text(r['name'].toString(), style: const TextStyle(fontSize: 13)))),
                            if (_roles.isEmpty) ...[
                              const DropdownMenuItem(value: 'TEAM MEMBER', child: Text('TEAM MEMBER', style: TextStyle(fontSize: 13))),
                              const DropdownMenuItem(value: 'MANAGER', child: Text('MANAGER', style: TextStyle(fontSize: 13))),
                              const DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN', style: TextStyle(fontSize: 13))),
                            ],
                            if (canAddCustomRole) const DropdownMenuItem(value: 'Custom', child: Text('Custom Role...', style: TextStyle(fontSize: 13, color: Color(0xFF20E19F), fontWeight: FontWeight.bold))),
                          ],
                          onChanged: (val) {
                            if (val == 'Custom') {
                              setState(() => _isCustomRole = true);
                            } else {
                              setState(() {
                                _isCustomRole = false;
                                _selectedRole = val ?? "TEAM MEMBER";
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    if (_isCustomRole) ...[
                      const SizedBox(height: 8),
                      _buildInput('Custom Role Name', _customRoleCtrl, hint: "E.g., Senior Designer"),
                    ],
                    const SizedBox(height: 16),

                    // Manager
                    _buildLabel('Reporting Manager'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedManagerId.isEmpty ? null : _selectedManagerId,
                          hint: const Text('Select Reporting Manager', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          items: users.map((u) => DropdownMenuItem(value: u.id, child: Text('${u.firstName} ${u.lastName} (${u.role})', style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) => setState(() => _selectedManagerId = val ?? ""),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Designation & Department
                    Row(
                      children: [
                        Expanded(child: _buildInput('Designation', _desigCtrl, hint: "e.g., Software Engineer")),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInput('Department', _deptCtrl, hint: "e.g., IT")),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Toggles
                    _buildToggleRow('Task Access', _taskAccess, (v) => setState(() => _taskAccess = v)),
                    const SizedBox(height: 16),
                    _buildToggleRow('Leave & Attendance Access', _leaveAccess, (v) => setState(() => _leaveAccess = v)),
                  ],
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade50, border: Border(top: BorderSide(color: Colors.grey.shade200)), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Discard', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF20E19F), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _isLoading 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Add Team Member', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {bool req = false, String hint = "", String helper = ""}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF20E19F))),
          ),
        ),
        if (helper.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(helper, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey));
  }

  Widget _buildToggleRow(String title, bool val, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
        Switch(
          value: val, 
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: const Color(0xFF20E19F),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey.shade300,
        )
      ],
    );
  }
}
