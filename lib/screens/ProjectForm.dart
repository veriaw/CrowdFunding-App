import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:project_tpm/models/ProjectModel.dart';
import 'package:project_tpm/presenters/project_presenter.dart';
import 'package:project_tpm/screens/MainMenu.dart';
import 'package:intl/intl.dart';

class ProjectFormPage extends StatefulWidget {
  final bool isEdit;
  final FundingProject? project;
  final int userId;

  const ProjectFormPage({
    super.key,
    this.isEdit = false,
    this.project,
    required this.userId,
  });

  @override
  State<ProjectFormPage> createState() => _ProjectFormPageState();
}

class _ProjectFormPageState extends State<ProjectFormPage> implements ProjectView {
  final _formKey = GlobalKey<FormState>();
  late ProjectPresenter _presenter;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();
  final _deadlineController = TextEditingController();

  String? _errorMessage;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  LatLng? currentPosition;
  String _status = "active";
  DateTime? _selectedDeadline;

  @override
  void initState() {
    super.initState();
    _presenter = ProjectPresenter(this);
    _getCurrentLocation();

    if (widget.isEdit && widget.project != null) {
      final p = widget.project!;
      _titleController.text = p.title;
      _descriptionController.text = p.description;
      _targetController.text = p.targetAmount.toString();
      _deadlineController.text = DateFormat('yyyy-MM-dd').format(p.deadline);
      _status = p.status;

      try {
        _selectedDeadline = p.deadline;
      } catch (_) {
        _selectedDeadline = null;
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _errorMessage = "Permission lokasi ditolak.");
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      setState(() => _errorMessage = "Gagal mendapatkan lokasi: $e");
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (!widget.isEdit && _selectedImage == null) {
      showError("Gambar wajib diunggah saat membuat project.");
      return;
    }

    if (_selectedDeadline == null) {
      showError("Tanggal deadline belum dipilih.");
      return;
    }

    final projectData = FundingProject(
      projectId: widget.project?.projectId ?? 0,
      userId: widget.userId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      targetAmount: double.tryParse(_targetController.text.trim()) ?? 0,
      startDate: DateTime.now(),
      deadline: _selectedDeadline!,
      latitude: currentPosition?.latitude ?? 0,
      longitude: currentPosition?.longitude ?? 0,
      status: _status,
      imgUrl: widget.project?.imgUrl ?? '',
      totalDonations: 0,
    );

    String formattedDeadline = DateFormat('yyyy-MM-dd').format(projectData.deadline);

    if (widget.isEdit) {
      _presenter.updateProject(
        imageFile: _selectedImage,
        userId: widget.userId,
        projectId: widget.project!.projectId,
        title: projectData.title,
        description: projectData.description,
        targetAmount: projectData.targetAmount,
        deadline: formattedDeadline,
        status: projectData.status,
        latitude: widget.project!.latitude,
        longitude: widget.project!.longitude,
      );
    } else {
      _presenter.createProject(
        imageFile: _selectedImage!,
        userId: widget.userId,
        title: projectData.title,
        description: projectData.description,
        targetAmount: projectData.targetAmount,
        deadline: formattedDeadline,
        latitude: projectData.latitude,
        longitude: projectData.longitude,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Project' : 'Add Project'),
        backgroundColor: Colors.teal.shade600,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField("Title", _titleController),
                    _buildTextField("Description", _descriptionController, maxLines: 3),
                    _buildTextField("Target Amount", _targetController, keyboard: TextInputType.number),
                    TextFormField(
                      readOnly: true,
                      controller: _deadlineController,
                      decoration: InputDecoration(
                        labelText: "Deadline",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        DateTime now = DateTime.now();
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedDeadline ?? now,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365 * 5)),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _selectedDeadline = pickedDate;
                            _deadlineController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Deadline is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: InputDecoration(
                        labelText: "Project Status",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ["active", "finished", "canceled"].map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status[0].toUpperCase() + status.substring(1)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _status = value);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _selectedImage != null
                              ? Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity)
                              : widget.isEdit && widget.project?.imgUrl != ''
                                  ? Image.network(
                                      widget.project!.imgUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 60),
                                    )
                                  : const Center(child: Icon(Icons.image, size: 60, color: Colors.teal)),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text("Choose Image from Gallery"),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(widget.isEdit ? "Save Changes" : "Create Project"),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }

  @override
  void hideLoading() => setState(() => _isLoading = false);

  @override
  void showLoading() => setState(() => _isLoading = true);

  @override
  void onCreateProjectResult(bool success) {
    _handleResult(success, "Project created successfully", "Failed to create project");
  }

  @override
  void onUpdateProjectResult(bool success) {
    _handleResult(success, "Project updated successfully", "Failed to update project");
  }

  void _handleResult(bool success, String successMsg, String errorMsg) {
    final snackBar = SnackBar(content: Text(success ? successMsg : errorMsg));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainMenu()),
        (route) => false,
      );
    }
  }

  @override
  void showAllLatestProjects(List<FundingProject> projects) {}

  @override
  void showAllProjects(List<FundingProject> projects) {}

  @override
  void showParticipatedProjects(List<FundingProject> projects) {}

  @override
  void projectById(FundingProject projects) {}

  @override
  void showUserDonation(Map<String, dynamic> donationData) {}

  @override
  void onDonateResult(bool success) {}

  @override
  void showError(String message) {
    final snackBar = SnackBar(content: Text("Error: $message"));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  void onCancelProjectResult(bool success) {}
  
  @override
  void showAllProjectByUserId(List<FundingProject> projects) {
    // TODO: implement showAllProjectByUserId
  }
}
