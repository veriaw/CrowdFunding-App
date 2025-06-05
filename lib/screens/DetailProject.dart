import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project_tpm/models/ProjectModel.dart';
import 'package:project_tpm/models/user.dart';
import 'package:project_tpm/presenters/project_presenter.dart';
import 'package:project_tpm/screens/MainMenu.dart';
import 'package:project_tpm/screens/ProjectForm.dart';
import 'package:project_tpm/services/route_service.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailFundingProject extends StatefulWidget {
  final int id;
  final User user;

  const DetailFundingProject({super.key, required this.id, required this.user});

  @override
  State<DetailFundingProject> createState() => _DetailFundingProjectState();
}

class _DetailFundingProjectState extends State<DetailFundingProject>
    implements ProjectView {
  LatLng? currentPosition;
  List<LatLng> routePlace = [];
  late ProjectPresenter _presenter;
  bool _isLoading = false;
  String? _errorMessage;
  final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  FundingProject? detailProject;
  bool _isDonating = false;
  final TextEditingController _amountController = TextEditingController();
  String selectedCurrency = 'IDR';
  Map<String, double> exchangeRates = {
    'IDR': 1.0,
    'USD': 0.000065, // contoh: 1 IDR = 0.000065 USD
    'EUR': 0.000060,
  };
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _presenter = ProjectPresenter(this);
    _presenter.getProjectById(widget.id);
    _initializeNotification();
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  void _initializeNotification() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showDonationSuccessNotification() async {
    final String amountText = _amountController.text.trim();
    final formattedAmount = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
    ).format(double.tryParse(amountText) ?? 0);
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'donation_channel',
      'Donasi',
      channelDescription: 'Donasi Berhasil Dilakukan Sebanyak $formattedAmount',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    final NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Donasi Berhasil 🎉',
      'Terima kasih atas donasi sebesar $formattedAmount!',
      platformDetails,
    );
  }

  String formatCurrency(double amount) {
    final rate = exchangeRates[selectedCurrency]!;
    final converted = amount * rate;

    switch (selectedCurrency) {
      case 'USD':
        return NumberFormat.currency(locale: 'en_US', symbol: '\$')
            .format(converted);
      case 'EUR':
        return NumberFormat.currency(locale: 'eu', symbol: '€')
            .format(converted);
      case 'IDR':
      default:
        return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp')
            .format(amount);
    }
  }

  Future<void> _getCurrentLocationAndRoute() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _errorMessage = "Permission lokasi ditolak.");
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      LatLng userLocation = LatLng(position.latitude, position.longitude);

      List<LatLng> route = await getRoute(
        userLocation,
        LatLng(detailProject!.latitude, detailProject!.longitude),
      );

      setState(() {
        currentPosition = userLocation;
        routePlace = route;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = "Gagal mendapatkan lokasi/rute: $e");
      }
    }
  }

  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    try {
      final result = await getRoutePolyline(
        startLat: start.latitude,
        startLng: start.longitude,
        endLat: end.latitude,
        endLng: end.longitude,
      );
      return result;
    } catch (e) {
      print("Error getRoute: $e");
      return [];
    }
  }

  LatLng midpoint(LatLng point1, LatLng point2) {
    return LatLng(
      (point1.latitude + point2.latitude) / 2,
      (point1.longitude + point2.longitude) / 2,
    );
  }

  Future<void> openGoogleMapsRoute(
      double startLat, double startLng, double endLat, double endLng) async {
    final Uri url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=$startLat,$startLng&destination=$endLat,$endLng&travelmode=driving');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tidak bisa membuka Google Maps.")),
      );
    }
  }

  void onDonatePressed() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Masukkan jumlah donasi terlebih dahulu")));
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Masukkan jumlah donasi yang valid")));
      return;
    }

    if (detailProject != null) {
      _presenter.donateToProject(widget.id, widget.user.id!, amount);
      setState(() {
        _isDonating = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar:
            AppBar(title: Text("Project Detail"), backgroundColor: Colors.teal),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    if (detailProject == null) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Project Detail"),
        backgroundColor: Colors.teal,
      ),
      body: Center(child: CircularProgressIndicator()),
    );
  }

    final percentFunded =
        detailProject!.totalDonations / detailProject!.targetAmount;

    return Scaffold(
      appBar:
          AppBar(
            title: Text("Project Detail"), 
            backgroundColor: Colors.teal,
            actions: detailProject!.userId == widget.user.id
            ? [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white,),
                  tooltip: 'Edit Project',
                  onPressed: () => {
                    Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ProjectFormPage(userId: widget.user.id!, isEdit: true, project: detailProject,)
                        )
                    )
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.white,),
                  tooltip: 'Batalkan Project',
                  onPressed: () => {
                    _presenter.cancelProject(userId: widget.user.id!, projectId: detailProject!.projectId)
                  }
                ),
              ]
            : [],
            ),
      body: Column(
        children: [
          Image.network(
            detailProject!.imgUrl,
            width: double.infinity,
            height: 250,
            fit: BoxFit.cover,
          ),
          Expanded(
            child: Transform.translate(
              offset: Offset(0, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  // borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                ),
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Colors.teal,
                        unselectedLabelColor: Colors.grey,
                        tabs: [
                          Tab(text: "Overview"),
                          Tab(text: "Location"),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(detailProject!.title,
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(height: 8),
                                  Text("Status: ${detailProject!.status}"),
                                  SizedBox(height: 8),
                                  DropdownButton<String>(
                                    value: selectedCurrency,
                                    items: ['IDR', 'USD', 'EUR']
                                        .map((currency) => DropdownMenuItem(
                                              value: currency,
                                              child: Text(currency),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedCurrency = value!;
                                      });
                                    },
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Target: ${formatCurrency(detailProject!.targetAmount)}",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                      "Terkumpul: ${formatCurrency(detailProject!.totalDonations)}"),
                                  SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: percentFunded.clamp(0.0, 1.0),
                                    color: Colors.green,
                                    backgroundColor: Colors.grey[300],
                                  ),
                                  SizedBox(height: 16),
                                  Text(detailProject!.description,
                                      textAlign: TextAlign.justify),
                                  Text(
                                      "Start Date: ${dateFormat.format(detailProject!.startDate)}"),
                                  SizedBox(height: 4),
                                  Text(
                                      "End Date: ${dateFormat.format(detailProject!.deadline)}"),
                                  SizedBox(height: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Donasi Sekarang",
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(height: 8),
                                      TextField(
                                        controller: _amountController,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                                decimal: true),
                                        decoration: InputDecoration(
                                          labelText: "Jumlah Donasi (Rp)",
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _isDonating
                                              ? null
                                              : onDonatePressed,
                                          child: _isDonating
                                              ? SizedBox(
                                                  height: 16,
                                                  width: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : Text("Donate"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.teal,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Expanded(
                                  child: (currentPosition == null)
                                      ? Center(
                                          child: CircularProgressIndicator())
                                      : FlutterMap(
                                          options: MapOptions(
                                            initialCenter: midpoint(
                                              currentPosition!,
                                              LatLng(detailProject!.latitude,
                                                  detailProject!.longitude),
                                            ),
                                            initialZoom: 13,
                                          ),
                                          children: [
                                            TileLayer(
                                              urlTemplate:
                                                  "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                              subdomains: ['a', 'b', 'c'],
                                            ),
                                            if (routePlace.isNotEmpty)
                                              PolylineLayer(
                                                polylines: [
                                                  Polyline(
                                                    points: routePlace,
                                                    strokeWidth: 4.0,
                                                    color: Colors.blue,
                                                  ),
                                                ],
                                              ),
                                            MarkerLayer(
                                              markers: [
                                                Marker(
                                                  point: LatLng(
                                                      detailProject!.latitude,
                                                      detailProject!.longitude),
                                                  width: 60,
                                                  height: 60,
                                                  child: Icon(Icons.location_on,
                                                      color: Colors.red,
                                                      size: 40),
                                                ),
                                                Marker(
                                                  point: currentPosition!,
                                                  width: 60,
                                                  height: 60,
                                                  child: Icon(
                                                      Icons.person_pin_circle,
                                                      color: Colors.blue,
                                                      size: 40),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ElevatedButton(
                                    onPressed: currentPosition != null
                                        ? () {
                                            openGoogleMapsRoute(
                                              currentPosition!.latitude,
                                              currentPosition!.longitude,
                                              detailProject!.latitude,
                                              detailProject!.longitude,
                                            );
                                          }
                                        : null,
                                    child: Text("Live Routing"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Presenter Callbacks
  @override
  void projectById(FundingProject projects) {
    setState(() {
      detailProject = projects;
    });
    _getCurrentLocationAndRoute();
  }

  @override
  void showError(String message) {
    setState(() => _errorMessage = message);
  }

  @override
  void showLoading() => setState(() => _isLoading = true);
  @override
  void hideLoading() => setState(() => _isLoading = false);
  @override
  void onCreateProjectResult(bool success) {}
  @override
  void onDonateResult(bool success) {
    setState(() {
      _isDonating = false;
    });
    _presenter.getProjectById(widget.id);
    _showDonationSuccessNotification();
  }

  @override
  void onUpdateProjectResult(bool success) {}
  @override
  void showAllLatestProjects(List<FundingProject> projects) {}
  @override
  void showAllProjects(List<FundingProject> projects) {}
  @override
  void showParticipatedProjects(List<FundingProject> projects) {}
  @override
  void showUserDonation(Map<String, dynamic> donationData) {}
  
  @override
  void onCancelProjectResult(bool success) {
    if(success==true){
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Berhasil Membatalkan Pendanaan!")));
      Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => MainMenu(),
      ),
      (route) => false,
    );
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal Membatalkan Pendanaan!")));
    }
  }
  
  @override
  void showAllProjectByUserId(List<FundingProject> projects) {
    // TODO: implement showAllProjectByUserId
  }
}
