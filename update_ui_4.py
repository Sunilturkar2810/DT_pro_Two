import re

with open('lib/widget/assign_task_sheet.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Category Picker Update
old_cat = '''  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Consumer<CategoryProvider>(
          builder: (context, catProvider, child) {
            final categories = catProvider.categories;
            if (catProvider.isLoading) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (categories.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('No categories available.')),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final c = categories[index];
                final isSelected = _selectedCategory?.id == c.id;
                return ListTile(
                  title: Text(c.name),
                  trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                  onTap: () {
                    setState(() => _selectedCategory = c);
                    Navigator.pop(ctx);
                  },
                );
              },
            );
          },
        );
      },
    );
  }'''

new_cat = '''  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Consumer<CategoryProvider>(
            builder: (context, catProvider, child) {
              final categories = catProvider.categories;
              if (catProvider.isLoading) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (categories.isEmpty) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: Text('No categories available.', style: TextStyle(color: Colors.grey))),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("SELECT CATEGORY", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 8),
                      shrinkWrap: true,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final c = categories[index];
                        final isSelected = _selectedCategory?.id == c.id;
                        return InkWell(
                          onTap: () {
                            setState(() => _selectedCategory = c);
                            Navigator.pop(ctx);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: (c.color != null && c.color!.length >= 6) 
                                        ? Color(int.parse(c.color!.replaceAll('#', '0xFF'))) 
                                        : Colors.blueAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(c.name, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: const Color(0xFF1E293B)))),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }'''

text = text.replace(old_cat, new_cat)

with open('lib/widget/assign_task_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("Done Cat")
