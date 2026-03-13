import 'package:d_table_delegate_system/model/delegate_model.dart';
import 'package:d_table_delegate_system/model/user_model.dart';
import 'package:d_table_delegate_system/provider/auth_provider.dart';
import 'package:d_table_delegate_system/provider/delegation_provider.dart';
import 'package:d_table_delegate_system/provider/theme_provider.dart';
import 'package:d_table_delegate_system/provider/user_provider.dart';
import 'package:d_table_delegate_system/widget/app_dropdown.dart';
import 'package:d_table_delegate_system/screen/auth/signup/signup_screen.dart';
import 'package:d_table_delegate_system/screen/home/edit_team_member.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyTeamScreen extends StatefulWidget {
  @override
  _MyTeamScreenState createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends State<MyTeamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  // States for Dropdowns
  String _selectedRole = "All";
  String _selectedManager = "Reporting Manager";
  String _selectedAccess = "Access Type";

  final Color _green = ThemeProvider.primaryGreen;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<UserProvider>();
      prov.fetchMyTeam();
      prov.clearSelectedMember();
      prov.fetchUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onMemberTap(UserModel member) {
    context.read<UserProvider>().fetchMemberProfile(member);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: MemberDetailPanel(
          member: member,
          onClose: () => Navigator.pop(ctx),
          tabController: _tabController,
          green: _green,
          appColors: Theme.of(context).extension<AppColors>()!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "My Team",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        backgroundColor: isDark ? appColors.toolbarBackground : Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProv, child) {
          if (userProv.isLoading) {
            return Center(child: CircularProgressIndicator(color: _green));
          }

          // Apply filters
          final team = userProv.users.where((u) {
            final q = _searchCtrl.text.toLowerCase();
            final matchesSearch =
                q.isEmpty ||
                u.fullName.toLowerCase().contains(q) ||
                u.workEmail.toLowerCase().contains(q) ||
                u.role.toLowerCase().contains(q);

            final matchesRole =
                _selectedRole == "All" ||
                u.role.toLowerCase() == _selectedRole.toLowerCase();

            return matchesSearch && matchesRole;
          }).toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopToolbar(appColors),
                _buildBadges(team.length),
                _buildTable(team, appColors, isDark),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopToolbar(AppColors ac) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Add Member Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignupScreen()),
              ).then((_) {
                // Refresh team after adding member
                context.read<UserProvider>().fetchMyTeam();
                context.read<UserProvider>().fetchUsers();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              elevation: 0,
            ),
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
              size: 16,
              color: Colors.white,
            ),
            label: const Text(
              "Add Member",
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Upload User Button
          ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              elevation: 0,
            ),
            icon: const Icon(
              Icons.upload_rounded,
              size: 16,
              color: Colors.white,
            ),
            label: const Text(
              "Upload User",
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Dropdowns
          _buildDropdownHeader(
            ac,
            ["All", "Admin", "Manager", "Team Member"],
            _selectedRole,
            (v) => setState(() => _selectedRole = v!),
            isDark,
          ),
          const SizedBox(width: 8),
          _buildDropdownHeader(
            ac,
            ["Reporting Manager"],
            _selectedManager,
            (v) => setState(() => _selectedManager = v!),
            isDark,
          ),
          const SizedBox(width: 8),
          // Search
          Container(
            height: 48,
            width: 220,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              color: isDark ? ac.inputBackground : Colors.white,
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Search Team Member",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                suffixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
                suffixIconConstraints: const BoxConstraints(minWidth: 30),
              ),
              style: TextStyle(fontSize: 13, color: ac.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          _buildDropdownHeader(
            ac,
            ["Access Type"],
            _selectedAccess,
            (v) => setState(() => _selectedAccess = v!),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownHeader(
    AppColors ac,
    List<String> items,
    String currentVal,
    Function(String?) onChanged,
    bool isDark,
  ) {
    if (!items.contains(currentVal)) items = [currentVal, ...items];
    return Container(
      height: 48,
      alignment: Alignment.center,
      child: AppDropdown<String>(
        isCompact: true,
        value: currentVal,
        items: items,
        labelBuilder: (v) => v,
        accentColor: _green,
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  Widget _buildBadges(int memberCount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          _badge(
            "$memberCount",
            "Members",
            const Color(0xFFE0F7FA),
            Colors.teal.shade700,
          ),
          _badge(
            "$memberCount/0",
            "Task App",
            const Color(0xFFE3F2FD),
            Colors.blue.shade700,
          ),
          _badge(
            "$memberCount/0",
            "Leave & Attendance App",
            const Color(0xFFE3F2FD),
            Colors.blue.shade700,
          ),
        ],
      ),
    );
  }

  Widget _badge(String countText, String labelText, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            countText,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            labelText,
            style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  TextStyle _thStyle() => const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 13,
  );

  Widget _buildTable(List<UserModel> team, AppColors ac, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: isDark ? ac.cardBackground : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(7),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        "Select",
                        style: _thStyle(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: Text("User", style: _thStyle()),
                    ),
                    SizedBox(
                      width: 150,
                      child: Text("Mobile", style: _thStyle()),
                    ),
                    SizedBox(
                      width: 200,
                      child: Text("Reports To", style: _thStyle()),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text("Role", style: _thStyle()),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        "Actions",
                        style: _thStyle(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              // Rows
              if (team.isEmpty)
                Container(
                  width: MediaQuery.of(context).size.width - 32,
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  child: Text(
                    "No team members found",
                    style: TextStyle(color: ac.textMuted, fontSize: 15),
                  ),
                )
              else
                ...team
                    .map((user) => _buildTableRow(user, ac, isDark))
                    .toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(UserModel user, AppColors ac, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Checkbox(
              value: false,
              onChanged: (v) {},
              activeColor: _green,
            ),
          ),
          SizedBox(
            width: 300,
            child: InkWell(
              onTap: () => _onMemberTap(user),
              child: Row(
                children: [
                  _avatar(user),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.fullName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ac.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified,
                              color: ThemeProvider.primaryGreen,
                              size: 14,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.workEmail,
                          style: TextStyle(fontSize: 12, color: ac.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              user.mobileNumber ?? "NA",
              style: TextStyle(fontSize: 13, color: ac.textSecondary),
            ),
          ),
          SizedBox(
            width: 200,
            child: Text(
              user.manager ?? "NA",
              style: TextStyle(fontSize: 13, color: ac.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 120,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _roleColor(user.role).withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: UnconstrainedBox(
                alignment: Alignment.centerLeft,
                child: Text(
                  user.role,
                  style: TextStyle(
                    fontSize: 11,
                    color: _roleColor(user.role),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: Colors.grey,
              ),
              onSelected: (value) {
                if (value == 'Profile') {
                  _onMemberTap(user);
                } else if (value == 'Edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditTeamMemberScreen(member: user),
                    ),
                  ).then((_) {
                    // Refresh team data after editing
                    context.read<UserProvider>().fetchMyTeam();
                  });
                }
                // Add your other actions here
              },
              itemBuilder: (BuildContext context) {
                final isAdmin = context.read<AuthProvider>().isAdmin;
                final items = [
                  const PopupMenuItem(
                    value: 'Profile',
                    child: Text('View Profile', style: TextStyle(fontSize: 13)),
                  ),
                ];
                
                if (isAdmin) {
                  items.addAll([
                    const PopupMenuItem(
                      value: 'Edit',
                      child: Text('Edit', style: TextStyle(fontSize: 13)),
                    ),
                    const PopupMenuItem(
                      value: 'Reassign',
                      child: Text(
                        'Reassign All Tasks',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'Credentials',
                      child: Text(
                        'Update Credentials',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'DeleteTasks',
                      child: Text(
                        'Delete All Tasks',
                        style: TextStyle(fontSize: 13, color: Colors.red),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'DeleteUser',
                      child: Text(
                        'Delete User',
                        style: TextStyle(fontSize: 13, color: Colors.red),
                      ),
                    ),
                  ]);
                }
                
                return items;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(UserModel user) {
    final initials = user.firstName.isNotEmpty
        ? user.firstName[0].toUpperCase() +
              (user.lastName.isNotEmpty ? user.lastName[0].toUpperCase() : '')
        : '?';
    return CircleAvatar(
      radius: 18,
      backgroundColor: _roleColor(user.role).withOpacity(0.15),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: _roleColor(user.role),
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.green;
      case 'manager':
        return Colors.blue;
      default:
        return Colors.deepOrange;
    }
  }
}

// ─── MEMBER DETAIL PANEL (Kept from original codebase) ────────────────────────
class MemberDetailPanel extends StatefulWidget {
  final UserModel member;
  final VoidCallback onClose;
  final TabController tabController;
  final Color green;
  final AppColors appColors;

  const MemberDetailPanel({
    required this.member,
    required this.onClose,
    required this.tabController,
    required this.green,
    required this.appColors,
  });

  @override
  State<MemberDetailPanel> createState() => _MemberDetailPanelState();
}

class _MemberDetailPanelState extends State<MemberDetailPanel> {
  final Color _green = ThemeProvider.primaryGreen;

  void _showEditDialog(String label, String fieldKey, String currentValue) {
    final TextEditingController _editController = TextEditingController(
      text: currentValue == "N/A" ? "" : currentValue,
    );
    showDialog(
      context: context,
      builder: (ctx) {
        final ac = widget.appColors;
        return AlertDialog(
          backgroundColor: ac.cardBackground,
          title: Text("Edit $label", style: TextStyle(color: ac.textPrimary)),
          content: TextField(
            controller: _editController,
            decoration: InputDecoration(
              hintText: "Enter $label",
              hintStyle: TextStyle(color: ac.textMuted),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _green)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _green)),
            ),
            style: TextStyle(color: ac.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel", style: TextStyle(color: ac.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _green),
              onPressed: () async {
                final newValue = _editController.text.trim();
                if (newValue != (currentValue == "N/A" ? "" : currentValue)) {
                  final provider = Provider.of<AuthProvider>(context, listen: false);
                  Navigator.pop(ctx);
                  
                  bool success = await provider.updateProfile({fieldKey: newValue});
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("$label updated successfully"), backgroundColor: Colors.green),
                    );
                    // Refresh current user if needed, though updateProfile usually updates the provider state
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(provider.errorMessage ?? "Failed to update"), backgroundColor: Colors.red),
                    );
                  }
                } else {
                  Navigator.pop(ctx);
                }
              },
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ac = widget.appColors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: ac.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Consumer<UserProvider>(
        builder: (ctx, userProv, _) {
          final profile = userProv.memberProfile;
          final isLoading = userProv.isMemberLoading;
          final taskStats =
              profile?['taskStats'] as Map<String, dynamic>? ?? {};
          final recentTasks = profile?['recentTasks'] as List<dynamic>? ?? [];

          return Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? ac.toolbarBackground
                      : _green.withOpacity(0.06),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  border: Border(bottom: BorderSide(color: ac.divider)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _bigAvatar(widget.member),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.member.fullName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: ac.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _roleBadge(widget.member.role),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: ac.textMuted,
                            size: 24,
                          ),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Contact Info
                    _infoRow(Icons.email_outlined, widget.member.workEmail, ac),
                    const SizedBox(height: 6),
                    _infoRow(
                      Icons.phone_outlined,
                      widget.member.mobileNumber ?? "N/A",
                      ac,
                    ),
                    const SizedBox(height: 6),
                    _infoRow(
                      Icons.supervisor_account_outlined,
                      "Reports To: ${widget.member.manager ?? 'NA'}",
                      ac,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // ── Tabs ──────────────────────────────────────────────────
              TabBar(
                controller: widget.tabController,
                labelColor: _green,
                unselectedLabelColor: ac.textMuted,
                indicatorColor: _green,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: "Tasks"),
                  Tab(text: "Groups"),
                  Tab(text: "Info"),
                ],
              ),

              // ── Tab Content ──────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: widget.tabController,
                  children: [
                    isLoading
                        ? Center(
                            child: CircularProgressIndicator(color: _green),
                          )
                        : _buildTasksTab(taskStats, recentTasks, ac),
                    _buildGroupsTab(ac),
                    _buildInfoTab(widget.member, ac),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTasksTab(
    Map<String, dynamic> taskStats,
    List<dynamic> recentTasks,
    AppColors ac,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Task Statistics",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: ac.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _statChip("Overdue", "${taskStats['overdue'] ?? 0}", Colors.red),
              _statChip(
                "Pending",
                "${taskStats['pending'] ?? 0}",
                Colors.orange,
              ),
              _statChip(
                "In Progress",
                "${taskStats['inProgress'] ?? 0}",
                Colors.blue,
              ),
              _statChip("Completed", "${taskStats['done'] ?? 0}", _green),
              _statChip("Total", "${taskStats['total'] ?? 0}", Colors.grey),
            ],
          ),
          const SizedBox(height: 20),
          if (taskStats.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  "Completion Rate",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ac.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  "${taskStats['completionRate'] ?? 0}%",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _green,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ((taskStats['completionRate'] ?? 0) as num) / 100,
                backgroundColor: ac.cardBorder,
                color: _green,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            "Task Details",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: ac.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (recentTasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "No tasks found",
                  style: TextStyle(color: ac.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D1E),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          "Task Name",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Status",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Due",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...recentTasks.take(10).map((t) {
                  final taskMap = t as Map<String, dynamic>;
                  final status = taskMap['status'] ?? '';
                  final statusColor =
                      status.toLowerCase() == 'done' ||
                          status.toLowerCase() == 'completed'
                      ? Colors.green
                      : (status.toLowerCase() == 'pending'
                            ? Colors.orange
                            : Colors.grey);
                  String due = taskMap['dueDate'] ?? '';
                  if (due.length > 10) due = due.substring(0, 10);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: ac.divider)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            taskMap['delegationName'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: ac.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            due,
                            style: TextStyle(fontSize: 11, color: ac.textMuted),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildGroupsTab(AppColors ac) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined, size: 48, color: ac.textMuted),
          const SizedBox(height: 12),
          Text(
            "No groups assigned yet",
            style: TextStyle(color: ac.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(UserModel member, AppColors ac) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    final bool isOwnProfile = currentUser?.id == member.id;
    final displayMember = isOwnProfile ? currentUser! : member;

    String addressText = [
      if (displayMember.address != null && displayMember.address!.isNotEmpty) displayMember.address,
      if (displayMember.city != null && displayMember.city!.isNotEmpty) displayMember.city,
      if (displayMember.state != null && displayMember.state!.isNotEmpty) displayMember.state,
      if (displayMember.nationality != null && displayMember.nationality!.isNotEmpty) displayMember.nationality,
    ].where((e) => e != null).join(', ');
    if (addressText.isEmpty) addressText = "N/A";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _infoCard("Personal Info", [
            _infoItem(Icons.person_outline, "First Name", displayMember.firstName, ac, fieldKey: 'firstName', canEdit: isOwnProfile),
            _infoItem(Icons.person_outline, "Last Name", displayMember.lastName, ac, fieldKey: 'lastName', canEdit: isOwnProfile),
            _infoItem(Icons.favorite_outline, "Gender", displayMember.gender ?? "N/A", ac, fieldKey: 'gender', canEdit: isOwnProfile),
            _infoItem(Icons.calendar_today_outlined, "Date of Birth", displayMember.dateOfBirth ?? "N/A", ac, fieldKey: 'dateOfBirth', canEdit: isOwnProfile),
            _infoItem(Icons.family_restroom_outlined, "Marital Status", displayMember.maritalStatus ?? "N/A", ac, fieldKey: 'maritalStatus', canEdit: isOwnProfile),
          ], ac),
          const SizedBox(height: 16),
          _infoCard("Communication Details", [
            _infoItem(Icons.email_outlined, "Work Email", displayMember.workEmail, ac), // Email usually not editable by user
            _infoItem(Icons.mail_outline, "Personal Email", displayMember.personalEmail ?? "N/A", ac, fieldKey: 'personalEmail', canEdit: isOwnProfile),
            _infoItem(Icons.phone_outlined, "Primary Mobile", displayMember.mobileNumber ?? "N/A", ac, fieldKey: 'mobileNumber', canEdit: isOwnProfile),
            _infoItem(Icons.phone_in_talk_outlined, "Emergency Contact", displayMember.emergencyMobileNo ?? "N/A", ac, fieldKey: 'emergencyMobileNo', canEdit: isOwnProfile),
            _infoItem(Icons.location_on_outlined, "Address", displayMember.address ?? "N/A", ac, fieldKey: 'address', canEdit: isOwnProfile),
            _infoItem(Icons.location_city_outlined, "City", displayMember.city ?? "N/A", ac, fieldKey: 'city', canEdit: isOwnProfile),
            _infoItem(Icons.map_outlined, "State", displayMember.state ?? "N/A", ac, fieldKey: 'state', canEdit: isOwnProfile),
            _infoItem(Icons.flag_outlined, "Nationality", displayMember.nationality ?? "N/A", ac, fieldKey: 'nationality', canEdit: isOwnProfile),
          ], ac),
          const SizedBox(height: 16),
          _infoCard("Employment & Career", [
            _infoItem(Icons.work_outline, "Role", displayMember.role, ac),
            _infoItem(Icons.badge_outlined, "Designation", displayMember.designation, ac, fieldKey: 'designation', canEdit: isOwnProfile),
            _infoItem(Icons.business_outlined, "Department", displayMember.department, ac, fieldKey: 'department', canEdit: isOwnProfile),
            _infoItem(Icons.supervisor_account_outlined, "Reports To", displayMember.manager ?? "N/A", ac),
            _infoItem(Icons.access_time_outlined, "Joining Date", displayMember.joiningDate ?? "N/A", ac, fieldKey: 'joiningDate', canEdit: isOwnProfile),
            _infoItem(Icons.account_balance_wallet_outlined, "Current Salary", displayMember.currentSalary != null ? "₹${displayMember.currentSalary}" : "N/A", ac),
          ], ac),
        ],
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> items, AppColors ac) {
    return Container(
      decoration: BoxDecoration(
        color: ac.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ac.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: _green,
              ),
            ),
          ),
          const Divider(height: 1),
          ...items,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value, AppColors ac, {String? fieldKey, bool canEdit = false}) {
    bool isNA = value == "N/A" || value.isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: InkWell(
        onTap: (canEdit && (isNA || true)) ? () => _showEditDialog(label, fieldKey!, value) : null,
        child: Row(
          children: [
            Icon(icon, size: 18, color: _green.withOpacity(0.7)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: ac.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ac.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (canEdit)
              Icon(
                isNA ? Icons.add_circle_outline : Icons.edit_outlined,
                size: 16,
                color: isNA ? _green : ac.textMuted,
              ),
          ],
        ),
      ),
    );
  }

  Widget _bigAvatar(UserModel user) {
    final initials = user.firstName.isNotEmpty
        ? user.firstName[0].toUpperCase() +
              (user.lastName.isNotEmpty ? user.lastName[0].toUpperCase() : '')
        : '?';
    return CircleAvatar(
      radius: 36,
      backgroundColor: Colors.blue.withOpacity(0.15),
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _roleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, AppColors ac) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ac.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: ac.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
