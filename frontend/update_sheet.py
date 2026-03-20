import re

with open('lib/widget/assign_task_sheet.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = re.sub(
    r'_extraOptionItem\(\s*Icons\.local_offer_outlined,\s*"Add Tags",\s*\(\)\s*\{[^}]*\},?\s*\)',
    r'_extraOptionItem(Icons.local_offer_outlined, "Add Tags", () { Navigator.pop(ctx); _showTagsDialog(); })',
    text
)

text = re.sub(
    r'_extraOptionItem\(\s*Icons\.link,\s*"Add Link",\s*\(\)\s*\{[^}]*\},?\s*\)',
    r'_extraOptionItem(Icons.link, "Add Link", () { Navigator.pop(ctx); _showLinkDialog(); })',
    text
)

# Replace Title Font
old_title_style = '''      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E293B),
      ),'''
new_title_style = '''      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),'''
text = text.replace(old_title_style, new_title_style)

old_title_hint = '''        hintStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: Colors.blueGrey[200],
        ),'''
new_title_hint = '''        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey[300],
        ),'''
text = text.replace(old_title_hint, new_title_hint)

# Replace description Font
old_desc_style = '''      style: const TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.5),'''
new_desc_style = '''      style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.5, fontWeight: FontWeight.w500),'''
text = text.replace(old_desc_style, new_desc_style)

old_desc_hint = '''        hintStyle: TextStyle(fontSize: 15, color: Colors.blueGrey[300], height: 1.5, fontStyle: FontStyle.italic),'''
new_desc_hint = '''        hintStyle: TextStyle(fontSize: 12, color: Colors.blueGrey[300], height: 1.5, fontWeight: FontWeight.normal),'''
text = text.replace(old_desc_hint, new_desc_hint)

old_desc_text = '''"Add details, references, or context to help complete this task..."'''
new_desc_text = '''"Write task details, instructions or goals here..."'''
text = text.replace(old_desc_text, new_desc_text)

# Add _showLinkDialog if it doesn't exist
link_dialog_code = '''
  void _showLinkDialog() {
    final linkController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("ADD LINK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B), letterSpacing: 1.2)),
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      child: Icon(Icons.close, color: Colors.blueGrey[300], size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: linkController,
                  decoration: InputDecoration(
                    hintText: 'https://...',
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF10B981))),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("CANCEL", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (linkController.text.isNotEmpty) {
                          setState(() {
                            refDocUrls.add(linkController.text);
                          });
                        }
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                      label: const Text("ADD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
'''
if '_showLinkDialog' not in text:
    text = text.replace('  void _showTagsDialog() {', link_dialog_code + '\n  void _showTagsDialog() {')

with open('lib/widget/assign_task_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("Updates applied")
