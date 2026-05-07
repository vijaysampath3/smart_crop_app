import 'package:flutter/material.dart';
import 'warehouse_result_screen.dart';
import 'warehouse_plan_model.dart';
import 'warehouse_plan_service.dart';

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  String selectedLocation = 'Inside Farm Land';
  String selectedCapacity = '1 - 5';
  String selectedMethod = 'Contractor';
  String selectedBudget = '1L - 2L';
  String selectedCrop = 'Rice';
  String customCrop = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Storage Planner',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Storage Location'),
              const SizedBox(height: 12),
              _buildLocationOption('Inside Farm Land', Icons.agriculture, isSelected: selectedLocation == 'Inside Farm Land'),
              const SizedBox(height: 12),
              _buildLocationOption('Outside Farm Land', Icons.domain, isSelected: selectedLocation == 'Outside Farm Land'),
              const SizedBox(height: 12),
              _buildLocationOption('Near Road', Icons.add_road, isSelected: selectedLocation == 'Near Road'),

              const SizedBox(height: 24),
              _buildSectionTitle('Capacity (Tons)'),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCapacityOption('1 - 5'),
                    const SizedBox(width: 12),
                    _buildCapacityOption('5 - 10'),
                    const SizedBox(width: 12),
                    _buildCapacityOption('10 - 20'),
                    const SizedBox(width: 12),
                    _buildCapacityOption('20+'),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Construction Method'),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(width: 120, child: _buildMethodOption('Local Labour', Icons.groups)),
                    const SizedBox(width: 12),
                    SizedBox(width: 120, child: _buildMethodOption('Contractor', Icons.engineering)),
                    const SizedBox(width: 12),
                    SizedBox(width: 120, child: _buildMethodOption('Pre-built', Icons.factory)),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Budget Range'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  _buildBudgetOption('50K - 1L'),
                  _buildBudgetOption('1L - 2L'),
                  _buildBudgetOption('2L - 5L'),
                  _buildBudgetOption('5L+'),
                ],
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Select Crop'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
                children: [
                  _buildCropOption('Rice', 'https://lh3.googleusercontent.com/aida-public/AB6AXuDPwuOHSjL4abwOQgXqAjk86fjyhhDk82eoYHS0n1cnFZurJZ3z8AtpGu5LrxtNH0bkqEF7vybQwWnSLdUUf_ZFJAkkvdO_POLVieQe1lVGB5_imkig-_o9eTsYH9HiA1Md6c1z7II0VXpaO8kZFBz9nenPaMyMVwBPef1Pa2GIaOMqBahzn5qSD_cICuUl6UVk7tuJx4HqtPZOAbJVAH0Ls-_EYUcMze5BOY5sVcvw6wRjZ9U7lP_1WW0JseWWcTcB7fGoDO_RF58'),
                  _buildCropOption('Wheat', 'https://lh3.googleusercontent.com/aida-public/AB6AXuDD0oL4FpWoZmD2_phQvMZ6TGnK3RZZga2y3yxExUm4-GOM-1IBzd9AH3yWdkQx-LvvDOKZVVwPhuS4iuPXwCMQEBEGl7L2XXyw7ZiBiCZ9jmhhigGKEDRIQZz6XsZ6bmU2HKpEHYZT32fln0AwCtXrkSeRzrj0wqnP2i0N7K06GETFZk1fBFH_ALAcmlzwf_H17zD9J05NVIWAP8jT1LuhxZVPtWX3gIb9JzBkesQr9kmUU8a_dv1pR3CwiNtl7aEmepE5ZT4-89c'),
                  _buildCropOption('Cotton', 'https://lh3.googleusercontent.com/aida-public/AB6AXuCbH0n64VRW0sDAL6S97E3P0WftF8nlsHpQzYihzvNrznXPUiRMDEk4Mw4GUgVgQkUpDLnbh7Zq8RVzCEYVAKlzyKg_H_rBv5okqP_q6WyxUGyQ3hvLqhumLY87WPptRrCPc1MxEwN9jYf9V7itd3876GMbfyK3NznIEkrD7hDwBFZlZQRe9dGahomEq6hOurb9A5ndIDfCg8qSow-EaZMIFa6V03JoMXrXtBxHdQHl3wGTyfgqSeiNtH6csssogOWtA37np87gVLk'),
                  _buildCropOption('Tomato', 'https://lh3.googleusercontent.com/aida-public/AB6AXuDeNAdX87hGK8_aEOWpsSesU8VK60LoJO1vz_Oug0w4WlHY6BIXJBN81gtTr9FrxlSxvuhfIocGVNx4GJR4Eyexd5XHg7XLPOhVm_5p0r-co9VTu-mEp4dlZ21XBkI_KOpkGc56zgXLrlS4CeMWbFmqixX57Fmj_Uu30LknRXksRovJVwADSdo87G3M-gM4-6RDxZNsi11PfxABoxp-lYc9JWcfuorSljKYFDUJAV3e4Q_Mz0hBD9tML6eQr10QoBb_mZIbQRAKVSo'),
                  _buildCropOption('Groundnut', 'https://lh3.googleusercontent.com/aida-public/AB6AXuCUXEP5Q-8ONM9dP4kvGUX7ydRxZ_J64vh9NW4pjNUHTh6YX8wYC6LGEqCvK877I52aAy3AR5DRU1fEZ2kNbOXVNAN8V3Zo23DQ5cc8Uq_3pr7CSp-8rRur_U7XcVtB7DF8fqZbp7gLAuuWrWoZeoaOvIR5rjB7geZzZKY-EyolHi9FG8nBNzrlzLnUan3fOosI7GK1B5X8wZKWc7yQ9xFBYWsrgidO17X5LSdoRrcOggy5xzHJesJb3Pjw-kPndIjK9mffwNIMzS8'),
                  _buildCropOption('Maize', 'https://lh3.googleusercontent.com/aida-public/AB6AXuCHIY3Pk7IPvLRa12Uw8JbENmTWyTbDlnsTLkUvf6yp4_Lob5AYi2Mb9ByeHerAaXQueYJgTokNjZP7qN5LVc8RMtY3FBY1ymSWXUfutC-ZKvOFxe3Ynna_gfcCN4BR0NzdzJSPe4iEXGAdcyqmVIsb7lyyrJcUtN5gdMbrv4DKdqBuFK-sSDSS6s19hzJog1Ex72r42iKWgDvF9d7uQVEwrLiR7GvMUbhkQKBnmUrCWeE7jo3OG7-Iqu4_t5KG6yivXTRXx4e0-BY'),
                  _buildCropOption('Other', '', icon: Icons.local_florist),
                ],
              ),

              if (selectedCrop == 'Other') ...[
                const SizedBox(height: 16),
                TextField(
                  onChanged: (val) {
                    customCrop = val;
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter your crop (e.g., Chilli, Mango)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () async {
                    if (selectedCrop == 'Other' && customCrop.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter your crop name'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _isLoading = true;
                    });
                    
                    final info = WarehousePlanInfo(
                      location: selectedLocation,
                      capacity: selectedCapacity,
                      method: selectedMethod,
                      budget: selectedBudget,
                      crop: selectedCrop == 'Other' ? customCrop.trim() : selectedCrop,
                    );
                    
                    final service = WarehousePlanService();
                    final result = await service.generatePlan(info);
                    
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WarehouseResultScreen(planResult: result),
                        ),
                      );
                    }
                  },
                  icon: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Icon(Icons.analytics, color: Colors.white),
                  label: Text(
                    _isLoading ? 'Planning Storage...' : 'Generate Storage Plan',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    disabledBackgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.7),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: Colors.black45,
      ),
    );
  }

  Widget _buildLocationOption(String label, IconData icon, {bool isSelected = false}) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedLocation = label;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade500,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isSelected ? Colors.black87 : Colors.black54,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityOption(String label) {
    bool isSelected = selectedCapacity == label;
    return InkWell(
      onTap: () {
        setState(() {
          selectedCapacity = label;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade200,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildMethodOption(String label, IconData icon) {
    bool isSelected = selectedMethod == label;
    return InkWell(
      onTap: () {
        setState(() {
          selectedMethod = label;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetOption(String label) {
    bool isSelected = selectedBudget == label;
    return InkWell(
      onTap: () {
        setState(() {
          selectedBudget = label;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isSelected ? Colors.white : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _buildCropOption(String label, String imageUrl, {IconData? icon}) {
    bool isSelected = selectedCrop == label;
    return InkWell(
      onTap: () {
        setState(() {
          selectedCrop = label;
        });
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: icon != null
                    ? Container(
                        color: Colors.grey.shade50,
                        child: Icon(
                          icon,
                          size: 40,
                          color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade400,
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        color: isSelected ? null : Colors.white.withValues(alpha: 0.3),
                        colorBlendMode: BlendMode.lighten,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
