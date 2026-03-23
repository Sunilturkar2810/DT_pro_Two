import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/notification_provider.dart';
import '../../../widget/shimmer_loading.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              context.read<NotificationProvider>().markAllAsRead();
            },
          )
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const ShimmerListLoading();
          }

          if (provider.notifications.isEmpty) {
            return const Center(child: Text("You have no notifications."));
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: RefreshIndicator(
                onRefresh: () async {
                  await context.read<NotificationProvider>().fetchNotifications();
                },
                child: ListView.builder(
                  itemCount: provider.notifications.length,
                  itemBuilder: (context, index) {
                final notif = provider.notifications[index];
                return Container(
                  color: notif.isRead ? Colors.transparent : Colors.green.withOpacity(0.1),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Icon(
                        notif.type == 'overdue' ? Icons.warning :
                        notif.type == 'status_changed' ? Icons.update :
                        notif.type == 'remark_added' ? Icons.comment :
                        Icons.notifications,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(notif.message, style: TextStyle(
                      fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                    )),
                    subtitle: Text(notif.createdAt, style: const TextStyle(fontSize: 12)),
                    onTap: () {
                      if (!notif.isRead) {
                        provider.markOneAsRead(notif.id);
                      }
                    },
                  ),
                );
              },
                          ),
              ),
        ));
        },
      ),
    );
  }
}
