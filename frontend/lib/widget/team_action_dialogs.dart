import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/user_model.dart';
import '../../services/auth_service.dart';
import '../../provider/auth_provider.dart';
import '../../provider/user_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

void showSnackbar(BuildContext context, String msg, {bool isSuccess = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: isSuccess ? Colors.green : Colors.red,
    )
  );
}

// -------------------------------------------------------------
// UPDATE CREDENTIALS DIALOG
// -------------------------------------------------------------
class UpdateCredentialsDialog extends StatefulWidget {
  final UserModel member;
  final VoidCallback onSuccess;
  const UpdateCredentialsDialog({Key? key, required this.member, required this.onSuccess}) : super(key: key);

  @override
  State<UpdateCredentialsDialog> createState() => _UpdateCredentialsDialogState();
}

class _UpdateCredentialsDialogState extends State<UpdateCredentialsDialog> {
  late TextEditingController _emailCtrl;
  final TextEditingController _passCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.member.workEmail);
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      await AuthService().updateCredentials(widget.member.id, {
        'newEmail': _emailCtrl.text.trim(),
        'newPassword': _passCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        showSnackbar(context, "Credentials updated successfully", isSuccess: true);
      }
    } catch (e) {
      if (mounted) showSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Update Credentials", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: "New Work Email")),
          const SizedBox(height: 12),
          TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: "New Password", hintText: "Leave blank to keep current")),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF20E19F)),
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Update", style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}

// -------------------------------------------------------------
// DELETE TASKS DIALOG
// -------------------------------------------------------------
class DeleteTasksDialog extends StatefulWidget {
  final UserModel member;
  final VoidCallback onSuccess;
  const DeleteTasksDialog({Key? key, required this.member, required this.onSuccess}) : super(key: key);

  @override
  State<DeleteTasksDialog> createState() => _DeleteTasksDialogState();
}

class _DeleteTasksDialogState extends State<DeleteTasksDialog> {
  final TextEditingController _emailCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty) {
      showSnackbar(context, "Please enter your email to confirm");
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService().deleteUserTasks(widget.member.id, _emailCtrl.text.trim());
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        showSnackbar(context, "All tasks deleted successfully", isSuccess: true);
      }
    } catch (e) {
      if (mounted) showSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Delete All Tasks", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("This action will permanently delete all tasks associated with ${widget.member.fullName}.", style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: "Confirm your email pattern", hintText: "Enter your admin email")),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Delete All Tasks", style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}

// -------------------------------------------------------------
// DELETE USER DIALOG
// -------------------------------------------------------------
class DeleteUserDialog extends StatefulWidget {
  final UserModel member;
  final VoidCallback onSuccess;
  const DeleteUserDialog({Key? key, required this.member, required this.onSuccess}) : super(key: key);

  @override
  State<DeleteUserDialog> createState() => _DeleteUserDialogState();
}

class _DeleteUserDialogState extends State<DeleteUserDialog> {
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final success = await context.read<AuthProvider>().deleteUser(widget.member.id);
      if (success) {
        if (mounted) {
          Navigator.pop(context);
          widget.onSuccess();
          showSnackbar(context, "User deleted successfully", isSuccess: true);
        }
      } else {
         if (mounted) showSnackbar(context, context.read<AuthProvider>().errorMessage ?? "Failed to delete user");
      }
    } catch (e) {
      if (mounted) showSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("DELETE USER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.red, fontStyle: FontStyle.italic)),
      content: Text("Are you sure you want to permanently delete ${widget.member.fullName}? This action cannot be undone.", style: const TextStyle(fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("DELETE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }
}

// -------------------------------------------------------------
// UPDATE MEMBER DIALOG (Simplified Version of CreateMemberDialog)
// -------------------------------------------------------------
class UpdateMemberDialog extends StatefulWidget {
  final UserModel member;
  final VoidCallback onSuccess;
  const UpdateMemberDialog({Key? key, required this.member, required this.onSuccess}) : super(key: key);

  @override
  State<UpdateMemberDialog> createState() => _UpdateMemberDialogState();
}

class _UpdateMemberDialogState extends State<UpdateMemberDialog> {
  late TextEditingController _fNameCtrl;
  late TextEditingController _lNameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _desigCtrl;
  late TextEditingController _deptCtrl;

  late String _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fNameCtrl = TextEditingController(text: widget.member.firstName);
    _lNameCtrl = TextEditingController(text: widget.member.lastName);
    _mobileCtrl = TextEditingController(text: widget.member.mobileNumber);
    _desigCtrl = TextEditingController(text: widget.member.designation);
    _deptCtrl = TextEditingController(text: widget.member.department);
    _selectedRole = widget.member.role.isNotEmpty ? widget.member.role : "TEAM MEMBER";
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final success = await context.read<AuthProvider>().updateTeamMemberDetails(widget.member.id, {
        "firstName": _fNameCtrl.text,
        "lastName": _lNameCtrl.text,
        "mobileNumber": _mobileCtrl.text,
        "role": _selectedRole,
        "designation": _desigCtrl.text,
        "department": _deptCtrl.text,
      });
      if (success) {
        if (mounted) {
          Navigator.pop(context);
          widget.onSuccess();
          showSnackbar(context, "Member updated successfully", isSuccess: true);
        }
      } else {
        if (mounted) showSnackbar(context, "Update failed");
      }
    } catch (e) {
      if (mounted) showSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Member", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _fNameCtrl, decoration: const InputDecoration(labelText: "First Name")),
            const SizedBox(height: 12),
            TextField(controller: _lNameCtrl, decoration: const InputDecoration(labelText: "Last Name")),
            const SizedBox(height: 12),
            TextField(controller: _mobileCtrl, decoration: const InputDecoration(labelText: "Mobile Number")),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: ['TEAM MEMBER', 'MANAGER', 'ADMIN', 'SUPERADMIN']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRole = v!),
              decoration: const InputDecoration(labelText: "Role"),
            ),
            const SizedBox(height: 12),
            TextField(controller: _desigCtrl, decoration: const InputDecoration(labelText: "Designation")),
            const SizedBox(height: 12),
            TextField(controller: _deptCtrl, decoration: const InputDecoration(labelText: "Department")),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF20E19F)),
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Save Changes", style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}
