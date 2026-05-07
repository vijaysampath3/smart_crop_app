import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../models/auction_model.dart';
import '../models/bid_model.dart';
import '../../core/config/app_secrets.dart';

class AuctionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cloudinary configuration from environment variables
  static const String _cloudinaryCloudName = AppSecrets.cloudinaryCloudName;
  static const String _cloudinaryApiKey = AppSecrets.cloudinaryApiKey;
  static const String _cloudinaryApiSecret = AppSecrets.cloudinaryApiSecret;

  Future<String> _uploadImageToCloudinary(File imageFile) async {
    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
    
    // Generate SHA-1 signature
    // The signature requires all parameters to be sorted alphabetically, except api_key and file
    final signatureString = 'timestamp=$timestamp$_cloudinaryApiSecret';
    final signature = sha1.convert(utf8.encode(signatureString)).toString();

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = _cloudinaryApiKey
      ..fields['timestamp'] = timestamp
      ..fields['signature'] = signature
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final jsonMap = json.decode(responseData);

    if (response.statusCode == 200) {
      return jsonMap['secure_url'];
    } else {
      throw Exception('Cloudinary upload failed: ${jsonMap['error']?['message'] ?? 'Unknown error'}');
    }
  }

  // Create new auction
  Future<void> createAuction({
    required AuctionModel auction,
    required File imageFile,
  }) async {
    try {
      // 1. Upload image to Cloudinary
      final String imageUrl = await _uploadImageToCloudinary(imageFile);

      // 2. Save auction to Firestore
      final Map<String, dynamic> auctionData = auction.toMap();
      auctionData['imageUrl'] = imageUrl; // Update with real URL

      await _firestore.collection('auctions').add(auctionData);
    } catch (e) {
      throw Exception('Failed to create auction: $e');
    }
  }

  // Stream active auctions
  Stream<List<AuctionModel>> getActiveAuctions() {
    return _firestore
        .collection('auctions')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => AuctionModel.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => a.endTime.compareTo(b.endTime));
      return list;
    });
  }

  // Stream bids for an auction
  Stream<List<BidModel>> getBids(String auctionId) {
    return _firestore
        .collection('bids')
        .where('auctionId', isEqualTo: auctionId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => BidModel.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.bidAmount.compareTo(a.bidAmount)); // descending
      return list;
    });
  }

  // Place a bid using transaction
  Future<void> placeBid(String auctionId, double bidAmount) async {
    final bidderId = _auth.currentUser?.uid;
    if (bidderId == null) throw Exception('User not logged in');

    final auctionRef = _firestore.collection('auctions').doc(auctionId);
    final bidRef = _firestore.collection('bids').doc(); // Auto-ID

    try {
      await _firestore.runTransaction((transaction) async {
        final auctionSnapshot = await transaction.get(auctionRef);

        if (!auctionSnapshot.exists) {
          throw Exception('Auction does not exist');
        }

        final auctionData = auctionSnapshot.data()!;
        final double currentHighestBid = (auctionData['highestBid'] ?? 0).toDouble();
        final int currentTotalBids = auctionData['totalBids'] ?? 0;
        final Timestamp endTime = auctionData['endTime'];

        if (DateTime.now().isAfter(endTime.toDate())) {
          throw Exception('Auction has expired');
        }

        if (bidAmount <= currentHighestBid) {
          throw Exception('Bid must be higher than current highest bid');
        }

        // Add bid to 'bids' collection
        final bidData = BidModel(
          id: bidRef.id,
          auctionId: auctionId,
          bidderId: bidderId,
          bidAmount: bidAmount,
          timestamp: DateTime.now(),
        ).toMap();
        transaction.set(bidRef, bidData);

        // Update auction
        transaction.update(auctionRef, {
          'highestBid': bidAmount,
          'totalBids': currentTotalBids + 1,
        });
      });
    } catch (e) {
      throw Exception('Failed to place bid: $e');
    }
  }

  // Accept highest bid
  Future<void> acceptBid(String auctionId, double highestBid) async {
    try {
      await _firestore.collection('auctions').doc(auctionId).update({
        'status': 'completed',
        'finalPrice': highestBid,
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to accept bid: $e');
    }
  }

  // Get Dashboard Stats for farmer
  Stream<Map<String, dynamic>> getDashboardStats() {
    final farmerId = _auth.currentUser?.uid;
    if (farmerId == null) return Stream.value({'activeCount': 0, 'completedCount': 0, 'totalEarnings': 0.0});

    return _firestore
        .collection('auctions')
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map((snapshot) {
      int activeCount = 0;
      int completedCount = 0;
      double totalEarnings = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'];
        if (status == 'active') {
          // Check if expired
          final endTime = (data['endTime'] as Timestamp).toDate();
          if (DateTime.now().isBefore(endTime)) {
            activeCount++;
          }
        } else if (status == 'completed') {
          completedCount++;
          // Parse quantity and final price
          final double finalPrice = (data['finalPrice'] ?? 0).toDouble();
          final String qtyStr = data['quantity'].toString().replaceAll(RegExp(r'[^0-9.]'), '');
          double qty = double.tryParse(qtyStr) ?? 1.0;
          totalEarnings += (qty * finalPrice);
        }
      }

      return {
        'activeCount': activeCount,
        'completedCount': completedCount,
        'totalEarnings': totalEarnings,
      };
    });
  }
}
