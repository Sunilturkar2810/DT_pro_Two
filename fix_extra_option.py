with open('lib/widget/assign_task_sheet.dart', 'r', encoding='utf-8') as f:
    text = f.read()

if '_extraOptionItem' not in text:
    lines = text.split('\n')
    # Find the last closing brace of the class
    last_brace_index = -1
    for i in range(len(lines) - 1, -1, -1):
        if lines[i].strip() == '}':
            last_brace_index = i
            break
            
    if last_brace_index != -1:
        extra_method = '''
  Widget _extraOptionItem(IconData icon, String title, VoidCallback onTap) {
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
'''
        lines.insert(last_brace_index, extra_method)
        text = '\n'.join(lines)
        
        with open('lib/widget/assign_task_sheet.dart', 'w', encoding='utf-8') as f:
            f.write(text)
        print("Fixed extra option item")
    else:
        print("Couldn't find the end of class")
else:
    print("Method already exists")
