import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/group_provider.dart';
import '../../../widget/shimmer_loading.dart';
import 'create_group.dart';
import 'group_detail.dart';

class MyGroupsScreen extends StatefulWidget {
  const MyGroupsScreen({Key? key}) : super(key: key);

  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().fetchMyGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Groups')),
      body: Consumer<GroupProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.myGroups.isEmpty) {
            return const ShimmerListLoading();
          }

          if (provider.myGroups.isEmpty) {
            return const Center(child: Text("You are not part of any groups yet."));
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: RefreshIndicator(
                onRefresh: () async {
                  await context.read<GroupProvider>().fetchMyGroups();
                },
                child: ListView.builder(
                  itemCount: provider.myGroups.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                final group = provider.myGroups[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.group)),
                    title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${group.memberCount} Members"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupDetailScreen(
                            groupId: group.id,
                            groupName: group.name,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
                          ),
              ),
        ));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen())),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.group_add),
      ),
    );
  }
}
