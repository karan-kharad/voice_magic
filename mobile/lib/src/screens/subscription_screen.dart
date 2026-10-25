import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final ApiService _apiService = ApiService.instance;
  Map<String, dynamic> _plansData = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    final data = await _apiService.getSubscriptionPlans();
    if (mounted) {
      setState(() {
        _plansData = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1218),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1218),
        title: const Text('Subscription Plans', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF25D366)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Feasibility Gate Alert Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B1D12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lock_clock_rounded, color: Colors.amber.shade400, size: 24),
                            const SizedBox(width: 10),
                            const Text(
                              'Feasibility Gate Active',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _plansData['feasibility_notice'] ??
                              'Commercial payments remain disabled until recipient-side verification is certified. Enjoy all Voice Studio DSP features free.',
                          style: TextStyle(fontSize: 13, color: Colors.amber.shade100, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Available Tiers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 14),

                  // Free Community Tier Card
                  _buildPlanCard(
                    title: 'Community Tier',
                    price: 'Free Forever',
                    isCurrent: true,
                    isPurchasable: true,
                    features: [
                      'Normal, High Pitch, Low Pitch Presets',
                      'Robot Vocoder & Echo Chamber Effects',
                      'Real-Time Input VU Metering',
                      'WhatsApp Voice Note Direct Export',
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Pro Tier (Preview / Disabled)
                  _buildPlanCard(
                    title: 'Voice Changer Pro (Preview)',
                    price: '\$4.99 / month',
                    isCurrent: false,
                    isPurchasable: false,
                    badgeText: 'LOCKED UNTIL VERIFIED',
                    features: [
                      'AI Voice Conversion Pipeline',
                      'Custom VST3 / CLAP Plugin Loader',
                      'Lossless Opus Audio Encoding',
                      'Dedicated In-App VoIP Real-Time Calling',
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required bool isCurrent,
    required bool isPurchasable,
    String? badgeText,
    required List<String> features,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFF14241E) : const Color(0xFF191D26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent ? const Color(0xFF25D366) : Colors.white12,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade900.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            price,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isCurrent ? const Color(0xFF25D366) : Colors.white70,
            ),
          ),
          const Divider(color: Colors.white12, height: 26),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(
                      isPurchasable ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                      size: 18,
                      color: isPurchasable ? const Color(0xFF25D366) : Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 13,
                          color: isPurchasable ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? const Color(0xFF25D366) : Colors.white12,
                foregroundColor: isCurrent ? Colors.black : Colors.white54,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isPurchasable && !isCurrent
                  ? () {}
                  : null,
              child: Text(
                isCurrent ? 'ACTIVE PLAN' : 'PURCHASE DISABLED',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
