class FundingProject {
  final int projectId;
  final int userId;
  final String title;
  final String description;
  final double targetAmount;
  final DateTime startDate;
  final DateTime deadline;
  final double latitude;
  final double longitude;
  final String status;
  final String imgUrl;
  final double totalDonations;

  FundingProject({
    required this.projectId,
    required this.userId,
    required this.title,
    required this.description,
    required this.targetAmount,
    required this.startDate,
    required this.deadline,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.imgUrl,
    required this.totalDonations,
  });

  factory FundingProject.fromJson(Map<String, dynamic> json) {
    return FundingProject(
      projectId: json['project_id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      targetAmount: double.parse(json['target_amount']),
      startDate: DateTime.parse(json['start_date']),
      deadline: DateTime.parse(json['deadline']),
      latitude: double.parse(json['latitude']),
      longitude: double.parse(json['longitude']),
      status: json['status'] as String,
      imgUrl: json['img_url'] as String,
      totalDonations: double.parse(json['total_donations']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'user_id': userId,
      'title': title,
      'description': description,
      'target_amount': targetAmount.toStringAsFixed(2),
      'start_date': startDate.toIso8601String(),
      'deadline': deadline.toIso8601String(),
      'latitude': latitude.toStringAsFixed(8),
      'longitude': longitude.toStringAsFixed(8),
      'status': status,
      'img_url': imgUrl,
      'total_donations': totalDonations.toStringAsFixed(2),
    };
  }
}