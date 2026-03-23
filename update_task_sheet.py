import re

with open('lib/widget/assign_task_sheet.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Add TagModel import
if 'tag_model.dart' not in text:
    text = text.replace('import \'../model/user_model.dart\';', 'import \'../model/user_model.dart\';\nimport \'../model/tag_model.dart\';\nimport \'../provider/tag_provider.dart\';')

# 2. Add _selectedTags list
if '_selectedTags' not in text:
    text = text.replace('  List<String> _checklist = [];', '  List<String> _checklist = [];\n  List<TagModel> _selectedTags = [];')

# 3. Modify Add Tags button in _extraOptionItem
old_add_tags = '_extraOptionItem(Icons.local_offer_outlined, "Add Tags", () { Navigator.pop(ctx); }),'
new_add_tags = '_extraOptionItem(Icons.local_offer_outlined, "Add Tags", () { Navigator.pop(ctx); _showTagsDialog(); }),'
if old_add_tags in text:
    text = text.replace(old_add_tags, new_add_tags)

# 4. Add _showTagsDialog
dialog_code = '''
  void _showTagsDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Container(
                width: 400,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("TASK TAGS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B), letterSpacing: 1.2)),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          child: Icon(Icons.close, color: Colors.blueGrey[300], size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 16),
                    
                    Consumer<TagProvider>(
                      builder: (context, tagProv, _) {
                        if (tagProv.isLoading) return const Center(child: CircularProgressIndicator());
                        
                        final allTags = tagProv.tags;
                        if (allTags.isEmpty) return const Text("No tags available", style: TextStyle(color: Colors.grey));
                        
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: allTags.map((tag) {
                            final isSelected = _selectedTags.any((t) => t.id == tag.id);
                            return InkWell(
                              onTap: () {
                                setDialogState(() {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedTags.removeWhere((t) => t.id == tag.id);
                                    } else {
                                      _selectedTags.add(tag);
                                    }
                                  });
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.blueGrey[50] : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isSelected ? Colors.blueGrey[300]! : Colors.grey[200]!, width: 1.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.local_offer_outlined, size: 14, color: isSelected ? Colors.blueGrey[700] : Colors.blueGrey[400]),
                                    const SizedBox(width: 6),
                                    Text(
                                      tag.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? Colors.blueGrey[700] : Colors.blueGrey[400],
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }
                    ),
                    
                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("CANCEL", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          icon: const Icon(Icons.add, color: Color(0xFF10B981), size: 18),
                          label: const Text("ADD MORE", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF97316),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                          label: const Text("DONE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    )
                  ],
                ),
              );
            }
          ),
        );
      }
    );
  }
'''
if '_showTagsDialog' not in text:
    text = text.replace('  void _showPriorityPicker() {', dialog_code + '\n  void _showPriorityPicker() {')

# 5. Modify _buildTitleField
old_title_field = '''  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      focusNode: _titleFocus,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey[700],
      ),
      decoration: InputDecoration(
        hintText: "Add Task Title...",
        hintStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey[300],
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    );
  }'''

new_title_field = '''  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      focusNode: _titleFocus,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E293B),
      ),
      decoration: InputDecoration(
        hintText: "E.g. Design Homepage...",
        hintStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: Colors.blueGrey[200],
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        isDense: true,
      ),
    );
  }'''

text = text.replace(old_title_field, new_title_field)


# 6. Modify _buildDescField
old_desc_field = '''  Widget _buildDescField() {
    return TextFormField(
      controller: _descController,
      focusNode: _descFocus,
      minLines: 2,
      maxLines: 10,
      style: TextStyle(fontSize: 14, color: Colors.blueGrey[700]),
      decoration: InputDecoration(
        hintText: "Write task details, instructions or goals here...",
        hintStyle: TextStyle(fontSize: 14, color: Colors.blueGrey[300]),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    );
  }'''

new_desc_field = '''  Widget _buildDescField() {
    return TextFormField(
      controller: _descController,
      focusNode: _descFocus,
      minLines: 2,
      maxLines: 10,
      style: const TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.5),
      decoration: InputDecoration(
        hintText: "Add details, references, or context to help complete this task...",
        hintStyle: TextStyle(fontSize: 15, color: Colors.blueGrey[300], height: 1.5, fontStyle: FontStyle.italic),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        isDense: true,
      ),
    );
  }'''

text = text.replace(old_desc_field, new_desc_field)

with open('lib/widget/assign_task_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("Updated sheet")
