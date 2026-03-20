with open('lib/widget/assign_task_sheet.dart', 'r', encoding='utf-8') as f:
    text = f.read()

import re

# Fix font sizes directly
old_desc = '''  Widget _buildDescField() {
    return TextFormField(
      controller: _descController,
      focusNode: _descFocus,
      minLines: 2,
      maxLines: 10,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF334155),
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: "Write task details, instructions or goals here...",
        hintStyle: TextStyle(
          fontSize: 15,
          color: Colors.blueGrey[300],
          height: 1.5,
          fontStyle: FontStyle.italic,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        isDense: true,
      ),
    );
  }'''

new_desc = '''  Widget _buildDescField() {
    return TextFormField(
      controller: _descController,
      focusNode: _descFocus,
      minLines: 2,
      maxLines: 10,
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF334155),
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: "Write task details, instructions or goals here...",
        hintStyle: TextStyle(
          fontSize: 11,
          color: Colors.blueGrey[300],
          height: 1.5,
          fontWeight: FontWeight.normal,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        isDense: true,
      ),
    );
  }'''

old_title = '''  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      focusNode: _titleFocus,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
      decoration: InputDecoration(
        hintText: "E.g. Design Homepage...",
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey[300],
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        isDense: true,
      ),
    );
  }'''

new_title = '''  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      focusNode: _titleFocus,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
      decoration: InputDecoration(
        hintText: "Add Task Title...",
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey[300],
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        isDense: true,
      ),
    );
  }'''

text = text.replace(old_desc, new_desc)
text = text.replace(old_title, new_title)

with open('lib/widget/assign_task_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(text)
