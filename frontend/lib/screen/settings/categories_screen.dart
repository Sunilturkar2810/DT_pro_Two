import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/category_provider.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String _selectedColor = '#20E19F';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "CATEGORIES",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2),
        ),
        backgroundColor: const Color(0xFF20E19F),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF20E19F),
        onPressed: () => _showAddCategoryDialog(),
        child: const Icon(Icons.add),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, _) {
          if (categoryProvider.isLoading && categoryProvider.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (categoryProvider.errorMessage != null && categoryProvider.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error: ${categoryProvider.errorMessage}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => categoryProvider.fetchCategories(),
                    child: const Text('Retry'),
                  )
                ],
              ),
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Cards
                  Row(
                    children: [
                      // Total Categories
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF20E19F),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Categories',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${categoryProvider.categories.length}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Recently Added
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recently Added',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                categoryProvider.categories.isNotEmpty
                                    ? (categoryProvider.categories.first['name'] ?? 'N/A')
                                    : 'N/A',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Search
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Category',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'All Categories(${categoryProvider.categories.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 12),

                  // Grid view of categories
                  if (categoryProvider.categories.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Column(
                          children: const [
                            Icon(Icons.category_outlined, size: 48, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 16),
                            Text('No categories yet', style: TextStyle(color: Color(0xFF8B95A5), fontSize: 14)),
                          ],
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: categoryProvider.categories.length,
                      itemBuilder: (context, index) {
                        final category = categoryProvider.categories[index];
                        final categoryId = category['id'] as String;
                        final name = category['name'] as String? ?? 'N/A';
                        final color = category['color'] as String? ?? '#20E19F';
                        final taskCount = category['taskCount'] as int? ?? 0;
                        final createdAt = category['createdAt'] as String? ?? '';

                        return _buildCategoryCard(
                          context,
                          categoryId,
                          name,
                          color,
                          taskCount,
                          createdAt,
                          categoryProvider,
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String categoryId,
    String name,
    String colorCode,
    int taskCount,
    String createdAt,
    CategoryProvider categoryProvider,
  ) {
    // Parse color code to Color
    Color categoryColor = _parseColorString(colorCode);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(color: categoryColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, categoryId, name, categoryProvider),
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete_tasks', child: Text('Delete tasks')),
                    const PopupMenuItem(value: 'delete_link', child: Text('Delete link')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete Category')),
                  ],
                  icon: const Icon(Icons.more_vert, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Task count
            Row(
              children: [
                const Icon(Icons.assignment, size: 14, color: Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Text(
                  '$taskCount Task',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            const Spacer(),

            // Created date
            Text(
              _formatDate(createdAt),
              style: const TextStyle(fontSize: 10, color: Color(0xFFAEB5C0)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, String categoryId, String categoryName, CategoryProvider categoryProvider) {
    switch (action) {
      case 'edit':
        _showEditCategoryDialog(categoryId);
        break;
      case 'delete_tasks':
        _showDeleteTasksConfirmation(categoryId, categoryName, categoryProvider);
        break;
      case 'delete_link':
        _showRemoveLinkConfirmation(categoryId, categoryName, categoryProvider);
        break;
      case 'delete':
        _showDeleteCategoryConfirmation(categoryId, categoryName, categoryProvider);
        break;
    }
  }

  void _showAddCategoryDialog() {
    _nameController.clear();
    _selectedColor = '#20E19F';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text('Select Color:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _getColorOptions()
                    .map(
                      (colorHex) => GestureDetector(
                        onTap: () => setState(() => _selectedColor = colorHex),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _parseColorString(colorHex),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedColor == colorHex ? Colors.black : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter category name')),
                  );
                  return;
                }

                final success = await context.read<CategoryProvider>().createCategory(
                  name: _nameController.text,
                  color: _selectedColor,
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Category added!' : 'Error adding category'),
                      backgroundColor: success ? const Color(0xFF20E19F) : Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF20E19F)),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(String categoryId) {
    final provider = context.read<CategoryProvider>();
    final category = provider.categories.firstWhere((c) => c['id'] == categoryId);
    _nameController.text = category['name'] as String? ?? '';
    _selectedColor = category['color'] as String? ?? '#20E19F';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text('Select Color:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _getColorOptions()
                    .map(
                      (colorHex) => GestureDetector(
                        onTap: () => setState(() => _selectedColor = colorHex),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _parseColorString(colorHex),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedColor == colorHex ? Colors.black : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final success = await context.read<CategoryProvider>().updateCategory(
                  categoryId: categoryId,
                  name: _nameController.text,
                  color: _selectedColor,
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Category updated!' : 'Error updating category'),
                      backgroundColor: success ? const Color(0xFF20E19F) : Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF20E19F)),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteCategoryConfirmation(String categoryId, String categoryName, CategoryProvider categoryProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete the category "$categoryName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await categoryProvider.deleteCategory(categoryId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Category deleted!' : 'Error deleting category'),
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

  void _showDeleteTasksConfirmation(String categoryId, String categoryName, CategoryProvider categoryProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tasks'),
        content: Text('Delete all tasks in "$categoryName"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await categoryProvider.deleteCategoryTasks(categoryId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Tasks deleted!' : 'Error deleting tasks'),
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

  void _showRemoveLinkConfirmation(String categoryId, String categoryName, CategoryProvider categoryProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Category Link'),
        content: Text('Unlink category from all tasks in "$categoryName"? Tasks will remain but category will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await categoryProvider.removeCategoryLink(categoryId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Link removed!' : 'Error removing link'),
                    backgroundColor: success ? const Color(0xFF20E19F) : Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Color _parseColorString(String colorCode) {
    try {
      return Color(int.parse('0xFF${colorCode.replaceAll('#', '')}'));
    } catch (e) {
      return const Color(0xFF20E19F);
    }
  }

  List<String> _getColorOptions() {
    return [
      '#20E19F', // Green
      '#FF6B6B', // Red
      '#4ECDC4', // Teal
      '#FFD93D', // Yellow
      '#6C5CE7', // Purple
      '#00B4D8', // Blue
      '#FF85A2', // Pink
      '#FF8C42', // Orange
    ];
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return 'Created: ${date.day} ${_getMonthName(date.month)}, ${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
