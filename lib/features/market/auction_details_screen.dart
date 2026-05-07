import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auction_completed_screen.dart';
import 'services/auction_service.dart';
import 'models/auction_model.dart';
import 'models/bid_model.dart';

class AuctionDetailsScreen extends StatefulWidget {
  final AuctionModel auction;

  const AuctionDetailsScreen({super.key, required this.auction});

  @override
  State<AuctionDetailsScreen> createState() => _AuctionDetailsScreenState();
}

class _AuctionDetailsScreenState extends State<AuctionDetailsScreen> {
  final AuctionService _auctionService = AuctionService();
  final TextEditingController _bidController = TextEditingController();
  bool _isBidding = false;
  bool _isAccepting = false;

  late AuctionModel _currentAuction;

  @override
  void initState() {
    super.initState();
    _currentAuction = widget.auction;
  }

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  void _placeBid() async {
    final amount = double.tryParse(_bidController.text);
    if (amount == null) return;

    if (amount <= _currentAuction.highestBid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bid must be higher than current highest bid')));
      return;
    }

    setState(() => _isBidding = true);
    try {
      await _auctionService.placeBid(_currentAuction.id, amount);
      if (mounted) {
        _bidController.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bid placed successfully')));
        // Update local state temporarily, or wrap entire screen in StreamBuilder
        setState(() {
          _currentAuction = AuctionModel(
            id: _currentAuction.id,
            cropName: _currentAuction.cropName,
            imageUrl: _currentAuction.imageUrl,
            quantity: _currentAuction.quantity,
            minPrice: _currentAuction.minPrice,
            quality: _currentAuction.quality,
            duration: _currentAuction.duration,
            startTime: _currentAuction.startTime,
            endTime: _currentAuction.endTime,
            locationName: _currentAuction.locationName,
            farmerId: _currentAuction.farmerId,
            status: _currentAuction.status,
            highestBid: amount,
            totalBids: _currentAuction.totalBids + 1,
            createdAt: _currentAuction.createdAt,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isBidding = false);
      }
    }
  }

  void _acceptBid() async {
    setState(() => _isAccepting = true);
    try {
      await _auctionService.acceptBid(_currentAuction.id, _currentAuction.highestBid);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AuctionCompletedScreen(auction: _currentAuction),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isAccepting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == _currentAuction.farmerId;
    final isExpired = DateTime.now().isAfter(_currentAuction.endTime);

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4), // background-light
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF15803D).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF15803D)),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
        title: const Text(
          'Auction Details',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFF15803D).withValues(alpha: 0.1),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildImageHero(),
            _buildStatsGrid(),
            _buildBidListSection(),
            if (isOwner && !isExpired && _currentAuction.totalBids > 0)
              _buildOwnerActionButtons(context),
            if (!isOwner && !isExpired)
              _buildBuyerActionButtons(context),
            if (isExpired && _currentAuction.status != 'completed')
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Auction has expired', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHero() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 256,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
          image: DecorationImage(
            image: _currentAuction.imageUrl.isNotEmpty 
              ? NetworkImage(_currentAuction.imageUrl) 
              : const NetworkImage('https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&q=80&w=800'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.7),
                Colors.transparent,
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF15803D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'LIVE AUCTION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_currentAuction.cropName} - ${_currentAuction.quality}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _currentAuction.locationName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final difference = _currentAuction.endTime.difference(DateTime.now());
    String timeLeft = '';
    bool isWarning = false;
    
    if (difference.isNegative) {
      timeLeft = 'Expired';
      isWarning = true;
    } else if (difference.inHours > 0) {
      timeLeft = '${difference.inHours}h ${difference.inMinutes.remainder(60)}m';
    } else {
      timeLeft = '${difference.inMinutes}m';
      isWarning = true;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.5,
        children: [
          _buildStatCard(
            icon: Icons.monitor_weight,
            title: '${_currentAuction.quantity} Tons',
            subtitle: 'Total Quantity',
          ),
          _buildStatCard(
            icon: Icons.sell,
            title: '₹${_currentAuction.minPrice.toStringAsFixed(0)}/kg',
            subtitle: 'Min Base Price',
          ),
          _buildStatCard(
            icon: Icons.trending_up,
            title: '₹${_currentAuction.highestBid.toStringAsFixed(0)}/kg',
            subtitle: 'Highest Bid',
            isHighlighted: true,
          ),
          _buildStatCard(
            icon: Icons.timer,
            title: timeLeft,
            subtitle: 'Remaining',
            isWarning: isWarning,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isHighlighted = false,
    bool isWarning = false,
  }) {
    final bgColor = isHighlighted
        ? const Color(0xFF15803D)
        : (isWarning ? Colors.orange.shade50 : const Color(0xFF15803D).withValues(alpha: 0.05));
    final borderColor = isHighlighted
        ? const Color(0xFF15803D).withValues(alpha: 0.2)
        : (isWarning ? Colors.orange.shade200 : const Color(0xFF15803D).withValues(alpha: 0.1));
    final iconColor = isHighlighted
        ? Colors.white
        : (isWarning ? Colors.orange.shade600 : const Color(0xFF15803D));
    final titleColor = isHighlighted
        ? Colors.white
        : (isWarning ? Colors.orange.shade900 : const Color(0xFF0F172A));
    final subtitleColor = isHighlighted
        ? Colors.white.withValues(alpha: 0.8)
        : (isWarning ? Colors.orange.shade600.withValues(alpha: 0.7) : const Color(0xFF64748B));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isHighlighted
            ? [BoxShadow(color: const Color(0xFF15803D).withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                  height: 1.2,
                ),
              ),
              Text(
                subtitle.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBidListSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Bids (${_currentAuction.totalBids})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<BidModel>>(
            stream: _auctionService.getBids(_currentAuction.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No bids yet. Be the first to bid!'),
                );
              }
              
              final bids = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bids.length,
                itemBuilder: (context, index) {
                  final bid = bids[index];
                  final diff = DateTime.now().difference(bid.timestamp);
                  String timeAgo = diff.inMinutes < 60 ? '${diff.inMinutes}m ago' : '${diff.inHours}h ago';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildBidItem(
                      initials: 'B',
                      name: 'Bidder',
                      type: 'Buyer',
                      rating: '',
                      bidAmount: '₹${bid.bidAmount.toStringAsFixed(0)}/kg',
                      timeAgo: timeAgo,
                      isTopBid: index == 0,
                    ),
                  );
                },
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildBidItem({
    required String initials,
    required String name,
    required String type,
    required String rating,
    required String bidAmount,
    required String timeAgo,
    bool isTopBid = false,
    bool isVerified = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isTopBid ? const Color(0xFF15803D).withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isTopBid ? const Color(0xFF15803D) : const Color(0xFF475569),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$type',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                bidAmount,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isTopBid ? const Color(0xFF15803D) : const Color(0xFF0F172A),
                ),
              ),
              Text(
                timeAgo.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: _isAccepting ? null : _acceptBid,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: const Color(0xFF15803D).withValues(alpha: 0.5),
            ),
            child: _isAccepting 
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  'Accept Highest Bid (₹${_currentAuction.highestBid.toStringAsFixed(0)}/kg)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerActionButtons(BuildContext context) {
    final amount = double.tryParse(_bidController.text);
    final bool isValidBid = amount != null && amount > _currentAuction.highestBid;
    final bool isEmpty = _bidController.text.isEmpty;

    String? errorText;
    if (!isEmpty) {
      if (amount == null) {
        errorText = 'Invalid amount';
      } else if (amount <= _currentAuction.highestBid) {
        errorText = 'Must be > ₹${_currentAuction.highestBid.toStringAsFixed(0)}';
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _bidController,
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Enter amount (>${_currentAuction.highestBid})',
                prefixText: '₹',
                errorText: errorText,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: (_isBidding || (!isValidBid && !isEmpty)) ? null : _placeBid,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: _isBidding 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
              : const Text(
                  'Place Bid',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
          ),
        ],
      ),
    );
  }
}
