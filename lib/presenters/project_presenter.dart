import 'dart:io';
import 'package:project_tpm/models/ProjectModel.dart';
import 'package:project_tpm/network/base_network.dart';

abstract class ProjectView {
  void showLoading();
  void hideLoading();
  void showAllProjects(List<FundingProject> projects);
  void showAllLatestProjects(List<FundingProject> projects);
  void showParticipatedProjects(List<FundingProject> projects);
  void showAllProjectByUserId(List<FundingProject> projects);
  void projectById(FundingProject projects);
  void onDonateResult(bool success);
  void onCreateProjectResult(bool success);
  void onUpdateProjectResult(bool success);
  void showUserDonation(Map<String, dynamic> donationData);
  void onCancelProjectResult(bool success);
  void showError(String message);
}

class ProjectPresenter {
  final ProjectView view;

  ProjectPresenter(this.view);

  Future<void> fetchAllProjects() async {
    view.showLoading();
    try {
      final response = await BaseNetwork.getAllProjects();
      print("response all project in presenter : $response");
      final List<FundingProject> projects = (response['projects'] as List)
          .map((json) => FundingProject.fromJson(json))
          .toList();
      print("all project in presenter : $projects");
      view.showAllProjects(projects);
    } catch (e) {
      view.showError(e.toString());
    } finally {
      view.hideLoading();
    }
  }

  Future<void> fetchAllLatestProjects() async {
    view.showLoading();
    try {
      final response = await BaseNetwork.getLatestProject();
      print("response latest project in presenter : $response");
      final List<FundingProject> projects = (response['projects'] as List)
          .map((json) => FundingProject.fromJson(json))
          .toList();
      print("all latest project in presenter : $projects");
      view.showAllLatestProjects(projects);
    } catch (e) {
      view.showError(e.toString());
    } finally {
      view.hideLoading();
    }
  }

  Future<void> fetchAllProjectByUserId(int id) async {
    view.showLoading();
    try {
      final response = await BaseNetwork.getAllProjectByUserId(id);
      print("response user project in presenter : $response");
      final List<FundingProject> projects = (response['projects'] as List)
          .map((json) => FundingProject.fromJson(json))
          .toList();
      print("all user project in presenter : $projects");
      view.showAllProjectByUserId(projects);
    } catch (e) {
      view.showError(e.toString());
    } finally {
      view.hideLoading();
    }
  }

  Future<void> getProjectById(int id) async {
    view.showLoading();
    try {
      final response = await BaseNetwork.getProjectById(id);
      print("response details project in presenter : $response");
      final FundingProject data = FundingProject.fromJson(response['project']);
      print("all detail project in presenter : $data");
      view.projectById(data);
    } catch (e) {
      view.showError(e.toString());
    } finally {
      view.hideLoading();
    }
  }

  Future<void> fetchUserParticipatedProjects(int userId) async {
    view.showLoading();
    try {
      final response = await BaseNetwork.getUserParticipatedProjects(userId);
      print("response participated project in presenter : $response");
      final List<FundingProject> projects = (response['projects'] as List)
          .map((json) => FundingProject.fromJson(json))
          .toList();
      print("participated project in presenter : $projects");
      view.showParticipatedProjects(projects);
    } catch (e) {
      view.showError(e.toString());
    } finally {
      view.hideLoading();
    }
  }

  Future<void> donateToProject(int userId, int projectId, double amount) async {
    view.showLoading();
    try {
      final result = await BaseNetwork.donate(userId, projectId, amount);
      view.onDonateResult(result);
    } catch (e) {
      view.showError(e.toString());
    } finally {
      view.hideLoading();
    }
  }

  Future<void> fetchUserDonation(int userId, int projectId) async {
    view.showLoading();
    try {
      final result = await BaseNetwork.getUserDonation(userId, projectId);
      view.showUserDonation(result['data']);
    } catch (e) {
      view.showError(e.toString());
    } finally {
      view.hideLoading();
    }
  }

  Future<void> createProject({
    required File imageFile,
    required int userId,
    required String title,
    required String description,
    required double targetAmount,
    required String deadline,
    required double latitude,
    required double longitude,
  }) async {
    view.showLoading();
    try {
      final result = await BaseNetwork.createProjectWithImage(
        imageFile: imageFile,
        userId: userId,
        title: title,
        description: description,
        targetAmount: targetAmount,
        deadline: deadline,
        latitude: latitude,
        longitude: longitude,
      );
      view.onCreateProjectResult(result);
    } catch (e) {
      view.showError(e.toString());
    } finally {
      view.hideLoading();
    }
  }

  Future<void> updateProject({
    File? imageFile,
    required int userId,
    required int projectId,
    String? title,
    String? description,
    double? targetAmount,
    String? deadline,
    double? latitude,
    double? longitude,
    String? status
  }) async {
    view.showLoading();
    try {
      final result = await BaseNetwork.updateProjectWithImage(
        imageFile: imageFile,
        userId: userId,
        projectId: projectId,
        title: title,
        description: description,
        targetAmount: targetAmount,
        deadline: deadline,
        latitude: latitude,
        longitude: longitude,
        status: status
      );
      view.onUpdateProjectResult(result);
    } catch (e) {
      view.showError(e.toString());
    } finally {
      view.hideLoading();
    }
  }

  Future<void> cancelProject({
    required int userId,
    required int projectId,
  }) async {
    view.showLoading();
    try {
      final result = await BaseNetwork.cancelProject(
        userId: userId,
        projectId: projectId,
      );
      view.onCancelProjectResult(result);
    } catch (e) {
      view.showError(e.toString());
    } finally {
      view.hideLoading();
    }
  }
}
