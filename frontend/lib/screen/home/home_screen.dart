import 'package:d_table_delegate_system/model/delegate_model.dart';
import 'package:d_table_delegate_system/model/user_model.dart';
import 'package:d_table_delegate_system/provider/auth_provider.dart';
import 'package:d_table_delegate_system/provider/dashboard_provider.dart';
import 'package:d_table_delegate_system/provider/delegation_provider.dart';
import 'package:d_table_delegate_system/provider/theme_provider.dart';
import 'package:d_table_delegate_system/provider/category_provider.dart';
import 'package:d_table_delegate_system/provider/user_provider.dart';
import 'package:d_table_delegate_system/widget/app_dropdown.dart';
import 'package:d_table_delegate_system/widget/custom_search_dropdown.dart';
import 'package:d_table_delegate_system/widget/custom_multi_dropdown.dart';
import 'package:d_table_delegate_system/widget/custom_simple_dropdown.dart';
import 'package:d_table_delegate_system/widget/custom_category_dropdown.dart';
import 'package:d_table_delegate_system/widget/assign_task_sheet.dart';
import 'package:d_table_delegate_system/widget/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class DynamicDashboard extends StatefulWidget {
  const DynamicDashboard({super.key});

  @override
  State<DynamicDashboard> createState() => _DynamicDashboardState();
}

class _DynamicDashboardState extends State<DynamicDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Color primaryColor = ThemeProvider.primaryGreen;
  final TextEditingController _searchController = TextEditingController();
  UserModel? _selectedUser;
  String? _selectedFrequency;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DelegationProvider>(context, listen: false).fetchAll();
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboardStats();
      // Users & Categories pre-load kar lo taaki assign sheet khulte hi ready ho
      final userProv = Provider.of<UserProvider>(context, listen: false);
      if (userProv.users.isEmpty) userProv.fetchUsers();
      final catProv = Provider.of<CategoryProvider>(context, listen: false);
      if (catProv.categories.isEmpty) catProv.fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isMobile = width < 800;
    var dashPro = Provider.of<DashboardProvider>(context);
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: MyCustomDrawer(),
      floatingActionButton: GestureDetector(
        onTap: () => _showAssignBottomSheet(context),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_task_rounded, color: Colors.white, size: 26),
              SizedBox(height: 3),
              Text("Assign", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              backgroundColor: primaryColor,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: const Text("DASHBOARD", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5)),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                    ),
                  ),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black), onPressed: () {}),
                ),
              ],
            ),
          ];
        },
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Performance Overview", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appColors.textPrimary)),
                    const SizedBox(height: 15),
                    _buildDateFilters(dashPro),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  children: [
                    _buildSummaryCards(isMobile),
                    const SizedBox(height: 25),
                    _buildActionRow(isMobile),
                    const SizedBox(height: 25),
                    _buildViewToggle(dashPro),
                    const SizedBox(height: 25),
                    _buildSubTabs(dashPro),
                    const SizedBox(height: 10),
                    dashPro.isTableView ? _buildReportTable(isMobile) : _buildAnalyticsCharts(dashPro, isMobile),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const AssignTaskSheet(),
    ).then((_) {
      Provider.of<DelegationProvider>(context, listen: false).fetchAll();
    });
  }

  Widget _buildDateFilters(DashboardProvider provider) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    const List<String> filters = ["Today", "Yesterday", "This Week", "Last Week", "This Month", "Last Month", "This Year", "All Time", "Custom"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          bool active = provider.selectedFilter == f;
          return GestureDetector(
            onTap: () async {
              if (f == 'Custom') {
                final picked = await showDateRangePicker(
                  context: context, firstDate: DateTime(2000), lastDate: DateTime(2100),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: primaryColor, onPrimary: Colors.white, onSurface: Colors.black)),
                    child: child!,
                  ),
                );
                if (picked != null) provider.setFilter(f, startDate: picked.start, endDate: picked.end);
              } else {
                provider.setFilter(f);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: active ? primaryColor : appColors.chipBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: active ? primaryColor : appColors.cardBorder),
                boxShadow: active ? [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
              ),
              child: Text(
                f == 'Custom' && active && provider.customStartDate != null
                    ? '${provider.customStartDate!.day}/${provider.customStartDate!.month} - ${provider.customEndDate!.day}/${provider.customEndDate!.month}'
                    : f,
                style: TextStyle(color: active ? Colors.white : appColors.textSecondary, fontSize: 13, fontWeight: active ? FontWeight.bold : FontWeight.w500),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards(bool isMobile) {
    return Consumer<DashboardProvider>(
      builder: (context, dashPro, _) {
        if (dashPro.isLoading) return const SizedBox(height: 130, child: Center(child: CircularProgressIndicator()));
        final stats = dashPro.taskStats;
        final cards = [
          _statusCard("OVERDUE",     (stats["overdue"]    ?? 0).toString(), Colors.redAccent,        Icons.warning_rounded),
          _statusCard("PENDING",     (stats["pending"]    ?? 0).toString(), Colors.orangeAccent,     Icons.hourglass_empty_rounded),
          _statusCard("IN PROGRESS", (stats["inProgress"] ?? 0).toString(), Colors.blueAccent,       Icons.sync_rounded),
          _statusCard("COMPLETED",   (stats["done"]       ?? 0).toString(), primaryColor,            Icons.check_circle_outline_rounded),
          _statusCard("ON TIME",     (stats["onTime"]     ?? 0).toString(), Colors.teal,             Icons.timer_outlined),
          _statusCard("DELAYED",     (stats["delayed"]    ?? 0).toString(), Colors.deepOrangeAccent, Icons.history_rounded),
        ];
        if (isMobile) {
          return SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SizedBox(width: 150, child: cards[i]),
            ),
          );
        }
        return LayoutBuilder(builder: (context, constraints) {
          int crossCount = constraints.maxWidth > 1200 ? 6 : (constraints.maxWidth > 800 ? 3 : 2);
          double aspectRatio = constraints.maxWidth > 1200 ? 1.5 : 2.5;
          return GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: crossCount, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: aspectRatio, children: cards);
        });
      },
    );
  }

  Widget _statusCard(String title, String count, Color color, IconData icon) {
    final appColors2 = Theme.of(context).extension<AppColors>()!;
    return Container(
      decoration: BoxDecoration(color: appColors2.cardBackground, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: appColors2.shadowColor, blurRadius: 10, offset: const Offset(0, 4))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
                  Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: appColors2.textPrimary)),
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: appColors2.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                  ])),
                ],
              ),
            ),
            Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 4, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(bool isMobile) {
    final appColors3 = Theme.of(context).extension<AppColors>()!;
    var dashPro = Provider.of<DashboardProvider>(context);
    final userProv = Provider.of<UserProvider>(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: appColors3.cardBackground, 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [BoxShadow(color: appColors3.shadowColor, blurRadius: 10)]
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _clearButton(context),
            const SizedBox(width: 12),
            CustomSearchDropdown<UserModel>(
              label: "Assigned To",
              items: userProv.users,
              value: _selectedUser,
              width: 150,
              labelBuilder: (u) => "${u.firstName} ${u.lastName}",
              onChanged: (val) {
                setState(() => _selectedUser = val);
              },
            ),
            const SizedBox(width: 12),
            CustomCategoryDropdown(
              items: ["All", ...dashPro.categories],
              value: dashPro.selectedCategory.isEmpty ? "All" : dashPro.selectedCategory,
              onChanged: (val) {
                Provider.of<DashboardProvider>(context, listen: false).setCategory(val);
              },
            ),
            const SizedBox(width: 12),
            CustomSimpleDropdown<String>(
              label: "Frequency",
              items: const ["All", "Daily", "Weekly", "Monthly", "Yearly"],
              value: _selectedFrequency,
              width: 150,
              labelBuilder: (f) => f,
              onChanged: (val) {
                setState(() => _selectedFrequency = val);
              },
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 200,
              child: _searchField(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clearButton(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextButton.icon(
        onPressed: () { 
          _searchController.clear(); 
          setState(() {
            _selectedUser = null;
            _selectedFrequency = null;
          });
          Provider.of<DashboardProvider>(context, listen: false).resetFilters(); 
        },
        icon: const Icon(Icons.filter_alt_off_rounded, size: 16, color: Color(0xFF616161)),
        label: const Text("Clear", style: TextStyle(color: Color(0xFF616161), fontWeight: FontWeight.w600, fontSize: 13)),
        style: TextButton.styleFrom(backgroundColor: const Color(0xFFE0E5E9), padding: const EdgeInsets.symmetric(horizontal: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      ),
    );
  }

  Widget _searchField(BuildContext context) {
    final appColors4 = Theme.of(context).extension<AppColors>()!;
    return Container(
      height: 42,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withOpacity(0.25))),
      child: TextField(
        controller: _searchController,
        onSubmitted: (value) => Provider.of<DashboardProvider>(context, listen: false).setSearchQuery(value),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: "Search...", hintStyle: TextStyle(color: appColors4.textMuted, fontSize: 13), 
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: appColors4.textMuted), 
          border: InputBorder.none, 
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12)
        ),
      ),
    );
  }

  Widget _buildViewToggle(DashboardProvider provider) {
    return Center(
      child: Container(
        decoration: BoxDecoration(color: Theme.of(context).extension<AppColors>()!.inputBackground, borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(4),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _toggleBtn("Table", Icons.table_chart_rounded, provider.isTableView, () => provider.toggleView(true)),
          _toggleBtn("Analytics", Icons.analytics_rounded, !provider.isTableView, () => provider.toggleView(false)),
        ]),
      ),
    );
  }

  Widget _toggleBtn(String text, IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Theme.of(context).cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active ? [BoxShadow(color: Theme.of(context).extension<AppColors>()!.shadowColor, blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: active ? primaryColor : Theme.of(context).extension<AppColors>()!.textMuted),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: active ? Theme.of(context).extension<AppColors>()!.textPrimary : Theme.of(context).extension<AppColors>()!.textMuted, fontWeight: active ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _buildSubTabs(DashboardProvider provider) {
    final ac = Theme.of(context).extension<AppColors>()!;

    final List<Map<String, dynamic>> tabs = [
      {"icon": Icons.people_outline, "label": "Employees"},
      {"icon": Icons.folder_open_outlined, "label": "Groups"},
      {"icon": Icons.check_circle_outline, "label": "My Report"},
      {"icon": Icons.share_outlined, "label": "Delegated"},
      {"icon": Icons.calendar_today_outlined, "label": "Daily"},
      {"icon": Icons.calendar_month_outlined, "label": "Monthly"},
      {"icon": Icons.schedule_outlined, "label": "Overdue"},
      {"icon": Icons.local_offer_outlined, "label": "Tags"},
      {"icon": Icons.category_outlined, "label": "Categories"},
    ];

    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ac.divider, width: 1.5))),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: tabs.map((tab) {
            String label = tab["label"];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _subTabItem(
                tab["icon"],
                label,
                provider.selectedTab == label,
                onTap: () {
                  provider.setTab(label);
                  // Further Dynamic API calls can be triggered here based on the selected tab
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _subTabItem(IconData icon, String label, bool active, {required VoidCallback onTap}) {
    final ac = Theme.of(context).extension<AppColors>()!;
    return InkWell(
      onTap: onTap,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(children: [
            Icon(icon, size: 20, color: active ? primaryColor : ac.textMuted),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: active ? FontWeight.bold : FontWeight.w500, color: active ? primaryColor : ac.textMuted)),
          ]),
        ),
        if (active) Container(height: 3, width: 100, decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(10))),
      ]),
    );
  }

  Widget _buildReportTable(bool isMobile) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return Center(child: Padding(padding: const EdgeInsets.all(40), child: CircularProgressIndicator(color: primaryColor)));
        final acTable = Theme.of(context).extension<AppColors>()!;
        return Container(
          decoration: BoxDecoration(color: acTable.cardBackground, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: acTable.shadowColor, blurRadius: 10)]),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Builder(builder: (context) {
              double tableMinWidth = 864;
              double screenAvailableWidth = MediaQuery.of(context).size.width - 32;
              double finalWidth = screenAvailableWidth > tableMinWidth ? screenAvailableWidth : tableMinWidth;
              return SizedBox(
                width: finalWidth,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: finalWidth,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    color: const Color(0xFF1A1D1E),
                    child: Row(children: [
                      _cell(180, _th("Employee Name"), isHeader: true),
                      _cell(80, _th("Total"), isHeader: true),
                      _cell(80, _th("Score"), isHeader: true),
                      _cell(100, _th("Overdue"), isHeader: true),
                      _cell(100, _th("Pending"), isHeader: true),
                      _cell(100, _th("In-Progress"), isHeader: true),
                      _cell(100, _th("In Time"), isHeader: true),
                      _cell(100, _th("Delayed"), isHeader: true),
                    ]),
                  ),
                  if (provider.categoryStats.isEmpty)
                    const Padding(padding: EdgeInsets.all(60), child: Center(child: Text("No records found", style: TextStyle(color: Colors.grey))))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.categoryStats.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: acTable.divider),
                      itemBuilder: (context, index) {
                        final cat = provider.categoryStats[index];
                        return _tdRow(cat['name'] ?? "Unknown", cat['total'].toString(), cat['score'].toString(), cat['overdue'].toString(), cat['pending'].toString(), cat['in_progress']?.toString() ?? "0", cat['in_time']?.toString() ?? "0", cat['delayed']?.toString() ?? "0");
                      },
                    ),
                ]),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _th(String t) => Text(t, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11));

  Widget _tdRow(String title, String total, String score, String overdue, String pending, String inProgress, String inTime, String delayed) {
    final acTd = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(children: [
        _cell(180, Row(children: [
          _circularIndicator(score, score.contains("100") ? Colors.green : (score == "0%" ? Colors.red : Colors.orange)),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: acTd.textPrimary))),
        ])),
        _cell(80, Text(total, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: acTd.textPrimary))),
        _cell(80, Text(score, textAlign: TextAlign.center, style: TextStyle(color: score.contains("100") ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 13))),
        _cell(100, _statusValue(overdue, Colors.red, total)),
        _cell(100, _statusValue(pending, Colors.orange, total)),
        _cell(100, _statusValue(inProgress, Colors.blue, total)),
        _cell(100, _statusValue(inTime, Colors.green, total)),
        _cell(100, _statusValue(delayed, Colors.deepOrange, total)),
      ]),
    );
  }

  Widget _cell(int flexValue, Widget child, {bool isHeader = false}) {
    return Expanded(flex: flexValue, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: child));
  }

  Widget _statusValue(String val, Color color, String total) {
    int v = int.tryParse(val) ?? 0;
    int t = int.tryParse(total) ?? 1;
    int perc = ((v / (t == 0 ? 1 : t)) * 100).toInt();
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(val, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      Text("($perc%)", style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 9)),
    ]);
  }

  Widget _circularIndicator(String label, Color color) {
    return Container(
      width: 34, height: 34,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.2), width: 2)),
      child: Center(child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.05)),
        child: Center(child: Text(label.replaceAll("%", ""), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color))),
      )),
    );
  }

  Widget _buildAnalyticsCharts(DashboardProvider dashPro, bool isMobile) {
    if (dashPro.isLoading) return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
    final stats = dashPro.taskStats;
    final ac = Theme.of(context).extension<AppColors>()!;

    // 1. OVERDUE, PENDING & IN-PROGRESS
    int overdue = stats["overdue"] ?? 0;
    int pending = stats["pending"] ?? 0;
    int inProgress = stats["inProgress"] ?? 0;
    int total1 = overdue + pending + inProgress;

    // 2. COMPLETED & NOT COMPLETED
    int completed = stats["done"] ?? 0;
    int notCompleted = (stats["total"] ?? 0) - completed;
    if (notCompleted < 0) notCompleted = 0;
    int total2 = completed + notCompleted;

    // 3. IN-TIME & DELAYED
    int onTime = stats["onTime"] ?? 0;
    int delayed = stats["delayed"] ?? 0;
    int total3 = onTime + delayed;

    return Column(
      children: [
        if (!isMobile)
          Row(
            children: [
              Expanded(child: _chartCard("OVERDUE, PENDING & IN-PROGRESS", total1, [
                _chartSection(overdue, Colors.redAccent, "Overdue"),
                _chartSection(pending, Colors.orangeAccent, "Pending"),
                _chartSection(inProgress, Colors.blueAccent, "In Progress"),
              ])),
              const SizedBox(width: 16),
              Expanded(child: _chartCard("COMPLETED & NOT COMPLETED", total2, [
                _chartSection(completed, primaryColor, "Completed"),
                _chartSection(notCompleted, Colors.grey.withOpacity(0.5), "Not Completed"),
              ])),
            ],
          )
        else ...[
          _chartCard("OVERDUE, PENDING & IN-PROGRESS", total1, [
            _chartSection(overdue, Colors.redAccent, "Overdue"),
            _chartSection(pending, Colors.orangeAccent, "Pending"),
            _chartSection(inProgress, Colors.blueAccent, "In Progress"),
          ]),
          const SizedBox(height: 16),
          _chartCard("COMPLETED & NOT COMPLETED", total2, [
            _chartSection(completed, primaryColor, "Completed"),
            _chartSection(notCompleted, Colors.grey.withOpacity(0.5), "Not Completed"),
          ]),
        ],
        const SizedBox(height: 16),
        _chartCard("IN-TIME & DELAYED", total3, [
          _chartSection(onTime, Colors.teal, "In-Time"),
          _chartSection(delayed, Colors.deepOrangeAccent, "Delayed"),
        ], isFullWidth: true),
      ],
    );
  }

  Widget _chartCard(String title, int total, List<PieChartSectionData> sections, {bool isFullWidth = false}) {
    final ac = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ac.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: ac.shadowColor, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: sections,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("$total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ac.textPrimary)),
                          Text("TOTAL", style: TextStyle(fontSize: 8, color: ac.textMuted, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: sections.map((s) {
                    double perc = total > 0 ? (s.value / total) * 100 : 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(s.title, style: TextStyle(fontSize: 12, color: ac.textSecondary))),
                          Text("${s.value.toInt()} (${perc.toStringAsFixed(0)}%)", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PieChartSectionData _chartSection(int value, Color color, String title) {
    return PieChartSectionData(
      color: color,
      value: value.toDouble(),
      title: '', // We show title in legent instead
      radius: 12,
      showTitle: false,
    );
  }

  Widget _buildPlaceholderChart() {
    // Keep for fallback or just remove
    return const SizedBox.shrink();
  }
}