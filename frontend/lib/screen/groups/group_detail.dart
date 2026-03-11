import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/group_provider.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupDetailScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().fetchGroupDetails(widget.groupId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.groupName)),
      body: Consumer<GroupProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final group = provider.selectedGroup;

          if (group == null) {
            return const Center(child: Text("Failed to load group details."));
          }

          final members = group.members ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display Details
                const Text(
                  "Description",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  group.description?.isNotEmpty == true
                      ? group.description!
                      : "No description provided.",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),

                // Members List
                Text(
                  "Members (${group.memberCount})",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (members.isEmpty)
                  const Text("No members found.")
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      // Members map format usually depends on your backend (e.g., {userId, role, firstName, lastName})
                      final name = member['firstName'] != null
                          ? "${member['firstName']} ${member['lastName'] ?? ''}"
                          : member['workEmail'] ?? "Unknown Member";

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(name[0].toUpperCase()),
                          ),
                          title: Text(name),
                          subtitle: Text(member['role'] ?? 'Member'),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
