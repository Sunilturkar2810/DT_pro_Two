import re

with open('lib/widget/assign_task_sheet.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Evidence Chip Update
old_ev_chip = '''          _buildWebChip(
            icon: Icons.upload_file,
            label: "EVIDENCE",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Evidence required logic can be added here."),
                ),
              );
            },
          ),'''
new_ev_chip = '''          _buildWebChip(
            icon: _requiresEvidence ? Icons.check_circle : Icons.upload_file,
            label: "EVIDENCE",
            isFilled: _requiresEvidence,
            color: const Color(0xFF10B981),
            onTap: () => setState(() => _requiresEvidence = !_requiresEvidence),
          ),'''
text = text.replace(old_ev_chip, new_ev_chip)

# 3 Dots Update
old_3dots = '''          _buildFooterIconBtn(
            icon: Icons.more_horiz,
            color: Colors.grey[600]!,
            onTap: () {},
          ),'''
new_3dots = '''          _buildFooterIconBtn(
            icon: Icons.more_horiz,
            color: Colors.grey[600]!,
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (ctx) => Container(
                  margin: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text("EXTRA OPTIONS", style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        ),
                      ),
                      _extraOptionItem(Icons.link, "Add Link", () { Navigator.pop(ctx); }),
                      _extraOptionItem(Icons.attach_file, "Add Attachment", () { Navigator.pop(ctx); _showAttachmentPicker(); }),
                      _extraOptionItem(Icons.image_outlined, "Upload Image", () { Navigator.pop(ctx); }),
                      _extraOptionItem(Icons.local_offer_outlined, "Add Tags", () { Navigator.pop(ctx); }),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          ),'''
text = text.replace(old_3dots, new_3dots)

# Add _extraOptionItem if not there
if '_extraOptionItem' not in text:
    text = text.replace('  void _showPriorityPicker() {', '''  Widget _extraOptionItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.blueGrey[300]),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }

  void _showPriorityPicker() {''')

with open('lib/widget/assign_task_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("Done")
