import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/category_provider.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = false;
  String _searchQuery = "";

  final List<Color> _presetColors = [
    const Color(0xFFE91E63), const Color(0xFF9C27B0), const Color(0xFF673AB7),
    const Color(0xFF3F51B5), const Color(0xFF2196F3), const Color(0xFF42A5F5),
    const Color(0xFF64B5F6), const Color(0xFF4DD0E1), const Color(0xFF26A69A),
    const Color(0xFF10B981), const Color(0xFF8BC34A), const Color(0xFFCDDC39),
    const Color(0xFFFFEB3B), const Color(0xFFFFC107), const Color(0xFFFF9800),
    const Color(0xFF607D8B), const Color(0xFF455A64),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("CATEGORIES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)),
        backgroundColor: const Color(0xFF20E19F),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(),
        backgroundColor: const Color(0xFF10B981),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Category", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          final categories = provider.categories.where((c) {
            final name = c['name']?.toString().toLowerCase() ?? "";
            return name.contains(_searchQuery.toLowerCase());
          }).toList();
          
          return Column(
            children: [
              _buildTopStats(
                provider.categories.length, 
                provider.categories.isNotEmpty ? (provider.categories.last['name']?.toString() ?? "None") : "None"
              ),
              _buildSearchBar(),
              Expanded(
                child: provider.isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : categories.isEmpty 
                        ? _buildEmptyState()
                        : _isGridView ? _buildGridView(categories) : _buildListView(categories),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopStats(int total, String recent) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Expanded(child: _statCard("Total Categories", total.toString(), Icons.folder_rounded, const Color(0xFF10B981))),
          const SizedBox(width: 15),
          Expanded(child: _statCard("Recently Added", recent, Icons.access_time_filled_rounded, Colors.blue)),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: "Search categories...",
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> categories) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final name = cat['name']?.toString() ?? "Unknown";
        final color = _parseColor(cat['color']?.toString());
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(Icons.tag, color: color, size: 20)),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () => _confirmDelete(cat['id']?.toString() ?? ""),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> categories) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.3),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final name = cat['name']?.toString() ?? "Unknown";
        final color = _parseColor(cat['color']?.toString());
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  GestureDetector(onTap: () => _confirmDelete(cat['id']?.toString() ?? ""), child: const Icon(Icons.close, size: 16, color: Colors.grey)),
                ],
              ),
              const Spacer(),
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No Categories Found", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return const Color(0xFF10B981);
    try {
      if (colorStr.startsWith('#')) return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
      return Color(int.parse(colorStr));
    } catch (e) {
      return const Color(0xFF10B981);
    }
  }

  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    Color selectedColor = _presetColors[9];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Create Category", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(hintText: "e.g. Design, Marketing", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 20),
              const Align(alignment: Alignment.centerLeft, child: Text("Color Label", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetColors.map((color) => GestureDetector(
                  onTap: () => setModalState(() => selectedColor = color),
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle,
                      border: selectedColor == color ? Border.all(color: Colors.black, width: 2) : null,
                    ),
                  ),
                )).toList(),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final hexColor = '#${selectedColor.value.toRadixString(16).substring(2)}';
                  await context.read<CategoryProvider>().createCategory(
                    name: nameController.text,
                    color: hexColor,
                  );
                  if (mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text("Create", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    if (id.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Category"),
        content: const Text("Are you sure you want to delete this category?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () async {
            await context.read<CategoryProvider>().deleteCategory(id);
            if (mounted) Navigator.pop(context);
          }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
