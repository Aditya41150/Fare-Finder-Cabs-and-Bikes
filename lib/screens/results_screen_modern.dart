import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/fare_provider.dart';
import '../models/fare_estimate.dart';
import 'map_preview_screen.dart';

class ResultsScreenModern extends StatefulWidget {
  static const _ink = Color(0xFF1F2933);
  static const _yellow = Color(0xFFF6C744);
  static const _canvas = Color(0xFFF7F7F5);
  static const _border = Color(0xFFE5E7EB);

  final String pickup;
  final String destination;
  final Map<String, dynamic> pickupData;
  final Map<String, dynamic> destinationData;

  const ResultsScreenModern({
    super.key,
    required this.pickup,
    required this.destination,
    required this.pickupData,
    required this.destinationData,
  });

  @override
  State<ResultsScreenModern> createState() => _ResultsScreenModernState();
}

class _ResultsScreenModernState extends State<ResultsScreenModern> {
  String _selectedCategory = 'All';

  bool _isBike(FareEstimate ride) => ride.isBike;
  bool _isAuto(FareEstimate ride) => ride.isAuto;
  bool _isCab(FareEstimate ride) => ride.isCab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ResultsScreenModern._canvas,
      appBar: AppBar(
        backgroundColor: ResultsScreenModern._canvas,
        foregroundColor: ResultsScreenModern._ink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Compare Rides',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: ResultsScreenModern._ink,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'View route on map',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MapScreen(
                  pickup: widget.pickupData,
                  destination: widget.destinationData,
                ),
              ),
            ),
            icon: const Icon(Icons.route_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Route info card
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: ResultsScreenModern._border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    children: [
                      const Icon(Icons.my_location_rounded,
                          size: 18, color: Color(0xFF10B981)),
                      Container(
                        width: 1.5,
                        height: 22,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: const Color(0xFFE5E7EB),
                      ),
                      const Icon(Icons.location_on_rounded,
                          size: 18, color: Color(0xFFEF4444)),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.pickup,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ResultsScreenModern._ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.destination,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ResultsScreenModern._ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content area
          Expanded(
            child: Consumer<FareProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: ResultsScreenModern._ink,
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Comparing live fares across providers...',
                          style: TextStyle(
                            color: ResultsScreenModern._ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.error.isNotEmpty) {
                  return _buildErrorState(context, provider);
                }

                if (provider.estimates.isEmpty) {
                  return const Center(
                    child: Text(
                      'No rides available for this route',
                      style: TextStyle(
                        color: ResultsScreenModern._ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }

                return _buildFareList(context, provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, FareProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 52, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            const Text(
              'Couldn’t load fares',
              style: TextStyle(
                color: ResultsScreenModern._ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: ResultsScreenModern._ink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFareList(BuildContext context, FareProvider provider) {
    final estimates = provider.estimates;
    final estimate = estimates.first;

    final overallCheapest = estimates
        .map((ride) => ride.estimatedFare)
        .reduce((lowest, fare) => fare < lowest ? fare : lowest);

    final bikes = estimates.where(_isBike).toList();
    final autos = estimates.where(_isAuto).toList();
    final cabs = estimates.where(_isCab).toList();

    int? lowestBikeFare;
    if (bikes.isNotEmpty) {
      lowestBikeFare = bikes
          .map((r) => r.estimatedFare)
          .reduce((a, b) => a < b ? a : b);
    }
    int? lowestAutoFare;
    if (autos.isNotEmpty) {
      lowestAutoFare = autos
          .map((r) => r.estimatedFare)
          .reduce((a, b) => a < b ? a : b);
    }
    int? lowestCabFare;
    if (cabs.isNotEmpty) {
      lowestCabFare = cabs
          .map((r) => r.estimatedFare)
          .reduce((a, b) => a < b ? a : b);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Filter Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          child: Row(
            children: [
              _buildCategoryTab(
                title: 'All Rides',
                icon: Icons.grid_view_rounded,
                count: estimates.length,
                isSelected: _selectedCategory == 'All',
                onTap: () => setState(() => _selectedCategory = 'All'),
              ),
              if (bikes.isNotEmpty) ...[
                const SizedBox(width: 8),
                _buildCategoryTab(
                  title: 'Bikes',
                  icon: Icons.two_wheeler_rounded,
                  count: bikes.length,
                  startingFare: lowestBikeFare,
                  isSelected: _selectedCategory == 'Bikes',
                  onTap: () => setState(() => _selectedCategory = 'Bikes'),
                ),
              ],
              if (autos.isNotEmpty) ...[
                const SizedBox(width: 8),
                _buildCategoryTab(
                  title: 'Autos',
                  icon: Icons.electric_rickshaw_rounded,
                  count: autos.length,
                  startingFare: lowestAutoFare,
                  isSelected: _selectedCategory == 'Autos',
                  onTap: () => setState(() => _selectedCategory = 'Autos'),
                ),
              ],
              if (cabs.isNotEmpty) ...[
                const SizedBox(width: 8),
                _buildCategoryTab(
                  title: 'Cabs',
                  icon: Icons.directions_car_filled_rounded,
                  count: cabs.length,
                  startingFare: lowestCabFare,
                  isSelected: _selectedCategory == 'Cabs',
                  onTap: () => setState(() => _selectedCategory = 'Cabs'),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Route distance & time summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Text(
                _selectedCategory == 'All'
                    ? '${estimates.length} options found'
                    : 'Showing $_selectedCategory',
                style: const TextStyle(
                  color: ResultsScreenModern._ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ResultsScreenModern._border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.speed_rounded,
                        size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      '${estimate.distance.toStringAsFixed(1)} km · ~${estimate.duration} min',
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Main categorized ride list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
            children: [
              // BIKES SECTION
              if ((_selectedCategory == 'All' || _selectedCategory == 'Bikes') &&
                  bikes.isNotEmpty)
                _buildRideSection(
                  context: context,
                  title: 'Bikes & Two-Wheelers',
                  subtitle: 'Fastest in traffic · Pocket-friendly solo rides',
                  icon: Icons.two_wheeler_rounded,
                  iconColor: const Color(0xFFD97706),
                  iconBg: const Color(0xFFFEF3C7),
                  rides: bikes,
                  overallCheapest: overallCheapest,
                  categoryLowest: lowestBikeFare,
                ),

              // AUTOS SECTION
              if ((_selectedCategory == 'All' || _selectedCategory == 'Autos') &&
                  autos.isNotEmpty)
                _buildRideSection(
                  context: context,
                  title: 'Auto Rickshaws',
                  subtitle: 'Direct city travel · Economical 3-seater',
                  icon: Icons.electric_rickshaw_rounded,
                  iconColor: const Color(0xFF059669),
                  iconBg: const Color(0xFFD1FAE5),
                  rides: autos,
                  overallCheapest: overallCheapest,
                  categoryLowest: lowestAutoFare,
                ),

              // CABS SECTION
              if ((_selectedCategory == 'All' || _selectedCategory == 'Cabs') &&
                  cabs.isNotEmpty)
                _buildRideSection(
                  context: context,
                  title: 'Cabs & Taxis',
                  subtitle: 'Comfortable AC rides · Hatchbacks, Sedans & SUVs',
                  icon: Icons.directions_car_filled_rounded,
                  iconColor: const Color(0xFF4F46E5),
                  iconBg: const Color(0xFFEEF2FF),
                  rides: cabs,
                  overallCheapest: overallCheapest,
                  categoryLowest: lowestCabFare,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTab({
    required String title,
    required IconData icon,
    required int count,
    int? startingFare,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? ResultsScreenModern._ink : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? ResultsScreenModern._ink
                  : ResultsScreenModern._border,
              width: 1.2,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    )
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? ResultsScreenModern._yellow
                    : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : ResultsScreenModern._ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  startingFare != null
                      ? '₹$startingFare'
                      : '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF4B5563),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRideSection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required List<FareEstimate> rides,
    required int overallCheapest,
    int? categoryLowest,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Section Header Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ResultsScreenModern._border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: ResultsScreenModern._ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${rides.length}',
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (categoryLowest != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    'from ₹$categoryLowest',
                    style: const TextStyle(
                      color: Color(0xFF047857),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Ride Cards in this section
        for (final ride in rides) ...[
          _buildRideCard(
            context,
            ride,
            isOverallLowest: ride.estimatedFare == overallCheapest,
            isCategoryLowest:
                categoryLowest != null && ride.estimatedFare == categoryLowest,
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildRideCard(
    BuildContext context,
    FareEstimate ride, {
    required bool isOverallLowest,
    required bool isCategoryLowest,
  }) {
    final icon = _providerIcon(ride);
    final brandColor = _providerColor(ride);
    final fareText = ride.fareMin == ride.fareMax
        ? '₹${ride.estimatedFare}'
        : '₹${ride.fareMin}–₹${ride.fareMax}';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _confirmBooking(context, ride),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isOverallLowest
                  ? const Color(0xFFE0B52E)
                  : ResultsScreenModern._border,
              width: isOverallLowest ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isOverallLowest
                    ? const Color(0x1CE0B52E)
                    : const Color(0x08000000),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Provider / vehicle icon badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: brandColor, size: 26),
              ),
              const SizedBox(width: 14),

              // Ride details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            ride.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ResultsScreenModern._ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (isOverallLowest) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: ResultsScreenModern._yellow,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'CHEAPEST',
                              style: TextStyle(
                                color: ResultsScreenModern._ink,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ] else if (isCategoryLowest) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'BEST VALUE',
                              style: TextStyle(
                                color: Color(0xFF15803D),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          ride.provider,
                          style: TextStyle(
                            color: brandColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('·',
                            style: TextStyle(color: Color(0xFF9CA3AF))),
                        const SizedBox(width: 6),
                        const Icon(Icons.schedule_rounded,
                            size: 13, color: Color(0xFF6B7280)),
                        const SizedBox(width: 3),
                        Text(
                          '${ride.eta}m',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('·',
                            style: TextStyle(color: Color(0xFF9CA3AF))),
                        const SizedBox(width: 6),
                        const Icon(Icons.person_rounded,
                            size: 13, color: Color(0xFF6B7280)),
                        const SizedBox(width: 2),
                        Text(
                          '${ride.capacity}',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Price & surge badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fareText,
                    style: const TextStyle(
                      color: ResultsScreenModern._ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (ride.surgeMultiplier > 1) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${ride.surgeMultiplier.toStringAsFixed(1)}x surge',
                        style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _providerIcon(FareEstimate ride) {
    if (ride.isBike) return Icons.two_wheeler_rounded;
    if (ride.isAuto) return Icons.electric_rickshaw_rounded;

    switch (ride.provider.toLowerCase()) {
      case 'rapido':
        return Icons.two_wheeler_rounded;
      case 'namma yatri':
        return Icons.electric_rickshaw_rounded;
      case 'uber':
        return Icons.directions_car_filled_rounded;
      case 'ola':
        return Icons.local_taxi_rounded;
      default:
        return Icons.local_taxi_rounded;
    }
  }

  Color _providerColor(FareEstimate ride) {
    switch (ride.provider.toLowerCase()) {
      case 'rapido':
        return const Color(0xFFD97706);
      case 'uber':
        return ResultsScreenModern._ink;
      case 'ola':
        return const Color(0xFF059669);
      case 'namma yatri':
        return const Color(0xFF2563EB);
      case 'indrive':
        return const Color(0xFF0D9488);
      default:
        return const Color(0xFF4B5563);
    }
  }

  Future<void> _confirmBooking(BuildContext context, FareEstimate ride) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.only(top: 40),
        padding: EdgeInsets.fromLTRB(
          22,
          16,
          22,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _providerColor(ride).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_providerIcon(ride),
                      color: _providerColor(ride), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.name,
                        style: const TextStyle(
                          color: ResultsScreenModern._ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${ride.provider} · ${ride.vehicleType}',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${ride.estimatedFare}',
                  style: const TextStyle(
                    color: ResultsScreenModern._ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location_rounded,
                          size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.pickup,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ResultsScreenModern._ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 16, color: Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.destination,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ResultsScreenModern._ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ResultsScreenModern._ink,
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ResultsScreenModern._yellow,
                      foregroundColor: ResultsScreenModern._ink,
                      minimumSize: const Size.fromHeight(52),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Open ${ride.provider}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await _openProvider(context, ride);
    if (!context.mounted) return;

    final provider = Provider.of<FareProvider>(context, listen: false);
    await provider.bookCab(
      userId: 'user123',
      estimate: ride,
      pickup: widget.pickup,
      destination: widget.destination,
    );
  }

  Future<void> _openProvider(BuildContext context, FareEstimate ride) async {
    final pickupLat = widget.pickupData['lat'];
    final pickupLng = widget.pickupData['lng'];
    final destinationLat = widget.destinationData['lat'];
    final destinationLng = widget.destinationData['lng'];
    String appUrl;
    String webUrl;

    switch (ride.provider.toLowerCase()) {
      case 'uber':
        appUrl =
            'uber://?action=setPickup&pickup[latitude]=$pickupLat&pickup[longitude]=$pickupLng&dropoff[latitude]=$destinationLat&dropoff[longitude]=$destinationLng';
        webUrl = 'https://m.uber.com/';
        break;
      case 'ola':
        appUrl =
            'olacabs://app/launch?lat=$pickupLat&lng=$pickupLng&drop_lat=$destinationLat&drop_lng=$destinationLng';
        webUrl = 'https://book.olacabs.com/';
        break;
      case 'rapido':
        appUrl =
            'rapido://ride?pickup_lat=$pickupLat&pickup_lng=$pickupLng&drop_lat=$destinationLat&drop_lng=$destinationLng';
        webUrl = 'https://www.rapido.bike/';
        break;
      case 'namma yatri':
        appUrl = 'in.juspay.nammayatri://app';
        webUrl =
            'https://play.google.com/store/apps/details?id=in.juspay.nammayatri';
        break;
      default:
        appUrl = 'indrive://';
        webUrl =
            'https://play.google.com/store/apps/details?id=sinet.startup.inDriver';
    }

    try {
      final appUri = Uri.parse(appUrl);
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(Uri.parse(webUrl),
            mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Couldn’t open ${ride.provider}.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
