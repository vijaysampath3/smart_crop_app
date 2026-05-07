import 'package:cloud_firestore/cloud_firestore.dart';

class BidModel {
  final String id;
  final String auctionId;
  final String bidderId;
  final double bidAmount;
  final DateTime timestamp;

  BidModel({
    required this.id,
    required this.auctionId,
    required this.bidderId,
    required this.bidAmount,
    required this.timestamp,
  });

  factory BidModel.fromMap(Map<String, dynamic> map, String documentId) {
    return BidModel(
      id: documentId,
      auctionId: map['auctionId'] ?? '',
      bidderId: map['bidderId'] ?? '',
      bidAmount: (map['bidAmount'] ?? 0).toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'auctionId': auctionId,
      'bidderId': bidderId,
      'bidAmount': bidAmount,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
