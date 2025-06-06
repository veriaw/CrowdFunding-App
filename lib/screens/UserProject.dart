import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:project_tpm/models/ProjectModel.dart';
import 'package:project_tpm/models/user.dart';
import 'package:project_tpm/presenters/project_presenter.dart';
import 'package:project_tpm/screens/DetailProject.dart';
import 'package:project_tpm/shared/color_palette.dart';

class UserProject extends StatefulWidget {
  final User user;
  const UserProject({super.key, required this.user});

  @override
  State<UserProject> createState() => _UserProjectState();
}

class _UserProjectState extends State<UserProject> implements ProjectView {
  late ProjectPresenter _presenter;
  List<FundingProject> allUserProjects = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _presenter = ProjectPresenter(this);
    _presenter.fetchAllProjectByUserId(widget.user.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Main Menu"),
        backgroundColor: secondaryColor,
      ),
      body: Column(
          children: [
            Text(
                "User Funding Projects",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            SizedBox(
              height: 696,
              child: ListView.builder(
                itemCount: allUserProjects.length,
                itemBuilder: (context, index) {
                  final project = allUserProjects[index];
                  final currentAmount = project.totalDonations ?? 0.0;
                  final targetAmount = project.targetAmount ?? 1.0;
                  final progress =
                      (currentAmount / targetAmount).clamp(0.0, 1.0);

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DetailFundingProject(
                                  id: project.projectId,
                                  user: widget.user)),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Gambar di kiri
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                project.imgUrl ?? '',
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 120,
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.broken_image, size: 40),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            // Informasi di kanan
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    project.title ?? 'No Title',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    project.description ??
                                        'No description available.',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.green),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${(progress * 100).toStringAsFixed(1)}% funded • \Rp.${currentAmount.toStringAsFixed(2)} raised of \Rp.${targetAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Status : ${project.status}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: project.status.toLowerCase() ==
                                              'active'
                                          ? Colors.blue
                                          : project.status.toLowerCase() ==
                                                  'canceled'
                                              ? Colors.orange
                                              : project.status.toLowerCase() ==
                                                      'finish'
                                                  ? Colors.green
                                                  : Colors.grey,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
    );
  }

  @override
  void hideLoading() {
    // TODO: implement hideLoading
  }

  @override
  void onCancelProjectResult(bool success) {
    // TODO: implement onCancelProjectResult
  }

  @override
  void onCreateProjectResult(bool success) {
    // TODO: implement onCreateProjectResult
  }

  @override
  void onDonateResult(bool success) {
    // TODO: implement onDonateResult
  }

  @override
  void onUpdateProjectResult(bool success) {
    // TODO: implement onUpdateProjectResult
  }

  @override
  void projectById(FundingProject projects) {
    // TODO: implement projectById
  }

  @override
  void showAllLatestProjects(List<FundingProject> projects) {
    // TODO: implement showAllLatestProjects
  }

  @override
  void showAllProjectByUserId(List<FundingProject> projects) {
    setState(() {
      allUserProjects = projects;
    });
  }

  @override
  void showAllProjects(List<FundingProject> projects) {
    // TODO: implement showAllProjects
  }

  @override
  void showError(String message) {
    // TODO: implement showError
  }

  @override
  void showLoading() {
    // TODO: implement showLoading
  }

  @override
  void showParticipatedProjects(List<FundingProject> projects) {
    // TODO: implement showParticipatedProjects
  }

  @override
  void showUserDonation(Map<String, dynamic> donationData) {
    // TODO: implement showUserDonation
  }
}