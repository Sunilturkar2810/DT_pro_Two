import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../provider/task_template_provider.dart';
import '../../provider/auth_provider.dart';

class TaskTemplatesScreen extends StatefulWidget {
  const TaskTemplatesScreen({Key? key}) : super(key: key);

  @override
  State<TaskTemplatesScreen> createState() => _TaskTemplatesScreenState();
}

class _TaskTemplatesScreenState extends State<TaskTemplatesScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> priorityOptions = ['All', 'Low', 'Medium', 'High', 'Urgent'];
  final List<String> frequencyOptions = ['All', 'Once', 'Daily', 'Weekly', 'Monthly'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskTemplateProvider>().fetchTemplates();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return Colors.redAccent;
      case 'High':
        return Colors.orangeAccent;
      case 'Medium':
        return Colors.amber;
      case 'Low':
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('TASK TEMPLATES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF20E19F),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddTemplateDialog(context),
          ),
        ],
      ),
      body: Consumer<TaskTemplateProvider>(
        builder: (context, provider, child) {
          final cats = provider.categoriesWithCount;
          final filteredList = provider.filteredTemplates;

          if (provider.isLoading && provider.templates.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Filters Section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Search
                      Container(
                        width: 150,
                        margin: const EdgeInsets.only(right: 8),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search templates...',
                            hintStyle: const TextStyle(fontSize: 12),
                            prefixIcon: const Icon(Icons.search, size: 16),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                          ),
                          onChanged: (val) => provider.setSearchQuery(val),
                        ),
                      ),
                      
                      // Priority
                      _buildFilterDropdown(
                        value: provider.priorityFilter,
                        items: priorityOptions,
                        onChanged: (val) => provider.setPriorityFilter(val!),
                      ),
                      const SizedBox(width: 8),

                      // Frequency
                      _buildFilterDropdown(
                        value: provider.frequencyFilter,
                        items: frequencyOptions,
                        onChanged: (val) => provider.setFrequencyFilter(val!),
                      ),
                      const SizedBox(width: 8),

                      // Created By
                      _buildFilterDropdown(
                        value: provider.createdByFilter,
                        items: ['All', ...provider.users.map((e) => e.id)],
                        displayMap: {
                          'All': 'Created By',
                          for (var u in provider.users) u.id: '${u.firstName} ${u.lastName}',
                        },
                        onChanged: (val) => provider.setCreatedByFilter(val!),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 8),

              // Categories Horizontal List (replaces Sidebar on Web)
              SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cats.length,
                  itemBuilder: (context, index) {
                    final catName = cats[index]['name'];
                    final count = cats[index]['count'];
                    final isSelected = provider.selectedCategory == catName;

                    return GestureDetector(
                      onTap: () => provider.setSelectedCategory(catName),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF20E19F).withOpacity(0.1) : Colors.white,
                          border: Border.all(color: isSelected ? const Color(0xFF20E19F) : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            '$catName ($count)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? const Color(0xFF1E8D66) : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Templates List
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.description_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(provider.searchQuery.isEmpty ? "No Templates Found" : "No matches found", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                            if (provider.searchQuery.isNotEmpty)
                              TextButton(onPressed: provider.resetFilters, child: const Text('Clear Filters', style: TextStyle(color: Color(0xFF20E19F))))
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final template = filteredList[index];
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade100),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          template.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.check_box_outlined, color: Color(0xFF20E19F), size: 20),
                                            tooltip: 'Assign from Template',
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            onPressed: () {},
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                            tooltip: 'Delete',
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('Delete Template'),
                                                  content: const Text('Are you sure you want to delete this?'),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                                    TextButton(
                                                      onPressed: () async {
                                                        Navigator.pop(context);
                                                        await provider.deleteTemplate(template.id);
                                                      }, 
                                                      child: const Text('Delete', style: TextStyle(color: Colors.red))
                                                    ),
                                                  ],
                                                )
                                              );
                                            },
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (template.priority != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getPriorityColor(template.priority!).withOpacity(0.1),
                                            border: Border.all(color: _getPriorityColor(template.priority!).withOpacity(0.3)),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(template.priority!.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getPriorityColor(template.priority!))),
                                        ),
                                      if (template.category != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(template.category!.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                                        ),
                                      if (template.frequency != null && template.frequency != 'Once')
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.indigo.shade50,
                                            border: Border.all(color: Colors.indigo.shade100),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.repeat, size: 10, color: Colors.indigo.shade400),
                                              const SizedBox(width: 4),
                                              Text(template.frequency!.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo.shade400)),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  if (template.description != null && template.description!.isNotEmpty)
                                    Text(
                                      template.description!,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.teal,
                                            child: Text(
                                              '${template.creatorFirstName?[0] ?? '?'}${template.creatorLastName?[0] ?? ''}',
                                              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text('${template.creatorFirstName ?? 'User'} ${template.creatorLastName ?? ''}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.date_range, size: 12, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            template.createdAt != null ? DateFormat('MMM dd, yyyy').format(template.createdAt!) : 'N/A',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                                          )
                                        ],
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    Map<String, String>? displayMap,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(displayMap != null ? (displayMap[val] ?? val) : val),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAddTemplateDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'General';
    String selectedPriority = 'Medium';
    String selectedFrequency = 'Once';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Create Task Template', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Server Maintenance',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Template details...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: selectedPriority,
                                    items: ['Urgent', 'High', 'Medium', 'Low'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                                    onChanged: (val) => setState(() => selectedPriority = val!),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Frequency', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Container(
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: selectedFrequency,
                                    items: ['Once', 'Daily', 'Weekly', 'Monthly'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                                    onChanged: (val) => setState(() => selectedFrequency = val!),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
                      return;
                    }
                    
                    try {
                      final provider = ctx.read<TaskTemplateProvider>();
                      final auth = ctx.read<AuthProvider>().currentUser;
                      
                      final data = {
                        "title": titleController.text.trim(),
                        "description": descriptionController.text.trim(),
                        "category": selectedCategory,
                        "priority": selectedPriority,
                        "frequency": selectedFrequency,
                        "createdBy": auth?.id ?? '',
                      };
                      
                      Navigator.pop(ctx);
                      
                      const snackInfo = SnackBar(content: Text('Creating Template...'));
                      ScaffoldMessenger.of(context).showSnackBar(snackInfo);
                      
                      // Assume create method exists or we quickly add it in provider
                      await provider.createTemplate(data);
                      
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template created!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF20E19F), elevation: 0),
                  child: const Text('Save Template', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }
}
