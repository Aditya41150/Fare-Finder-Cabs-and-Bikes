import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../providers/fare_provider.dart';
import '../models/fare_estimate.dart';
import '../widgets/fare_card.dart';

class ResultsScreen extends StatefulWidget {
  final String pickup;
  final String destination;

  const ResultsScreen({
    super.key,
    required this.pickup,
    required this.destination,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fare Comparison'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.my_location,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.pickup,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.place, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.destination,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<FareProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SpinKitFadingCircle(
                          color: Colors.blue[600],
                          size: 50,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Comparing fares...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.error.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load fare estimates',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.error,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            provider.clearError();
                            Navigator.pop(context);
                          },
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.estimates.isEmpty) {
                  return const Center(
                    child: Text(
                      'No fare estimates available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                final estimates = provider.estimates;
                final bikes = estimates.where((r) => r.isBike).toList();
                final autos = estimates.where((r) => r.isAuto).toList();
                final cabs = estimates.where((r) => r.isCab).toList();
                final overallCheapest = estimates
                    .map((r) => r.estimatedFare)
                    .reduce((a, b) => a < b ? a : b);

                return Column(
                  children: [
                    // Category Filter Tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _buildFilterChip('All (${estimates.length})', 'All'),
                          if (bikes.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            _buildFilterChip(
                                '🏍️ Bikes (${bikes.length})', 'Bikes'),
                          ],
                          if (autos.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            _buildFilterChip(
                                '🛺 Autos (${autos.length})', 'Autos'),
                          ],
                          if (cabs.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            _buildFilterChip(
                                '🚗 Cabs (${cabs.length})', 'Cabs'),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue[600], size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _selectedCategory == 'All'
                                ? '${estimates.length} options found'
                                : 'Showing $_selectedCategory',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Lowest ₹$overallCheapest',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[800],
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          if ((_selectedCategory == 'All' ||
                                  _selectedCategory == 'Bikes') &&
                              bikes.isNotEmpty) ...[
                            _buildSectionHeader(
                                '🏍️ Bikes & Two-Wheelers', Colors.amber[800]!),
                            for (final ride in bikes)
                              FareCard(
                                estimate: ride,
                                isLowest: ride.estimatedFare == overallCheapest,
                                onBook: () => _bookCab(ride),
                              ),
                            const SizedBox(height: 12),
                          ],
                          if ((_selectedCategory == 'All' ||
                                  _selectedCategory == 'Autos') &&
                              autos.isNotEmpty) ...[
                            _buildSectionHeader(
                                '🛺 Auto Rickshaws', Colors.teal[700]!),
                            for (final ride in autos)
                              FareCard(
                                estimate: ride,
                                isLowest: ride.estimatedFare == overallCheapest,
                                onBook: () => _bookCab(ride),
                              ),
                            const SizedBox(height: 12),
                          ],
                          if ((_selectedCategory == 'All' ||
                                  _selectedCategory == 'Cabs') &&
                              cabs.isNotEmpty) ...[
                            _buildSectionHeader(
                                '🚗 Cabs & Taxis', Colors.blue[700]!),
                            for (final ride in cabs)
                              FareCard(
                                estimate: ride,
                                isLowest: ride.estimatedFare == overallCheapest,
                                onBook: () => _bookCab(ride),
                              ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String category) {
    final isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedCategory = category),
      selectedColor: Colors.blue[600],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[800],
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  void _bookCab(FareEstimate estimate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Book ${estimate.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service: ${estimate.name}'),
            Text('Fare: ₹${estimate.estimatedFare}'),
            Text('ETA: ${estimate.eta} minutes'),
            const SizedBox(height: 16),
            const Text(
              'Confirm your booking?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Book Now'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;

      final provider = Provider.of<FareProvider>(context, listen: false);
      final success = await provider.bookCab(
        userId: 'user123', // In real app, get from auth
        estimate: estimate,
        pickup: widget.pickup,
        destination: widget.destination,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Booking confirmed for ${estimate.name}!'
                : 'Booking failed. Please try again.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        Navigator.pop(context);
      }
    }
  }
}
