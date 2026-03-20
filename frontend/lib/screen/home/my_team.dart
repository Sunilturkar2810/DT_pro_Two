import 'package:d_table_delegate_system/model/user_model.dart';
import 'package:d_table_delegate_system/provider/auth_provider.dart';
import 'package:d_table_delegate_system/provider/theme_provider.dart';
import 'package:d_table_delegate_system/provider/user_provider.dart';
import 'package:d_table_delegate_system/screen/auth/signup/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
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
        title: Text(
          "My Team",
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.w900, // Fixed FontWeight.black error
            fontSize: 18,
          ),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF12161B) : Colors.white,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProv, child) {
          if (userProv.isLoading) {
            return Center(child: CircularProgressIndicator(color: _primaryGreen));
          }

          final allMembers = userProv.users;
          
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
          _actionButton(LucideIcons.plus, "Create Team", _primaryGreen),
          const SizedBox(width: 8),
          _actionButton(LucideIcons.userPlus, "Add Member", _primaryGreen, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
          }),
          const SizedBox(width: 12),
          _buildDropdown(roles, _selectedRole, (v) => setState(() => _selectedRole = v!), isDark, "Role"),
          const SizedBox(width: 8),
          _buildDropdown(managers, _selectedManager, (v) => setState(() => _selectedManager = v!), isDark, "Manager"),
          const SizedBox(width: 8),
          _buildSearchField(isDark),
          const SizedBox(width: 8),
          _buildDropdown(["All", "Task App", "Leave App"], _selectedAccess, (v) => setState(() => _selectedAccess = v!), isDark, "Access"),
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

  Widget _buildDropdown(List<String> items, String current, Function(String?) onChanged, bool isDark, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? slate800 : slate200), // Fixed slate error
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(current) ? current : items.first,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87)))).toList(),
          onChanged: onChanged,
          icon: const Icon(LucideIcons.chevronDown, size: 14),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _statBadge("$count Members", const Color(0xFFB4F5E1), const Color(0xFF2C7A63), isDark),
          const SizedBox(width: 8),
          _statBadge("$count/$count Task App", const Color(0xFFCFEAFF), const Color(0xFF2B6FB5), isDark),
        ],
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? slate800 : slate100), // Fixed slate error
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  color: _primaryGreen,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  children: [
                    _th("Select", 60),
                    _th("User", 250),
                    _th("Mobile", 120),
                    _th("Reports To", 150),
                    _th("Role", 100),
                    _th("Actions", 80, align: TextAlign.center),
                  ],
                ),
              ),
              // Body
              if (members.isEmpty)
                Container(padding: const EdgeInsets.all(40), child: const Text("No members found"))
              else
                ...members.map((m) => _buildRow(m, isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _th(String label, double width, {TextAlign align = TextAlign.left}) {
    return SizedBox(
      width: width,
      child: Text(label, textAlign: align, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildRow(UserModel m, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? slate800 : slate50)), // Fixed slate error
      ),
      child: Row(
        children: [
          SizedBox(width: 60, child: Checkbox(value: false, onChanged: (v) {}, activeColor: _primaryGreen)),
          SizedBox(
            width: 250,
            child: Row(
              children: [
                _avatar(m),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.fullName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                      Text(m.workEmail, style: TextStyle(fontSize: 11, color: slate400)), // Fixed slate error
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 120, child: Text(m.mobileNumber ?? "N/A", style: const TextStyle(fontSize: 13))),
          SizedBox(width: 150, child: Text(m.manager ?? "N/A", style: const TextStyle(fontSize: 13))),
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(m.role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(m.role, style: TextStyle(color: _getRoleColor(m.role), fontWeight: FontWeight.bold, fontSize: 10), textAlign: TextAlign.center),
            ),
          ),
          SizedBox(
            width: 80,
            child: IconButton(
              icon: Icon(LucideIcons.moreVertical, size: 18, color: slate400), // Fixed slate error
              onPressed: () {},
            ),
          ),
        ],
      ),
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
