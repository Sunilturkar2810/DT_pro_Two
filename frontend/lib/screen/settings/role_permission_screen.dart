import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/roles_provider.dart';

class RolePermissionScreen extends StatefulWidget {
  const RolePermissionScreen({Key? key}) : super(key: key);

  @override
  State<RolePermissionScreen> createState() => _RolePermissionScreenState();
}

class _RolePermissionScreenState extends State<RolePermissionScreen> {
  final List<String> actions = ['Create', 'Edit', 'View', 'Delete', 'Import Task', 'Export Task'];

  @override
  void initState() {
    super.initState();
    // Load roles when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RolesProvider>().fetchAllRoles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "ROLE & PERMISSION",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2),
        ),
        backgroundColor: const Color(0xFF20E19F),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<RolesProvider>(
        builder: (context, rolesProvider, _) {
          if (rolesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (rolesProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error: ${rolesProvider.errorMessage}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      rolesProvider.fetchAllRoles();
                      rolesProvider.clearError();
                    },
                    child: const Text('Retry'),
                  )
                ],
              ),
            );
          }

          final defaultRoles = rolesProvider.getDefaultRoles();
          final customRoles = rolesProvider.getCustomRoles();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Default Roles Section
                  if (defaultRoles.isNotEmpty)
                    _buildRoleSection(context, 'Default Roles', defaultRoles, true, rolesProvider),
                  const SizedBox(height: 24),

                  // Custom Roles Section
                  if (customRoles.isNotEmpty)
                    _buildRoleSection(context, 'Custom Roles', customRoles, false, rolesProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleSection(BuildContext context, String title, List<Map<String, dynamic>> roles, bool isDefault, RolesProvider rolesProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
            ),
            if (!isDefault)
              ElevatedButton.icon(
                onPressed: () {
                  _showAddRoleDialog(context, rolesProvider);
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Role'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF20E19F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Permission tables for each role
        ...roles.map((roleData) {
          final roleId = roleData['id'] as String;
          final roleName = roleData['name'] as String;
          final permissions = roleData['permissions'] as Map<String, dynamic>? ?? {};

          return Column(
            children: [
              // Role name with delete button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    roleName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  if (!isDefault)
                    GestureDetector(
                      onTap: () => _showDeleteConfirmation(context, roleId, roleName, rolesProvider),
                      child: const Icon(Icons.delete, size: 18, color: Colors.red),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Permission table
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        color: const Color(0xFF20E19F),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text('Action', style: _headerStyle())),
                            Expanded(child: Center(child: Text('Allowed', style: _headerStyle()))),
                          ],
                        ),
                      ),

                      // Permission rows
                      ...actions.asMap().entries.map((entry) {
                        int index = entry.key;
                        String action = entry.value;
                        bool isLast = index == actions.length - 1;
                        
                        // Use action name directly as key (no conversion)
                        bool isChecked = permissions[action] as bool? ?? false;

                        return Container(
                          decoration: BoxDecoration(
                            border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  action,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () async {
                                      final newPermissions = {...permissions};
                                      // Use action name directly as key (no conversion)
                                      newPermissions[action] = !isChecked;
                                      
                                      await rolesProvider.updateRolePermissions(
                                        roleId: roleId,
                                        permissions: Map<String, bool>.from(newPermissions),
                                      );
                                      
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Permission updated'),
                                            backgroundColor: isChecked ? Colors.orange : const Color(0xFF20E19F),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isChecked ? const Color(0xFF20E19F) : Colors.transparent,
                                        border: Border.all(
                                          color: isChecked ? const Color(0xFF20E19F) : Colors.grey,
                                          width: 2,
                                        ),
                                      ),
                                      child: isChecked
                                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ],
    );
  }

  void _showAddRoleDialog(BuildContext context, RolesProvider rolesProvider) {
    final TextEditingController controller = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter role name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                hintText: 'Enter role description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                
                final success = await rolesProvider.createRole(
                  name: controller.text,
                  description: descriptionController.text,
                );
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Role added successfully' : 'Error adding role'),
                      backgroundColor: success ? const Color(0xFF20E19F) : Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF20E19F)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String roleId, String roleName, RolesProvider rolesProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Role'),
        content: Text('Are you sure you want to delete the role "$roleName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final success = await rolesProvider.deleteRole(roleId);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Role deleted' : 'Error deleting role'),
                    backgroundColor: success ? Colors.red : Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() => const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11);
}
