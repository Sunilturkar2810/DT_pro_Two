import 'package:d_table_delegate_system/model/user_model.dart';

class RemarkModel {
  final String id;
  final String remark;
  final String date;
  final String assignedUserId;

  RemarkModel({
    required this.id,
    required this.remark,
    required this.date,
    required this.assignedUserId,
  });

  factory RemarkModel.fromJson(Map<String, dynamic> json) {
    return RemarkModel(
      id: json['id']?.toString() ?? '',
      remark: json['remark'] ?? '',
      date: json['createdAt'] ?? json['date'] ?? '',
      // Backend stores as 'userId', fallback to old keys for safety
      assignedUserId: json['userId'] ?? json['assignedUserId'] ?? json['assigned_user_id'] ?? '',
    );
  }
}

class DelegationModel {
  String? id;
  String delegationName;
  String description;
  String delegatorId;
  String assingDoerId;
  String priority;
  String dueDate;
  String status;
  String department;
  bool evidenceRequired;
  List<RemarkModel> remarks;

  // Additional fields from backend
  List<String> inLoopIds;
  String category;
  bool isRepeat;
  String? repeatFrequency;
  String? repeatStartDate;
  String? repeatEndDate;
  String? asset;
  List<Map<String, dynamic>> checklistItems;

  // Media & references
  String? voiceNoteUrl;       // uploaded voice recording URL
  List<String> referenceDocs; // uploaded attachment URLs
  String? reminderAt;         // ISO string of reminder time (stored in tags)

  // Backend se directly aane wale names (list API se)
  String delegatorName;
  String assigneeName;

  DelegationModel({
    this.id,
    required this.delegationName,
    required this.description,
    required this.delegatorId,
    required this.assingDoerId,
    required this.priority,
    required this.dueDate,
    this.status = "Pending",
    this.department = "General",
    this.evidenceRequired = false,
    this.remarks = const [],
    this.inLoopIds = const [],
    this.category = "General",
    this.isRepeat = false,
    this.repeatFrequency,
    this.repeatStartDate,
    this.repeatEndDate,
    this.checklistItems = const [],
    this.delegatorName = '',
    this.assigneeName = '',
    this.asset,
    this.voiceNoteUrl,
    this.referenceDocs = const [],
    this.reminderAt,
  });

  factory DelegationModel.fromJson(Map<String, dynamic> json) {
    var list = json['remarks'] as List? ?? [];
    List<RemarkModel> remarksList =
        list.map((i) => RemarkModel.fromJson(i as Map<String, dynamic>)).toList();

    var inLoop = json['inLoopIds'] ?? json['in_loop_ids'] as List? ?? [];
    List<String> inLoopList = (inLoop is List) ? inLoop.map((i) => i.toString()).toList() : [];

    var checklist = json['checklistItems'] ?? json['checklist_items'] as List? ?? [];
    List<Map<String, dynamic>> checklistItemsList =
        (checklist is List) ? checklist.map((i) => i as Map<String, dynamic>).toList() : [];

    // Backend se direct names parse karo
    final delegatorFirst = json['delegatorFirstName'] ?? json['delegator_first_name'] ?? '';
    final delegatorLast = json['delegatorLastName'] ?? json['delegator_last_name'] ?? '';
    final assigneeFirst = json['assigneeFirstName'] ?? json['assignee_first_name'] ?? '';
    final assigneeLast = json['assigneeLastName'] ?? json['assignee_last_name'] ?? '';

    // Parse referenceDocs — stored as JSON string or list
    List<String> refDocsList = [];
    final rawRefDocs = json['referenceDocs'] ?? json['reference_docs'];
    if (rawRefDocs is List) {
      refDocsList = rawRefDocs.map((e) => e.toString()).toList();
    } else if (rawRefDocs is String && rawRefDocs.isNotEmpty) {
      try {
        final decoded = rawRefDocs.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        refDocsList = decoded;
      } catch (_) {}
    }

    // Parse reminderAt from tags jsonb
    String? reminderAt;
    final rawTags = json['tags'];
    if (rawTags is Map) {
      reminderAt = rawTags['reminderAt']?.toString();
    }

    return DelegationModel(
      id: json['id']?.toString(),
      delegationName: json['taskTitle'] ?? json['task_title'] ?? json['delegationName'] ?? json['delegation_name'] ?? '',
      description: json['description'] ?? '',
      delegatorId: json['assignerId'] ?? json['assigner_id'] ?? json['delegatorId'] ?? json['delegator_id'] ?? '',
      assingDoerId: json['doerId'] ?? json['doer_id'] ?? json['assingDoerId'] ?? json['assing_doer_id'] ?? '',
      priority: json['priority'] ?? 'Medium',
      dueDate: json['dueDate'] ?? json['due_date'] ?? '',
      status: json['status'] ?? 'Pending',
      department: json['department'] ?? 'General',
      evidenceRequired: json['evidenceRequired'] == true || json['evidence_required'] == true || json['evidenceRequired'] == 1 || json['evidence_required'] == 1,
      remarks: remarksList,
      inLoopIds: inLoopList,
      category: json['category'] ?? 'General',
      isRepeat: json['isRepeat'] == true || json['is_repeat'] == true || json['isRepeat'] == 1 || json['is_repeat'] == 1,
      repeatFrequency: json['repeatFrequency'] ?? json['repeat_frequency'],
      repeatStartDate: json['repeatStartDate'] ?? json['repeat_start_date'],
      repeatEndDate: json['repeatEndDate'] ?? json['repeat_end_date'],
      checklistItems: checklistItemsList,
      delegatorName: '$delegatorFirst $delegatorLast'.trim(),
      assigneeName: '$assigneeFirst $assigneeLast'.trim(),
      asset: json['asset'],
      voiceNoteUrl: json['voiceNoteUrl'] ?? json['voice_note_url'],
      referenceDocs: refDocsList,
      reminderAt: reminderAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "taskTitle": delegationName,
      "description": description,
      "assignerId": delegatorId,
      "doerId": assingDoerId,
      "priority": priority,
      "dueDate": dueDate,
      "status": status,
      "department": department,
      "evidenceRequired": evidenceRequired,
      "inLoopIds": inLoopIds,
      "category": category,
      "isRepeat": isRepeat,
      "repeatFrequency": repeatFrequency,
      "repeatStartDate": repeatStartDate,
      "repeatEndDate": repeatEndDate,
      "checklistItems": checklistItems,
      "asset": asset,
      if (voiceNoteUrl != null) "voiceNoteUrl": voiceNoteUrl,
      if (referenceDocs.isNotEmpty) "referenceDocs": referenceDocs.join(','),
      if (reminderAt != null) "tags": {"reminderAt": reminderAt},
    };
  }

  // Backend se naam directly use karo, fallback users list se
  String getAssignedToName(List<UserModel> users) {
    if (assigneeName.isNotEmpty) return assigneeName;
    try {
      return users.firstWhere((u) => u.id == assingDoerId).fullName;
    } catch (e) {
      return assingDoerId;
    }
  }

  String getAssignedByName(List<UserModel> users) {
    if (delegatorName.isNotEmpty) return delegatorName;
    try {
      return users.firstWhere((u) => u.id == delegatorId).fullName;
    } catch (e) {
      return delegatorId;
    }
  }
}
