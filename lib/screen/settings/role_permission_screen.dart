import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/roles_provider.dart';

class RolePermissionScreen extends StatefulWidget {
  const RolePermissionScreen({Key? key}) : super(key: key);

  @override
  State<RolePermissionScreen> createState() => _RolePermissionScreenState();
}

class _RolePermissionScreenState extends State<RolePermissionScreen> {
  // Local state for edits
  bool _isEditing = false;
  Map<String, Map<String, dynamic>> _localPermissions = {};

  final List<Map<String, dynamic>> _modules = [
    {
      'title': 'Task Template',
      'key': 'taskTemplate',
      'actions': [
        {'name': 'Create', 'key': 'create', 'type': 'bool'},
        {'name': 'Edit', 'key': 'edit', 'type': 'bool'},
        {'name': 'View', 'key': 'view', 'type': 'bool'},
        {'name': 'Delete', 'key': 'delete', 'type': 'bool'},
      ]
    },
    {
      'title': 'Task',
      'key': 'task',
      'actions': [
        {'name': 'Create', 'key': 'create', 'type': 'bool'},
        {'name': 'Edit', 'key': 'edit', 'type': 'list', 'options': ['All', 'My Team + Assigned', 'Assigned', 'None']},
        {'name': 'Delete', 'key': 'delete', 'type': 'list', 'options': ['All', 'Assigned', 'None']},
        {'name': 'Import Task', 'key': 'importTask', 'type': 'bool'},
        {'name': 'Export Task', 'key': 'exportTask', 'type': 'list', 'options': ['All', 'My Team + Me', 'None']},
      ]
    },
    {
      'title': 'My Team',
      'key': 'myTeam',
      'actions': [
        {'name': 'Add', 'key': 'add', 'type': 'bool'},
        {'name': 'Edit', 'key': 'edit', 'type': 'list', 'options': ['All', 'My Team', 'None']},
        {'name': 'Delete', 'key': 'delete', 'type': 'list', 'options': ['All', 'None']},
        {'name': 'View', 'key': 'view', 'type': 'list', 'options': ['All', 'None']},
      ]
    },
    {
      'title': 'Holidays',
      'key': 'holidays',
      'actions': [
        {'name': 'Create', 'key': 'create', 'type': 'bool'},
        {'name': 'Edit', 'key': 'edit', 'type': 'bool'},
        {'name': 'View', 'key': 'view', 'type': 'bool'},
        {'name': 'Delete', 'key': 'delete', 'type': 'bool'},
      ]
    },
    {
      'title': 'Groups',
      'key': 'groups',
      'actions': [
        {'name': 'Create', 'key': 'create', 'type': 'bool'},
        {'name': 'Edit', 'key': 'edit', 'type': 'bool'},
        {'name': 'View', 'key': 'view', 'type': 'bool'},
        {'name': 'Delete', 'key': 'delete', 'type': 'bool'},
      ]
    },
    {
      'title': 'Activity',
      'key': 'activity',
      'actions': [
        {'name': 'View History', 'key': 'view', 'type': 'bool'},
      ]
    },
    {
      'title': 'Idea Board',
      'key': 'ideaBoard',
      'actions': [
        {'name': 'View Board', 'key': 'view', 'type': 'bool'},
      ]
    },
    {
      'title': 'Task Directory',
      'key': 'taskDirectory',
      'actions': [
        {'name': 'View Directory', 'key': 'view', 'type': 'bool'},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RolesProvider>().fetchAllRoles();
    });
  }

  void _initLocalPermissions(List<Map<String, dynamic>> roles) {
    if (!_isEditing) {
      _localPermissions.clear();
      for (var role in roles) {
        String roleId = role['id'].toString();
        // create deep copy
        _localPermissions[roleId] = jsonDecode(jsonEncode(role['permissions'] ?? {}));
      }
    }
  }

  Future<void> _saveAllChanges(RolesProvider provider) async {
    bool overallSuccess = true;
    for (String roleId in _localPermissions.keys) {
      bool success = await provider.updateRolePermissions(
        roleId: roleId,
        permissions: _localPermissions[roleId]!,
      );
      if (!success) overallSuccess = false;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(overallSuccess ? 'Permissions saved successfully!' : 'Some saves failed. Retrying...'),
          backgroundColor: overallSuccess ? const Color(0xFF20E19F) : Colors.red,
        ),
      );
      if (overallSuccess) {
        setState(() {
          _isEditing = false;
        });
        provider.fetchAllRoles(); // refresh from db
      }
    }
  }

  void _resetChanges(RolesProvider provider) {
    setState(() {
      _isEditing = false;
      _localPermissions.clear();
    });
    // This will force re-initialization of local permissions from existing provider roles
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
        builder: (context, provider, _) {
          if (provider.isLoading && !_isEditing) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && !_isEditing) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error: ${provider.errorMessage}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.fetchAllRoles();
                      provider.clearError();
                    },
                    child: const Text('Retry'),
                  )
                ],
              ),
            );
          }

          final roles = provider.roles;
          if (roles.isEmpty) return const Center(child: Text("No Roles Available"));

          _initLocalPermissions(roles);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _resetChanges(provider),
                        icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                        label: const Text('Reset', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _saveAllChanges(provider),
                        icon: const Icon(Icons.save, size: 16, color: Colors.white),
                        label: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showAddRoleDialog(context, provider),
                        icon: const Icon(Icons.add, size: 16, color: Colors.white),
                        label: const Text('Add Role', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF20E19F),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Matrix view
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _modules.map((module) {
                          return _buildModuleSection(module, roles, provider);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModuleSection(Map<String, dynamic> module, List<Map<String, dynamic>> roles, RolesProvider provider) {
    final String moduleKey = module['key'];
    final String moduleTitle = module['title'];
    final List<Map<String, dynamic>> actions = List<Map<String, dynamic>>.from(module['actions']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF20E19F),
          ),
          child: Row(
            children: [
              SizedBox(width: 150, child: Text(moduleTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white))),
              ...roles.map((role) {
                return SizedBox(
                  width: 140,
                  child: Center(
                    child: Text(
                      role['name'].toString().toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        
        // Action Rows
        ...actions.asMap().entries.map((entry) {
          int idx = entry.key;
          var action = entry.value;
          bool isLast = idx == actions.length - 1;
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
              color: Colors.white,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 150, 
                  child: Text(
                    action['name'], 
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))
                  )
                ),
                
                ...roles.map((role) {
                  return SizedBox(
                    width: 140,
                    child: Center(
                      child: _buildCellContent(role['id'].toString(), moduleKey, action),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCellContent(String roleId, String moduleKey, Map<String, dynamic> action) {
    String actionKey = action['key'];
    String type = action['type'];
    
    // Read from local state instead of provider directly
    Map<String, dynamic> perms = _localPermissions[roleId] ?? {};
    Map<String, dynamic> modulePerms = perms[moduleKey] != null 
        ? Map<String, dynamic>.from(perms[moduleKey]) 
        : {};
        
    dynamic currentValue = modulePerms[actionKey];

    if (type == 'bool') {
      bool val = currentValue is bool ? currentValue : (currentValue == 'true' || currentValue == true);
      return GestureDetector(
        onTap: () {
          setState(() {
            _isEditing = true;
            modulePerms[actionKey] = !val;
            perms[moduleKey] = modulePerms;
            _localPermissions[roleId] = perms;
          });
        },
        child: Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(4),
            color: val ? const Color(0xFF20E19F) : Colors.transparent,
            border: Border.all(color: val ? const Color(0xFF20E19F) : Colors.grey.shade300, width: 1.5),
          ),
          child: val ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
        ),
      );
    } else if (type == 'list') {
      List<String> options = List<String>.from(action['options']);
      String val = currentValue is String && options.contains(currentValue) ? currentValue : options.last;
      
      return Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FD),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: val,
            isDense: true,
            icon: const Icon(Icons.arrow_drop_down, size: 16),
            style: const TextStyle(fontSize: 10, color: Color(0xFF334155), fontWeight: FontWeight.w500),
            items: options.map((opt) {
              return DropdownMenuItem(value: opt, child: Text(opt));
            }).toList(),
            onChanged: (newVal) {
              if (newVal != null && newVal != val) {
                setState(() {
                  _isEditing = true;
                  modulePerms[actionKey] = newVal;
                  perms[moduleKey] = modulePerms;
                  _localPermissions[roleId] = perms;
                });
              }
            },
          ),
        ),
      );
    }
    
    return const SizedBox();
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
              decoration: const InputDecoration(hintText: 'Enter role name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(hintText: 'Enter role description (optional)', border: OutlineInputBorder()),
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
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
