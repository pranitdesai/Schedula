import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:schedula/Utils/app_color.dart';
import 'package:intl/intl.dart';

import '../custom_widget/snack_bar.dart';

class ManageProjectScreen extends StatefulWidget {
  const ManageProjectScreen({super.key});

  @override
  State<ManageProjectScreen> createState() => _ManageProjectScreenState();
}

/// simple model to represent a project loaded from Firebase
class Project {
  final String id;
  final String name;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;

  Project({
    required this.id,
    required this.name,
    required this.status,
    this.startDate,
    this.endDate,
  });
}

class _ManageProjectScreenState extends State<ManageProjectScreen> {
  final TextEditingController projectNameController = TextEditingController();
  String projectStatus = "pending";
  DateTime? startDate;
  DateTime? endDate;
  String? _nameError;

  // projects fetched from the database
  List<Project> _projects = [];
  bool _isEditing = false; // track whether sheet is in editing mode
  String? _editingProjectId;

  @override
  void dispose() {
    projectNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  static const _projectCardPadding = EdgeInsets.symmetric(horizontal: 18, vertical: 10);
  static const _projectCardInnerPadding = EdgeInsets.all(18);
  static const _iconSize = 28.0;
  static const _cardBorderRadius = 14.0;
  static const _modalBorderRadius = 20.0;

  Widget _projectCard({
    required String title,
    required String subtitle,
    required List<List<dynamic>> icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: _projectCardPadding,
        padding: _projectCardInnerPadding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_cardBorderRadius),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: HugeIcon(
                icon: icon,
                color: color,
                size: _iconSize,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey.shade400,
            )
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(
      bool isStartDate,
      Function(DateTime) onDateSelected,
      {DateTime? initialDate}
      ) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  void _openCreateProjectSheet() {
    _resetForm();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_modalBorderRadius),
        ),
      ),
      builder: (context) => _CreateProjectModal(
        projectNameController: projectNameController,
        projectStatus: projectStatus,
        startDate: startDate,
        endDate: endDate,
        nameError: _nameError,
        onStatusChanged: (value) {
          setState(() => projectStatus = value);
        },
        onStartDateSelected: (date) {
          setState(() => startDate = date);
        },
        onEndDateSelected: (date) {
          setState(() => endDate = date);
        },
        onSelectStartDate: () async {
          await _selectDate(true, (date) {
            setState(() => startDate = date);
          }, initialDate: startDate);
        },
        onSelectEndDate: () async {
          await _selectDate(false, (date) {
            setState(() => endDate = date);
          }, initialDate: endDate);
        },
        onNameChanged: (value) {
          setState(() {
            _nameError = null;
          });
        },
        onCreatePressed: _validateAndCreateProject,
        onSavePressed: _validateAndCreateProject,
      ),
    );
  }

  Future<void> _validateAndCreateProject() async {

    final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

    if (projectNameController.text.trim().isEmpty) {
      setState(() => _nameError = "Project name is required");
      return;
    }

    try {

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("User not logged in");
      }

      String projectId = dbRef
          .child("projects")
          .child(user.uid)
          .push()
          .key!;

      await dbRef
          .child("projects")
          .child(user.uid)
          .child(projectId)
          .set({
        "name": projectNameController.text.trim(),
        "status": projectStatus,
        "startDate": startDate?.toIso8601String(),
        "endDate": endDate?.toIso8601String(),
        "createdAt": DateTime.now().toIso8601String(),
      });

      Navigator.pop(context);
      _resetForm();
      await _loadProjects();

      CustomSnackBar.show(
          context,
          message: 'Project created successfully',
          type: SnackBarType.success,
          fromTop: false
      );
    } catch (e) {

      CustomSnackBar.show(
          context,
          message: 'Error creating project: $e',
          type: SnackBarType.error,
          fromTop: false
      );
    }
  }

  /// load all projects from Firebase for current user
  Future<void> _loadProjects() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref('projects/${user.uid}');
    final snapshot = await ref.get();
    final List<Project> list = [];

    if (snapshot.exists && snapshot.value != null) {
      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      data.forEach((key, value) {
        final map = Map<String, dynamic>.from(value as Map);
        list.add(Project(
          id: key,
          name: map['name'] ?? '',
          status: map['status'] ?? 'pending',
          startDate: map['startDate'] != null
              ? DateTime.parse(map['startDate'])
              : null,
          endDate: map['endDate'] != null
              ? DateTime.parse(map['endDate'])
              : null,
        ));
      });
    }

    setState(() {
      _projects = list;
    });
  }

  /// open bottom sheet for editing existing project
  void _openEditProjectSheet(Project project) {
    setState(() {
      _isEditing = true;
      _editingProjectId = project.id;
      projectNameController.text = project.name;
      projectStatus = project.status;
      startDate = project.startDate;
      endDate = project.endDate;
      _nameError = null;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(_modalBorderRadius),
        ),
      ),
      builder: (context) => _CreateProjectModal(
        projectNameController: projectNameController,
        projectStatus: projectStatus,
        startDate: startDate,
        endDate: endDate,
        nameError: _nameError,
        isEditing: true,
        onStatusChanged: (value) {
          setState(() => projectStatus = value);
        },
        onStartDateSelected: (date) {
          setState(() => startDate = date);
        },
        onEndDateSelected: (date) {
          setState(() => endDate = date);
        },
        onSelectStartDate: () async {
          await _selectDate(true, (date) {
            setState(() => startDate = date);
          }, initialDate: startDate);
        },
        onSelectEndDate: () async {
          await _selectDate(false, (date) {
            setState(() => endDate = date);
          }, initialDate: endDate);
        },
        onNameChanged: (value) {},
        onSavePressed: _validateAndUpdateProject,
      ),
    );
  }

  Future<void> _validateAndUpdateProject() async {
    if (_editingProjectId == null) return;

    final DatabaseReference dbRef = FirebaseDatabase.instance.ref();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      await dbRef
          .child("projects")
          .child(user.uid)
          .child(_editingProjectId!)
          .update({
        "status": projectStatus,
        "startDate": startDate?.toIso8601String(),
        "endDate": endDate?.toIso8601String(),
      });

      Navigator.pop(context);
      _resetForm();
      await _loadProjects();

      CustomSnackBar.show(
          context,
          message: 'Project updated successfully',
          type: SnackBarType.success,
          fromTop: false
      );
    } catch (e) {
      CustomSnackBar.show(
          context,
          message: 'Error updating project: $e',
          type: SnackBarType.error,
          fromTop: false
      );
    }
  }

  /// render a card-like entry for an existing project
  Widget _projectEntry(Project project) {
    String dateRange = '';
    if (project.startDate != null || project.endDate != null) {
      final start = project.startDate != null
          ? DateFormat('dd MMM yyyy').format(project.startDate!)
          : '';
      final end = project.endDate != null
          ? DateFormat('dd MMM yyyy').format(project.endDate!)
          : '';
      dateRange = '$start${start.isNotEmpty && end.isNotEmpty ? ' - ' : ''}$end';
    }

    return Container(
      margin: _projectCardPadding,
      padding: _projectCardInnerPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${project.status}${dateRange.isNotEmpty ? ' • $dateRange' : ''}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: AppColor.green700),
            onPressed: () => _openEditProjectSheet(project),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    projectNameController.clear();
    projectStatus = "pending";
    startDate = null;
    endDate = null;
    _nameError = null;
    _isEditing = false;
    _editingProjectId = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _projectCard(
                      title: "Create New Project",
                      subtitle: "Add a new project with start & end date",
                      icon: HugeIcons.strokeRoundedAddCircle,
                      color: Colors.green,
                      onTap: _openCreateProjectSheet,
                    ),
                    if (_projects.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          "No projects available",
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 14),
                        ),
                      )
                    else
                      ..._projects.map((p) => _projectEntry(p)).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Hero(
      tag: "manageProject",
      transitionOnUserGestures: true,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          height: 65,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Manage projects",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedFolderManagement,
                color: AppColor.green700,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateProjectModal extends StatefulWidget {
  final TextEditingController projectNameController;
  final String projectStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? nameError;
  final Function(String) onStatusChanged;
  final Function(DateTime) onStartDateSelected;
  final Function(DateTime) onEndDateSelected;
  final VoidCallback onSelectStartDate;
  final VoidCallback onSelectEndDate;
  final Function(String) onNameChanged;
  /// callback used when creating a brand new project (button labelled create)
  final VoidCallback? onCreatePressed;
  /// callback used when editing an existing project (button labelled update)
  final VoidCallback? onSavePressed;
  /// indicates the modal is being used for editing
  final bool isEditing;

  const _CreateProjectModal({
    required this.projectNameController,
    required this.projectStatus,
    required this.startDate,
    required this.endDate,
    required this.nameError,
    required this.onStatusChanged,
    required this.onStartDateSelected,
    required this.onEndDateSelected,
    required this.onSelectStartDate,
    required this.onSelectEndDate,
    required this.onNameChanged,
    this.onCreatePressed,
    this.onSavePressed,
    this.isEditing = false,
  });

  @override
  State<_CreateProjectModal> createState() => _CreateProjectModalState();
}

class _CreateProjectModalState extends State<_CreateProjectModal> {
  late FocusNode _nameFocusNode;

  @override
  void initState() {
    super.initState();
    _nameFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.isEditing ? "Edit Project" : "Create Project",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 28),
              _buildProjectNameField(),
              const SizedBox(height: 20),
              _buildStatusDropdown(),
              const SizedBox(height: 24),
              _buildDatePicker(
                title: "Start Date",
                date: widget.startDate,
                onTap: widget.onSelectStartDate,
              ),
              const SizedBox(height: 12),
              _buildDatePicker(
                title: "End Date",
                date: widget.endDate,
                onTap: widget.onSelectEndDate,
              ),
              const SizedBox(height: 32),
              _buildCreateButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.projectNameController,
          focusNode: _nameFocusNode,
          onChanged: widget.onNameChanged,
          enabled: !widget.isEditing,
          decoration: InputDecoration(
            labelText: "Project Name",
            hintText: "Enter project name",
            errorText: widget.nameError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColor.green700,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: widget.projectStatus,
      items: const [
        DropdownMenuItem(value: "pending", child: Text("Pending")),
        DropdownMenuItem(value: "in progress", child: Text("In Progress")),
        DropdownMenuItem(value: "completed", child: Text("Completed")),
      ],
      onChanged: (value) => widget.onStatusChanged(value ?? widget.projectStatus),
      decoration: InputDecoration(
        labelText: "Project Status",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColor.green700,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date == null
                      ? "Select date"
                      : DateFormat('dd MMM yyyy').format(date),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: AppColor.green700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.green700,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: widget.isEditing
            ? widget.onSavePressed
            : widget.onCreatePressed,
        child: Text(
          widget.isEditing ? "Update Project" : "Create Project",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
