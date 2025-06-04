import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:project_tpm/models/ProjectModel.dart';
import 'package:project_tpm/models/user.dart';
import 'package:project_tpm/presenters/project_presenter.dart';
import 'package:project_tpm/screens/DetailProject.dart';
import 'package:project_tpm/screens/EditProfile.dart';
import 'package:project_tpm/screens/Login.dart';
import 'package:project_tpm/shared/color_palette.dart';
import 'package:project_tpm/utils/handle_image_profile.dart';

class MainMenu extends StatefulWidget {
  final User user;
  const MainMenu({super.key, required this.user});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> implements ProjectView {
  int currentPageIndex = 0;
  late ProjectPresenter _presenter;
  bool _isLoading = false;
  String? _errorMessage;
  List<FundingProject> allProjectList = [];
  List<FundingProject> participatedProjects = [];
  List<FundingProject> filteredProjects = [];
  LatLng? currentPosition;
  FundingProject? selectedProject;
  File? _profileImage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _presenter = ProjectPresenter(this);
    showLoading();
    _getCurrentLocation();
    _presenter.fetchAllProjects();
    _presenter.fetchUserParticipatedProjects(widget.user.id!);
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final image = await ProfileImageHelper.loadProfileImage(widget.user.id!);
    setState(() => _profileImage = image);
  }

  void searchProject(String enteredKeyword) {
    if (enteredKeyword.isEmpty) {
      // Kalau kosong, misal ingin tampil semua data
      setState(() {
        filteredProjects = [];
      });
    } else {
      final results = allProjectList.where((project) {
        final titleLower = project.title.toLowerCase();
        final searchLower = enteredKeyword.toLowerCase();
        return titleLower.contains(searchLower);
      }).toList();

      setState(() {
        filteredProjects = results;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Main Menu"),
        backgroundColor: secondaryColor,
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
          if (index == 0) {
            _presenter.fetchAllProjects();
          } else if (index == 1) {
            _presenter.fetchUserParticipatedProjects(widget.user.id!);
          } else if (index == 2) {
            _getCurrentLocation();
          } else {
            print("Belum ada apa apa!");
          }
        },
        indicatorColor: secondaryColor,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(
              Icons.home_outlined,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Participated',
          ),
          NavigationDestination(
            icon: Icon(Icons.maps_home_work),
            label: 'Maps',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_pin),
            label: 'User Profile',
          ),
        ],
      ),
      body: <Widget>[
        // index 0
        SingleChildScrollView(
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Cari Project',
                      hintText: 'Masukkan kata kunci...',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () {
                          searchProject(_searchController.text);
                        },
                      ),
                    ),
                    onChanged: (value) {
                      // Optional: lakukan pencarian langsung saat mengetik
                      searchProject(value);
                    },
                    onSubmitted: (value) {
                      searchProject(value);
                    },
                  ),
                  SizedBox(height: 20),
                  filteredProjects.isEmpty
                  ? SizedBox.shrink()
                  : SizedBox(
                    height: 262,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredProjects.length,
                      itemBuilder: (context, index) {
                        final project = filteredProjects[index];
                        final currentAmount = project.totalDonations ?? 0.0;
                        final targetAmount = project.targetAmount ?? 1.0;
                        final progress =
                            (currentAmount / targetAmount).clamp(0.0, 1.0);

                        return Container(
                          width: 220,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 10.0),
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
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Gambar Project
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                    child: Image.network(
                                      project.imgUrl ?? '',
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        height: 120,
                                        color: Colors.grey[300],
                                        child:
                                            Icon(Icons.broken_image, size: 40),
                                      ),
                                    ),
                                  ),
                                  // Title
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      project.title ?? 'No Title',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Description (short)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Text(
                                      project.description ??
                                          'No description available.',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ),
                                  // Progress bar
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 4),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 8,
                                        backgroundColor: Colors.grey[300],
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.green),
                                      ),
                                    ),
                                  ),
                                  // Funding info
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Text(
                                      '${(progress * 100).toStringAsFixed(1)}% funded',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.green),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 4.0),
                                    child: Text(
                                      'Status : ${project.status}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: project.status.toLowerCase() ==
                                                'active'
                                            ? Colors.blue
                                            : project.status.toLowerCase() ==
                                                    'canceled'
                                                ? Colors.orange
                                                : project.status
                                                            .toLowerCase() ==
                                                        'finish'
                                                    ? Colors.green
                                                    : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "Latest Fundings",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 262,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: allProjectList.length,
                itemBuilder: (context, index) {
                  final project = allProjectList[index];
                  final currentAmount = project.totalDonations ?? 0.0;
                  final targetAmount = project.targetAmount ?? 1.0;
                  final progress =
                      (currentAmount / targetAmount).clamp(0.0, 1.0);

                  return Container(
                    width: 220,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 10.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DetailFundingProject(
                                  id: project.projectId, user: widget.user)),
                        );
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Gambar Project
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: Image.network(
                                project.imgUrl ?? '',
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.broken_image, size: 40),
                                ),
                              ),
                            ),
                            // Title
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                project.title ?? 'No Title',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Description (short)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                project.description ??
                                    'No description available.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ),
                            // Progress bar
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.green),
                                ),
                              ),
                            ),
                            // Funding info
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                '${(progress * 100).toStringAsFixed(1)}% funded',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.green),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 4.0),
                              child: Text(
                                'Status : ${project.status}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      project.status.toLowerCase() == 'active'
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
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Text(
              "All Fundings",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 394,
              child: ListView.builder(
                itemCount: allProjectList.length,
                itemBuilder: (context, index) {
                  final project = allProjectList[index];
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
                                  id: project.projectId, user: widget.user)),
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
            ),
          ],
        ),
        ),

        // index 1
        Column(
          children: [
            SizedBox(
              height: 696,
              child: ListView.builder(
                itemCount: participatedProjects.length,
                itemBuilder: (context, index) {
                  final project = participatedProjects[index];
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
                                  id: project.projectId, user: widget.user)),
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

        // index 2
        Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: currentPosition == null
                      ? Center(child: CircularProgressIndicator())
                      : FlutterMap(
                          options: MapOptions(
                            initialCenter: currentPosition!,
                            initialZoom: 13,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                              subdomains: ['a', 'b', 'c'],
                              userAgentPackageName: 'com.example.app',
                            ),
                            MarkerLayer(
                              markers: [
                                // Marker user
                                Marker(
                                  point: currentPosition!,
                                  width: 60,
                                  height: 60,
                                  child: Icon(Icons.person_pin_circle,
                                      color: Colors.blue, size: 40),
                                ),
                                // Marker project
                                ...allProjectList.map((project) => Marker(
                                      point: LatLng(
                                          project.latitude, project.longitude),
                                      width: 60,
                                      height: 60,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedProject = project;
                                          });
                                        },
                                        child: Icon(Icons.location_on,
                                            color: Colors.red, size: 40),
                                      ),
                                    )),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            ),

            // Card detail project
            if (selectedProject != null)
              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    print("Cetak Kartu Map");
                  },
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              selectedProject!.imgUrl.isNotEmpty
                                  ? selectedProject!.imgUrl
                                  : 'https://via.placeholder.com/100',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[300],
                                child: Icon(Icons.broken_image, size: 40),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedProject!.title,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  selectedProject!.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14),
                                ),
                                SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: (selectedProject!.totalDonations /
                                            selectedProject!.targetAmount)
                                        .clamp(0.0, 1.0),
                                    minHeight: 8,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.green),
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  '${(selectedProject!.totalDonations / selectedProject!.targetAmount * 100).toStringAsFixed(1)}% funded • Rp.${selectedProject!.totalDonations.toStringAsFixed(2)} dari Rp.${selectedProject!.targetAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
          ],
        ),

        // index 3
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.all(10),
              child: SizedBox(
                  width: 600,
                  height: 500,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                    margin: EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: _profileImage != null
                                    ? FileImage(_profileImage!)
                                    : null,
                                child: _profileImage == null
                                    ? Icon(
                                        Icons.person,
                                        size: 48,
                                        color: Colors.grey[700],
                                      )
                                    : null,
                              ),
                              SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.user.username,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    _buildLabelValue('Gender',
                                        widget.user.gender ?? 'Not specified'),
                                    SizedBox(height: 12),
                                    _buildLabelValue(
                                      'Date of Birth',
                                      widget.user.dateOfBirth != null
                                          ? '${widget.user.dateOfBirth!.toLocal().toString().split(' ')[0]}'
                                          : 'Not specified',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 32),
                          Divider(thickness: 1.5),
                          SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfilePage(
                                      user: widget.user,
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(Icons.edit, size: 20),
                              label: Text('Edit Profile'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Colors.blue,
                                foregroundColor: primaryColor,
                                textStyle: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                                elevation: 5,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginPage(),
                                  ),
                                );
                              },
                              icon: Icon(Icons.logout, size: 20),
                              label: Text('Logout'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Colors.redAccent,
                                foregroundColor: primaryColor,
                                textStyle: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                                elevation: 5,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Pesan & Kesan TPM",
                            textAlign: TextAlign.justify,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                              "Deadline datang kayak hantu, errornya kayak monster ga pernah abis. Pokoknya, TPM ngajarin satu hal: siap-siap ora turu!",
                              textAlign: TextAlign.justify)
                        ],
                      ),
                    ),
                  )),
            )
          ],
        )
      ][currentPageIndex],
    );
  }

  // Helper widget buat label dan value
  Widget _buildLabelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  void hideLoading() {
    setState(() {
      _isLoading = false;
    });
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
  void showAllProjects(List<FundingProject> projects) {
    setState(() {
      allProjectList = projects;
    });
  }

  @override
  void showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  @override
  void showLoading() {
    setState(() {
      _isLoading = true;
    });
  }

  @override
  void showParticipatedProjects(List<FundingProject> projects) {
    setState(() {
      participatedProjects = projects;
    });
  }

  @override
  void showUserDonation(Map<String, dynamic> donationData) {
    // TODO: implement showUserDonation
  }

  @override
  void projectById(FundingProject projects) {
    // TODO: implement projectById
  }

  @override
  void showAllLatestProjects(List<FundingProject> projects) {
    // TODO: implement showAllLatestProjects
  }
}
