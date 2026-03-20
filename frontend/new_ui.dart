  // --- Web-Matched UI --------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        constraints: BoxConstraints(maxHeight: size.height * 0.95),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildWebHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleField(),
                      const SizedBox(height: 10),
                      _buildDescField(),
                      const SizedBox(height: 20),
                      
                      // ADD CHECKLIST
                      GestureDetector(
                        onTap: () => setState(() => _showChecklist = !_showChecklist),
                        child: Row(
                          children: [
                            const Icon(Icons.add, color: Color(0xFF10B981), size: 18),
                            const SizedBox(width: 4),
                            const Text("ADD CHECKLIST", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                            const Spacer(),
                            Icon(_showChecklist ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey, size: 20)
                          ],
                        ),
                      ),
                      if (_showChecklist) ...[
                        const SizedBox(height: 16),
                        _buildChecklistSection(),
                      ],
                      const SizedBox(height: 24),

                      // ROW OF CHIPS
                      _buildWebChipsRow(),

                      const SizedBox(height: 24),
                      _buildRepeatSection(),

                      const SizedBox(height: 24),
                      if (_attachedFiles.isNotEmpty) _buildAttachmentsRow(),
                      if (_reminderDateTime != null) _buildReminderChip(),
                      if (_isRecording || _recordedPath != null) _buildRecordingBar(),
                      
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
            _buildWebFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildWebHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF0FDF4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.add, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Assign New Task", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A))),
              Text("NEW DELEGATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF10B981), letterSpacing: 1.2)),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      focusNode: _titleFocus,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey[700]),
      decoration: InputDecoration(
        hintText: "Add Task Title...",
        hintStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey[300]),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    );
  }

  Widget _buildDescField() {
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
  }

  Widget _buildChecklistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _checklistController,
                decoration: InputDecoration(
                  hintText: 'Add an item...',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF10B981))),
                ),
                onFieldSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    setState(() {
                      _checklist.add(v.trim());
                      _checklistController.clear();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                if (_checklistController.text.trim().isNotEmpty) {
                  setState(() {
                    _checklist.add(_checklistController.text.trim());
                    _checklistController.clear();
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        if (_checklist.isNotEmpty) const SizedBox(height: 12),
        ..._checklist.asMap().entries.map((e) {
          int idx = e.key;
          String item = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.check_box_outline_blank, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(item, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _checklist.removeAt(idx)),
                )
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWebChipsRow() {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final userProv = Provider.of<UserProvider>(context, listen: false);
    final currentUser = authProv.currentUser;

    List<UserModel> allowedUsers = userProv.users;
    if (currentUser != null && !authProv.isAdmin) {
      if (authProv.currentUser?.role?.toLowerCase() == 'manager') {
        allowedUsers = userProv.users.where((u) => u.role.toLowerCase() == 'manager' || u.role.toLowerCase() == 'user' || u.id == currentUser.id).toList();
      } else {
        allowedUsers = userProv.users.where((u) => u.role.toLowerCase() == 'user' || u.id == currentUser.id).toList();
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildWebChip(
            icon: Icons.person_outline,
            label: _selectedDoer != null ? "ASSIGNEE" : "ASSIGNEE",
            value: _selectedDoer?.fullName,
            onTap: () => _showUserPicker(allowedUsers, isInLoop: false),
          ),
          _buildWebChip(
            icon: Icons.calendar_today_outlined,
            label: "DUE DATE",
            value: _endDate != null ? DateFormat('MMM dd').format(_endDate!) : null,
            onTap: () => _pickDate(false),
          ),
          _buildWebChip(
            icon: Icons.flag_outlined,
            label: _priority.toUpperCase(),
            isFilled: true,
            color: _priorityColor(_priority),
            onTap: () => _showPriorityPicker(),
          ),
          _buildWebChip(
            icon: Icons.check_box_outlined,
            label: "CATEGORY",
            value: _category,
            onTap: () => _showCategoryPicker(),
          ),
          _buildWebChip(
            icon: Icons.group_outlined,
            label: "IN LOOP",
            value: _selectedInLoop.isNotEmpty ? "\ Added" : null,
            onTap: () => _showUserPicker(allowedUsers, isInLoop: true),
          ),
          _buildWebChip(
            icon: Icons.upload_file,
            label: "EVIDENCE",
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Evidence required logic can be added here.")));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWebChip({required IconData icon, required String label, String? value, bool isFilled = false, Color? color, VoidCallback? onTap}) {
    Color baseColor = color ?? Colors.grey[700]!;
    bool hasValue = value != null && value.isNotEmpty;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isFilled ? baseColor.withOpacity(0.1) : Colors.white,
          border: Border.all(color: isFilled || hasValue ? baseColor : Colors.grey[300]!, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isFilled || hasValue ? baseColor : Colors.grey[500]),
            const SizedBox(width: 6),
            if (hasValue)
               Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: baseColor))
            else
               Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isFilled ? baseColor : Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return const Color(0xFFEF4444);
      case 'medium': return const Color(0xFFF59E0B);
      case 'low': return const Color(0xFF10B981);
      default: return Colors.grey;
    }
  }

  Widget _buildRepeatSection() {
    return GestureDetector(
      onTap: () {
        setState(() => _repeat = !_repeat);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!, width: 1.5),
          borderRadius: BorderRadius.circular(16)
        ),
        child: Row(
          children: [
            Icon(_repeat ? Icons.radio_button_checked : Icons.radio_button_off, color: _repeat ? const Color(0xFF10B981) : Colors.grey[400], size: 20),
            const SizedBox(width: 10),
            Text("REPEAT", style: TextStyle(fontWeight: FontWeight.bold, color: _repeat ? const Color(0xFF10B981) : Colors.blueGrey[400], letterSpacing: 0.5)),
            const Spacer(),
            if (_repeat) 
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _repeatFrequency,
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  items: const ['Daily', 'Weekly', 'Monthly', 'Yearly'].map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _repeatFrequency = v);
                  },
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildWebFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          _buildFooterIconBtn(icon: Icons.attach_file, color: Colors.grey[600]!, onTap: _pickFiles, badge: _attachedFiles.isNotEmpty ? _attachedFiles.length.toString() : null),
          const SizedBox(width: 4),
          _buildFooterIconBtn(
             icon: Icons.access_time, 
             color: _reminderDateTime != null ? const Color(0xFF10B981) : Colors.grey[600]!, 
             onTap: _showReminderPicker,
             badge: _reminderDateTime != null ? "?" : null
          ),
          const SizedBox(width: 4),
          _buildFooterIconBtn(
             icon: _isRecording ? Icons.stop_circle : Icons.mic_none, 
             color: _isRecording ? Colors.red : (_recordedPath != null ? const Color(0xFF10B981) : Colors.grey[600]!), 
             onTap: _isRecording ? _stopRecording : _startRecording,
          ),
          const SizedBox(width: 4),
          _buildFooterIconBtn(icon: Icons.more_horiz, color: Colors.grey[600]!, onTap: () {}),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _handleAssign,
            icon: _isSubmitting 
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.upload_rounded, size: 18, color: Colors.white),
            label: Text(_isSubmitting ? "ASSIGNING..." : "ASSIGN TASK", style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 0,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFooterIconBtn({required IconData icon, required Color color, required VoidCallback onTap, String? badge}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10)
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            if (badge != null)
              Positioned(
                top: 4, right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                  child: Text(badge, style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
          ],
        ),
      ),
    );
  }

