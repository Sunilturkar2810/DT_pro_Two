import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/group_provider.dart';
import '../../../provider/user_provider.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  List<String> _selectedMemberIds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
  }

  void _submitGroup() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedMemberIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one member')),
        );
        return;
      }

      final provider = Provider.of<GroupProvider>(context, listen: false);
      final success = await provider.createGroup(
        _nameController.text.trim(),
        _descController.text.trim(),
        _selectedMemberIds,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group created successfully!')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Error creating group')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<GroupProvider>().isLoading;
    final userProvider = context.watch<UserProvider>();
    final allUsers = userProvider.users;

    return Scaffold(
      appBar: AppBar(title: const Text('Create New Group')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Group Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('Add Members', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  if (userProvider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (allUsers.isEmpty)
                    const Center(child: Text("No users found"))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: allUsers.length,
                      itemBuilder: (context, index) {
                        final user = allUsers[index];
                        final isSelected = _selectedMemberIds.contains(user.id);

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: CheckboxListTile(
                            title: Text("${user.firstName} ${user.lastName}"),
                            subtitle: Text("${user.designation} | ${user.department}"),
                            secondary: CircleAvatar(
                              child: Text(user.firstName[0].toUpperCase()),
                            ),
                            value: isSelected,
                            onChanged: (bool? val) {
                              setState(() {
                                if (val == true) {
                                  _selectedMemberIds.add(user.id);
                                } else {
                                  _selectedMemberIds.remove(user.id);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submitGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF20E19F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                          'CREATE GROUP',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

