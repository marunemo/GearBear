import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'models/camp_site.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:geolocator/geolocator.dart';

class CampMapPage extends StatefulWidget {
  @override
  State<CampMapPage> createState() => _CampMapPageState();
}

class _CampMapPageState extends State<CampMapPage> {
  GoogleMapController? _mapController;
  LatLng? _userPosition = LatLng(36.103302286741716, 129.38704047004038);
  List<CampSite> _allCamps = [];
  Set<Marker> _markers = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    loadCampSites().then((camps) {
      _allCamps = camps;
      setState(() {
        _loading = false;
      });
    });
  }

  Future<List<CampSite>> loadCampSites() async {
    final csvString = await rootBundle.loadString('assets/mapData/Camp_Map.csv');
    final List<List<dynamic>> rows = const CsvToListConverter(
      fieldDelimiter: ',',
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(csvString);

    return rows.skip(1).map((row) {
      final name = row[0] as String;
      final lat = double.tryParse(row[11].toString()) ?? 0.0;
      final lng = double.tryParse(row[12].toString()) ?? 0.0;
      final address = row[14] as String;
      return CampSite(name: name, latitude: lat, longitude: lng, address: address);
    }).toList();
  }

  Set<Marker> filterMarkers(LatLngBounds bounds, List<CampSite> camps) {
    return camps.where((camp) {
      final lat = camp.latitude;
      final lng = camp.longitude;
      return lat >= bounds.southwest.latitude &&
             lat <= bounds.northeast.latitude &&
             lng >= bounds.southwest.longitude &&
             lng <= bounds.northeast.longitude;
    }).map((camp) => Marker(
      markerId: MarkerId(camp.name),
      position: LatLng(camp.latitude, camp.longitude),
      infoWindow: InfoWindow(
        title: '', // infoWindow 비활성화
        snippet: '',
      ),
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(camp.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(camp.address, style: TextStyle(fontSize: 16)),
                SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // RSVP 기능(추후 구현)
                    Navigator.pop(context);
                  },
                  child: Text('RSVP'),
                ),
              ],
            ),
          ),
        );
      },
    )).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Camp Map')),
      body: _loading || _userPosition == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (controller) async {
                _mapController = controller;
                final bounds = await controller.getVisibleRegion();
                setState(() {
                  _markers = filterMarkers(bounds, _allCamps);
                });
              },
              initialCameraPosition: CameraPosition(
                target: _userPosition!,
                zoom: 12.0,
              ),
              onCameraIdle: () async {
                if (_mapController != null) {
                  LatLngBounds b = await _mapController!.getVisibleRegion();
                  setState(() {
                    _markers = filterMarkers(b, _allCamps);
                  });
                }
              },
              markers: _markers,
            ),
    );
  }
}