import 'package:d_table_delegate_system/model/user_model.dart';
import 'package:d_table_delegate_system/provider/auth_provider.dart';
import 'package:d_table_delegate_system/provider/theme_provider.dart';
import 'package:d_table_delegate_system/provider/user_provider.dart';
import 'package:d_table_delegate_system/screen/auth/signup/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../widget/app_dropdown.dart';
import '../../widget/create_team_dialog.dart';
import '../../widget/create_member_dialog.dart';
import '../../widget/team_action_dialogs.dart';
import 'add_user_screen.dart';
import '../../services/team_service.dart';

class MyTeamScreen extends StatefulWidget {
  const MyTeamScreen({super.key});

  @override
  _MyTeamScreenState createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends State<MyTeamScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedRole = "All";
  String _selectedManager = "All";
  String _selectedAccess = "All";

  final Color _primaryGreen = const Color(0xFF00D094);

  // Custom Slate Colors (Replacement for Colors.slate which is not standard)
  final Color slate50 = const Color(0xFFF8FAFC);
  final Color slate100 = const Color(0xFFF1F5F9);
  final Color slate200 = const Color(0xFFE2E8F0);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color slate600 = const Color(0xFF475569);
  final Color slate800 = const Color(0xFF1E293B);

  List<UserModel> _teamMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeamMembers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
  }

  Future<void> _fetchTeamMembers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await TeamService().getMyTeamMembers();
      if (mounted) {
        setState(() {
          _teamMembers = data.map((e) => UserModel.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12161B) : Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF20E19F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "MY TEAM",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (_isLoading) {
            return Center(child: CircularProgressIndicator(color: _primaryGreen));
          }

          final allMembers = _teamMembers;
          
          // Filters logic
          final filteredMembers = allMembers.where((u) {
            final q = _searchCtrl.text.toLowerCase();
            final matchesSearch = q.isEmpty ||
                u.fullName.toLowerCase().contains(q) ||
                u.workEmail.toLowerCase().contains(q);
            
            final matchesRole = _selectedRole == "All" || u.role == _selectedRole;
            final matchesManager = _selectedManager == "All" || (u.manager != null && u.manager == _selectedManager);
            
            return matchesSearch && matchesRole && matchesManager;
          }).toList();

          final uniqueRoles = ["All", ...allMembers.map((m) => m.role).toSet().toList()];
          final uniqueManagers = ["All", ...allMembers.map((m) => m.manager).whereType<String>().toSet().toList()];

          return Column(
            children: [
              _buildFilterBar(uniqueRoles, uniqueManagers, isDark),
              _buildStats(allMembers.length, isDark),
              Expanded(
                child: _buildTable(filteredMembers, isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(List<String> roles, List<String> managers, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _actionButton(
            LucideIcons.plus, 
            "Create New Team", 
            _primaryGreen,
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => CreateTeamDialog(
                  onSuccess: () {
                    context.read<UserProvider>().fetchUsers();
                    _fetchTeamMembers();
                  },
                ),
              );
            }
          ),
          const SizedBox(width: 8),
          _actionButton(LucideIcons.userPlus, "Add Member", _primaryGreen, onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => CreateMemberDialog(
                onSuccess: () {
                  context.read<UserProvider>().fetchUsers();
                  _fetchTeamMembers();
                },
              ),
            );
           }),
          const SizedBox(width: 8),
          _actionButton(
            LucideIcons.upload, 
            "Upload User", 
            _primaryGreen,
            onTap: () async {
              final refresh = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddUserScreen()));
              if (refresh == true) {
                _fetchTeamMembers();
              }
            }
          ),
          const SizedBox(width: 12),
          _buildDropdown(roles, _selectedRole, (v) => setState(() => _selectedRole = v!), isDark, "All"),
          const SizedBox(width: 8),
          _buildDropdown(managers, _selectedManager, (v) => setState(() => _selectedManager = v!), isDark, "Reporting Manager"),
          const SizedBox(width: 8),
          _buildSearchField(isDark),
          const SizedBox(width: 8),
          _buildDropdown(["All", "Task App", "Leave App"], _selectedAccess, (v) => setState(() => _selectedAccess = v!), isDark, "Access Type"),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap ?? () {},
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String current, Function(String?) onChanged, bool isDark, String customLabel) {
    return AppDropdown<String>(
      isCompact: true,
      value: items.contains(current) ? current : items.first,
      items: items,
      labelBuilder: (v) => v == 'All' ? customLabel : v,
      onChanged: onChanged,
    );
  }

  Widget _buildSearchField(bool isDark) {
    return Container(
      width: 200,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? slate800 : slate200), // Fixed slate error
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() {}),
        style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: "Search Team Member",
          hintStyle: TextStyle(color: slate400, fontSize: 12), // Fixed slate error
          prefixIcon: Icon(LucideIcons.search, size: 16, color: slate400), // Fixed slate error
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildStats(int count, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 16), // Padding for scroll feel
            _statBadge("$count Members", const Color(0xFFB4F5E1), const Color(0xFF2C7A63), isDark),
            const SizedBox(width: 8),
            _statBadge("$count/$count Task App", const Color(0xFFCFEAFF), const Color(0xFF2B6FB5), isDark),
            const SizedBox(width: 8),
            _statBadge("0/0 Leave & Attendance App", const Color(0xFFCFEAFF), const Color(0xFF2B6FB5), isDark),
            const SizedBox(width: 16), // Padding for scroll feel
          ],
        ),
      ),
    );
  }

  Widget _statBadge(String text, Color bg, Color textCol, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? textCol.withOpacity(0.1) : bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? textCol.withOpacity(0.3) : bg.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(color: textCol, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildTable(List<UserModel> members, bool isDark) {
    if (members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.users, size: 48, color: slate400.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                "No team members match your filters.", 
                style: TextStyle(color: slate600, fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: members.length,
      itemBuilder: (context, index) {
        return _buildListCard(members[index], isDark);
      },
    );
  }

  Widget _buildListCard(UserModel m, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? slate800 : slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Checkbox, Avatar, Name, Email, Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: false, 
                  onChanged: (v) {}, 
                  activeColor: _primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                )
              ),
              const SizedBox(width: 12),
              _avatar(m),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 2),
                    Text(m.workEmail, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: slate400)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: PopupMenuButton<String>(
                  icon: Icon(LucideIcons.moreVertical, size: 20, color: slate400),
                  padding: EdgeInsets.zero,
                  position: PopupMenuPosition.under,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  elevation: 8,
                  offset: const Offset(0, 4),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      height: 40,
                      child: Text('Edit', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    PopupMenuItem(
                      value: 'update_cred',
                      height: 40,
                      child: Text('Update Credentials', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    const PopupMenuDivider(height: 1),
                    const PopupMenuItem(
                      value: 'delete_tasks',
                      height: 40,
                      child: Text('Delete All Tasks', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const PopupMenuItem(
                      value: 'delete_user',
                      height: 40,
                      child: Text('DELETE USER', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                    ),
                  ],
                  onSelected: (val) {
                    if (val == 'edit') {
                      showDialog(context: context, builder: (_) => UpdateMemberDialog(member: m, onSuccess: () {
                        context.read<UserProvider>().fetchUsers();
                        _fetchTeamMembers();
                      }));
                    } else if (val == 'update_cred') {
                      showDialog(context: context, builder: (_) => UpdateCredentialsDialog(member: m, onSuccess: () {
                        context.read<UserProvider>().fetchUsers();
                        _fetchTeamMembers();
                      }));
                    } else if (val == 'delete_tasks') {
                      showDialog(context: context, builder: (_) => DeleteTasksDialog(member: m, onSuccess: () {
                        context.read<UserProvider>().fetchUsers();
                        _fetchTeamMembers();
                      }));
                    } else if (val == 'delete_user') {
                      showDialog(context: context, builder: (_) => DeleteUserDialog(member: m, onSuccess: () {
                        context.read<UserProvider>().fetchUsers();
                        _fetchTeamMembers();
                      }));
                    }
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          Divider(color: isDark ? slate800 : slate100, height: 1),
          const SizedBox(height: 16),
          
          // Row 2: Grid of info
          Row(
            children: [
              Expanded(child: _infoBlock("Mobile", m.mobileNumber ?? "N/A", LucideIcons.phone, isDark)),
              Expanded(child: _infoBlock("Reports To", m.manager ?? "N/A", LucideIcons.userCheck, isDark)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _infoBlock("Team Name", "N/A", LucideIcons.users, isDark)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.shield, size: 14, color: slate400),
                        const SizedBox(width: 4),
                        Text("Role", style: TextStyle(fontSize: 11, color: slate400, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRoleColor(m.role).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(m.role, style: TextStyle(color: _getRoleColor(m.role), fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBlock(String label, String value, IconData icon, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: slate400),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: slate400, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B))),
      ],
    );
  }

  Widget _avatar(UserModel m) {
    final initials = (m.firstName.isNotEmpty ? m.firstName[0] : "") + (m.lastName.isNotEmpty ? m.lastName[0] : "");
    return CircleAvatar(
      radius: 18,
      backgroundColor: _getRoleColor(m.role),
      child: Text(initials.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN': return const Color(0xFFEC4899);
      case 'MANAGER': return const Color(0xFF38BDF8);
      default: return const Color(0xFFFB923C);
    }
  }
}
