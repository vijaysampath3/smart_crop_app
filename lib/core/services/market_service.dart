import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MarketPriceData {
  final String commodity;
  final String state;
  final String district;
  final String market;
  final double pricePerKg; 
  final String arrivalDate;

  MarketPriceData({
    required this.commodity,
    required this.state,
    required this.district,
    required this.market,
    required this.pricePerKg,
    required this.arrivalDate,
  });

  factory MarketPriceData.fromJson(Map<String, dynamic> json) {
    double modalPrice = 0.0;
    if (json['modal_price'] != null) {
      modalPrice = double.tryParse(json['modal_price'].toString()) ?? 0.0;
    }

    return MarketPriceData(
      commodity: json['commodity'] ?? 'Unknown',
      state: json['state'] ?? 'Unknown',
      district: json['district'] ?? 'Unknown',
      market: json['market'] ?? 'Unknown',
      pricePerKg: modalPrice / 100.0,
      arrivalDate: json['arrival_date'] ?? 'Unknown',
    );
  }
}

class MarketService {
  static final MarketService _instance = MarketService._internal();

  factory MarketService() {
    return _instance;
  }

  MarketService._internal();

  
  static const String apiKey = '579b464db66ec23bdd00000173f1018db7894b70703fd9d9945c0814';
  
  bool isFetching = false;
  bool hasFetched = false;
  String errorMessage = '';
  
  List<MarketPriceData> marketData = [];
  DateTime? lastUpdated;

  Future<void> fetchMarketPrices({
    bool forceRefresh = false,
  }) async {
    if (hasFetched && !forceRefresh) return;
    if (isFetching) return;

    isFetching = true;
    errorMessage = '';

    String detectedState = 'Andhra Pradesh'; 

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          Position? position = await Geolocator.getLastKnownPosition();
          
          try {
            position ??= await Geolocator.getCurrentPosition(
              timeLimit: const Duration(seconds: 5),
            );
          } catch (e) {
            debugPrint("Timeout getting current location: $e");
          }
          
          if (position != null) {
            List<Placemark> placemarks = await placemarkFromCoordinates(
              position.latitude, 
              position.longitude,
            );
            
            if (placemarks.isNotEmpty && placemarks.first.administrativeArea != null) {
              detectedState = placemarks.first.administrativeArea!;
              // The API usually expects full state name
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Location detection failed: $e");
    }
    const String defaultApiKey = '579b464db66ec23bdd00000173f1018db7894b70703fd9d9945c0814';
    
    final uri = Uri.parse(
      'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070'
      '?api-key=$defaultApiKey'
      '&format=json'
      '&filters[state]=$detectedState'
      '&limit=100'
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['records'] != null && data['records'] is List) {
          final List<dynamic> records = data['records'];
          
          List<MarketPriceData> parsedData = records
              .map((json) => MarketPriceData.fromJson(json as Map<String, dynamic>))
              .toList();

          // Group by commodity and keep highest price
          Map<String, MarketPriceData> bestPrices = {};
          for (var item in parsedData) {
            String commodityName = item.commodity.toLowerCase().trim();
            if (!bestPrices.containsKey(commodityName) || 
                item.pricePerKg > bestPrices[commodityName]!.pricePerKg) {
              bestPrices[commodityName] = item;
            }
          }
          
          List<MarketPriceData> uniqueCrops = bestPrices.values.toList();

          
          uniqueCrops.sort((a, b) => b.pricePerKg.compareTo(a.pricePerKg));

          
          if (uniqueCrops.length > 10) {
            uniqueCrops = uniqueCrops.sublist(0, 10);
          }

          marketData = uniqueCrops;
          lastUpdated = DateTime.now();
          hasFetched = true;
        } else {
          errorMessage = 'No records found in the response.';
          marketData = [];
        }
      } else {
        errorMessage = 'Failed to fetch data (Status ${response.statusCode})';
      }
    } catch (e) {
      debugPrint("MarketService fetch error: $e");
      errorMessage = 'Error fetching market data: $e';
    } finally {
      isFetching = false;
    }
  }
}
