import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ble_peripheral/ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';

class VehicleControlPage extends StatefulWidget {
  const VehicleControlPage({super.key});

  @override
  _VehicleControlPageState createState() => _VehicleControlPageState();
}

class _VehicleControlPageState extends State<VehicleControlPage> with SingleTickerProviderStateMixin {
  bool _isAdvertising = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _initBle();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }


  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    if (statuses.values.any((status) => status != PermissionStatus.granted)) {
      print("Not all permissions were granted");
    }
  }

  void _initBle() async {
    await _requestPermissions();
    await BlePeripheral.initialize();
    BlePeripheral.setAdvertisingStatusUpdateCallback(
            (bool advertising, String? error) {
          setState(() {
            _isAdvertising = advertising;
          });
          if (kDebugMode) {
            print("AdvertisingStatus: $advertising Error: $error");
          }
        });
  }

  void _advertiseData(List<int> data) async {
    if (_isAdvertising) {
      await BlePeripheral.stopAdvertising();
    }
    ManufacturerData manufacturerData = ManufacturerData(
      manufacturerId: 0x131,
      data: Uint8List.fromList(data),
    );

    try {
      await BlePeripheral.startAdvertising(
        addManufacturerDataInScanResponse: false,
        services: [],
        manufacturerData: manufacturerData,
      );

      // Stop advertising after 1 second
      await Future.delayed(const Duration(seconds: 1));
      await BlePeripheral.stopAdvertising();
    } catch (e) {
      print("Error while advertising: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatusIndicator(),
                      const SizedBox(height: 40),
                      _buildControlButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(bottom: BorderSide(color: Colors.blue, width: 1)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'RAPTRIX KEYFOB',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border.all(color: Colors.blue, width: 1),
        boxShadow: [
          BoxShadow(
            color: _isAdvertising ? Colors.blue.withOpacity(0.3) : Colors.transparent,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bluetooth,
            size: 50,
            color: _isAdvertising ? Colors.blue : Colors.white54,
          ),
          const SizedBox(height: 15),
          Text(
            _isAdvertising ? 'TRANSMITTING' : 'READY',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isAdvertising ? Colors.blue : Colors.white54,
            ),
          ),
          const SizedBox(height: 10),
          _buildPulseIndicator(),
        ],
      ),
    );
  }

  Widget _buildPulseIndicator() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isAdvertising
                ? Colors.blue.withOpacity(_animationController.value)
                : Colors.transparent,
          ),
        );
      },
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton('ON', [0xa1, 0xb4, 0xc7, 0x01]),
        const SizedBox(width: 20),
        _buildButton('OFF', [0xa1, 0xb4, 0xc7, 0x00]),
      ],
    );
  }

  Widget _buildButton(String label, List<int> data) {
    return GestureDetector(
      onTap: () => _advertiseData(data),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          border: Border.all(color: Colors.blue, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
