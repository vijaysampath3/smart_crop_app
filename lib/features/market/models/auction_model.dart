import 'package:cloud_firestore/cloud_firestore.dart';

class AuctionModel {
  final String id;
  final String cropName;
  final String imageUrl;
  final String quantity;
  final double minPrice;
  final String quality;
  final int duration;
  final DateTime startTime;
  final DateTime endTime;
  final String locationName;
  final String farmerId;
  final String status;
  final double highestBid;
  final int totalBids;
  final DateTime createdAt;
  final double? finalPrice;
  final DateTime? completedAt;

  AuctionModel({
    required this.id,
    required this.cropName,
    required this.imageUrl,
    required this.quantity,
    required this.minPrice,
    required this.quality,
    required this.duration,
    required this.startTime,
    required this.endTime,
    required this.locationName,
    required this.farmerId,
    required this.status,
    required this.highestBid,
    required this.totalBids,
    required this.createdAt,
    this.finalPrice,
    this.completedAt,
  });

  factory AuctionModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AuctionModel(
      id: documentId,
      cropName: map['cropName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      quantity: map['quantity'] ?? '',
      minPrice: (map['minPrice'] ?? 0).toDouble(),
      quality: map['quality'] ?? '',
      duration: map['duration'] ?? 0,
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      locationName: map['locationName'] ?? '',
      farmerId: map['farmerId'] ?? '',
      status: map['status'] ?? 'active',
      highestBid: (map['highestBid'] ?? 0).toDouble(),
      totalBids: map['totalBids'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      finalPrice: map['finalPrice'] != null ? (map['finalPrice']).toDouble() : null,
      completedAt: map['completedAt'] != null ? (map['completedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cropName': cropName,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'minPrice': minPrice,
      'quality': quality,
      'duration': duration,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'locationName': locationName,
      'farmerId': farmerId,
      'status': status,
      'highestBid': highestBid,
      'totalBids': totalBids,
      'createdAt': Timestamp.fromDate(createdAt),
      if (finalPrice != null) 'finalPrice': finalPrice,
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
    };
  }
}
