import 'dart:html';
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';

class MapScreen extends StatefulWidget {
  final String vendorName;
  final String location;
  final double vendorLat;
  final double vendorLng;

  const MapScreen({
    super.key,
    required this.vendorName,
    required this.location,
    required this.vendorLat,
    required this.vendorLng,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  // ── Warm Brown Palette (kept from your original) ─────────────────
  static const _bgPrimary   = Color(0xFFE1CBB1);
  static const _bgCard      = Color(0xFF976F47);
  static const _bgAccent    = Color(0xFF7B5836);
  static const _textSecond  = Color(0xFF4B3828);
  static const _textPrimary = Color(0xFF422A14);

  // ── State ────────────────────────────────────────────────────────
  double _radiusKm     = 50;
  String _activeFeature = 'map'; // 'map' | 'radius' | 'route' | 'streetview'
  bool   _isLoadingRoute = false;
  late AnimationController _slideAnim;
  late Animation<Offset>   _slideOffset;

  // In a real app, get buyer location from Geolocator
  // Hardcoded Chennai city centre as buyer location for demo
  static const double _buyerLat = 13.0827;
  static const double _buyerLng = 80.2707;

  @override
  void initState() {
    super.initState();
    _slideAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideOffset = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideAnim, curve: Curves.easeOutCubic));
    _registerAllMaps();
    _slideAnim.forward();
  }

  @override
  void dispose() {
    _slideAnim.dispose();
    super.dispose();
  }

  // ── Register all iframe views upfront ─────────────────────────────
  void _registerAllMaps() {
    // 1. Default embed map
    _registerView('default', _buildDefaultUrl());
    // 2. Street View
    _registerView('streetview', _buildStreetViewUrl());
    // 3. Radius map (custom static-style embed)
    _registerView('radius', _buildRadiusUrl());
    // 4. Route (Directions embed)
    _registerView('route', _buildRouteUrl());
  }

  void _registerView(String type, String url) {
    final viewId = 'map-${widget.vendorName}-$type';
    try {
      ui.platformViewRegistry.registerViewFactory(viewId, (int id) {
        final iframe = IFrameElement()
          ..src = url
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        return iframe;
      });
    } catch (_) {
      // Already registered (hot reload safe)
    }
  }

  // ── URL Builders ──────────────────────────────────────────────────
  static const _apiKey = 'AIzaSyASPNylgAyPF0_DWjTzM5NkbB-I-Ga6gL4'; // Replace this

  String _buildDefaultUrl() =>
      'https://www.google.com/maps/embed/v1/place'
      '?key=$_apiKey'
      '&q=${Uri.encodeComponent(widget.location)}'
      '&zoom=14';

  String _buildStreetViewUrl() =>
      'https://www.google.com/maps/embed/v1/streetview'
      '?key=$_apiKey'
      '&location=${widget.vendorLat},${widget.vendorLng}'
      '&heading=210'
      '&pitch=10'
      '&fov=90';

  String _buildRadiusUrl() {
    // Shows the vendor centered on map with zoom reflecting radius
    // Radius visual is shown via UI overlay (circle drawn in Stack)
    final zoom = _radiusKm <= 25
        ? 12
        : _radiusKm <= 75
            ? 10
            : _radiusKm <= 150
                ? 9
                : 8;
    return 'https://www.google.com/maps/embed/v1/place'
        '?key=$_apiKey'
        '&q=${widget.vendorLat},${widget.vendorLng}'
        '&zoom=$zoom';
  }

  String _buildRouteUrl() =>
      'https://www.google.com/maps/embed/v1/directions'
      '?key=$_apiKey'
      '&origin=$_buyerLat,$_buyerLng'
      '&destination=${widget.vendorLat},${widget.vendorLng}'
      '&mode=driving';

  // ── Helpers ───────────────────────────────────────────────────────
  double _estimateDistanceKm() {
    const r = 6371.0;
    final dLat = _toRad(widget.vendorLat - _buyerLat);
    final dLng = _toRad(widget.vendorLng - _buyerLng);
    final a = _sin2(dLat / 2) +
        _cos(_buyerLat) * _cos(widget.vendorLat) * _sin2(dLng / 2);
    return r * 2 * _atan2(a);
  }

  double _toRad(double d) => d * 3.141592653589793 / 180;
  double _sin2(double x) {
    final s = _sinApprox(x);
    return s * s;
  }
  double _sinApprox(double x) => x - x * x * x / 6;
  double _cos(double deg) {
    final r = _toRad(deg);
    return 1 - r * r / 2;
  }
  double _atan2(double a) => a < 0.5 ? (a * (1 + 0.27846 * a)) : 1.5707963;

  String _distanceLabel() {
    final d = _estimateDistanceKm();
    return d < 1 ? '<1 km away' : '~${d.toStringAsFixed(0)} km away';
  }

  String _travelTimeLabel() {
    final d = _estimateDistanceKm();
    final hrs = (d / 55).floor();
    final mins = ((d / 55 - hrs) * 60).round();
    if (hrs == 0) return '~${mins}m drive';
    return '~${hrs}h ${mins}m drive';
  }

  bool _isWithinRadius() => _estimateDistanceKm() <= _radiusKm;

  // ── Active view type string ───────────────────────────────────────
  String _viewType() {
    if (_activeFeature == 'radius')    return 'radius';
    if (_activeFeature == 'route')     return 'route';
    if (_activeFeature == 'streetview') return 'streetview';
    return 'default';
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPrimary,
      appBar: AppBar(
        backgroundColor: _textPrimary,
        title: Text(
          '${widget.vendorName} – Map',
          style: const TextStyle(
            color: Color(0xFFE1CBB1),
            fontWeight: FontWeight.w600,
            fontSize: 17,
            letterSpacing: 0.1,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFE1CBB1)),
        elevation: 0,
        actions: [
          // Street View quick action in app bar
          IconButton(
            icon: const Icon(Icons.streetview, color: Color(0xFFE1CBB1)),
            tooltip: 'Street View',
            onPressed: () => setState(() => _activeFeature =
                _activeFeature == 'streetview' ? 'map' : 'streetview'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Info Card ──────────────────────────────────────────────
          _InfoCard(
            vendorName: widget.vendorName,
            location: widget.location,
            distanceLabel: _distanceLabel(),
            travelLabel: _travelTimeLabel(),
            bgCard: _bgCard,
            bgPrimary: _bgPrimary,
          ),

          // ── Feature Tab Bar ────────────────────────────────────────
          _FeatureTabBar(
            active: _activeFeature,
            onSelect: (f) => setState(() {
              _activeFeature = f;
              // Re-register radius map when radius changes
              if (f == 'radius') _registerView('radius', _buildRadiusUrl());
            }),
            bgAccent: _bgAccent,
            textPrimary: _textPrimary,
            bgPrimary: _bgPrimary,
            textSecond: _textSecond,
          ),

          // ── Map Area ───────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                HtmlElementView(
                  viewType: 'map-${widget.vendorName}-${_viewType()}',
                ),
                // Thin top border overlay
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 3,
                    color: _bgAccent.withOpacity(0.35),
                  ),
                ),
                // Feature-specific overlay panels
                if (_activeFeature == 'radius')
                  _RadiusPanel(
                    radiusKm: _radiusKm,
                    isWithin: _isWithinRadius(),
                    onChanged: (v) => setState(() {
                      _radiusKm = v;
                      _registerView('radius', _buildRadiusUrl());
                    }),
                    bgPrimary: _bgPrimary,
                    bgCard: _bgCard,
                    bgAccent: _bgAccent,
                    textPrimary: _textPrimary,
                    textSecond: _textSecond,
                  ),
                if (_activeFeature == 'route')
                  _RouteInfoPanel(
                    distance: _distanceLabel(),
                    travel: _travelTimeLabel(),
                    bgPrimary: _bgPrimary,
                    bgCard: _bgCard,
                    textPrimary: _textPrimary,
                  ),
                if (_activeFeature == 'streetview')
                  _StreetViewBadge(bgAccent: _bgAccent, bgPrimary: _bgPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Sub-widgets
// ═══════════════════════════════════════════════════════════════════

class _InfoCard extends StatelessWidget {
  final String vendorName, location, distanceLabel, travelLabel;
  final Color bgCard, bgPrimary;
  const _InfoCard({
    required this.vendorName,
    required this.location,
    required this.distanceLabel,
    required this.travelLabel,
    required this.bgCard,
    required this.bgPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: bgCard,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF422A14).withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: bgPrimary.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.store_outlined,
                color: Color(0xFFE1CBB1), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vendorName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFFE1CBB1))),
                const SizedBox(height: 2),
                Text(location,
                    style: TextStyle(
                        color: bgPrimary.withOpacity(0.7), fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: bgPrimary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(distanceLabel,
                    style: TextStyle(
                        color: bgPrimary.withOpacity(0.95),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
              Text(travelLabel,
                  style: TextStyle(
                      color: bgPrimary.withOpacity(0.6), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Feature Tab Bar ────────────────────────────────────────────────
class _FeatureTabBar extends StatelessWidget {
  final String active;
  final ValueChanged<String> onSelect;
  final Color bgAccent, textPrimary, bgPrimary, textSecond;

  const _FeatureTabBar({
    required this.active,
    required this.onSelect,
    required this.bgAccent,
    required this.textPrimary,
    required this.bgPrimary,
    required this.textSecond,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: textPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _Tab(label: 'Map',        icon: Icons.map_outlined,          value: 'map',        active: active, onTap: onSelect, bgPrimary: bgPrimary, bgAccent: bgAccent),
          const SizedBox(width: 8),
          _Tab(label: 'Radius',     icon: Icons.radar,                 value: 'radius',     active: active, onTap: onSelect, bgPrimary: bgPrimary, bgAccent: bgAccent),
          const SizedBox(width: 8),
          _Tab(label: 'Route',      icon: Icons.alt_route,             value: 'route',      active: active, onTap: onSelect, bgPrimary: bgPrimary, bgAccent: bgAccent),
          const SizedBox(width: 8),
          _Tab(label: 'Street',     icon: Icons.streetview,            value: 'streetview', active: active, onTap: onSelect, bgPrimary: bgPrimary, bgAccent: bgAccent),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label, value, active;
  final IconData icon;
  final ValueChanged<String> onTap;
  final Color bgPrimary, bgAccent;

  const _Tab({
    required this.label, required this.icon, required this.value,
    required this.active, required this.onTap,
    required this.bgPrimary, required this.bgAccent,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = active == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? bgPrimary : bgPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? null
                : Border.all(color: bgPrimary.withOpacity(0.2), width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 18,
                  color: isActive
                      ? const Color(0xFF422A14)
                      : bgPrimary.withOpacity(0.65)),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: isActive
                          ? const Color(0xFF422A14)
                          : bgPrimary.withOpacity(0.65))),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Radius Panel ───────────────────────────────────────────────────
class _RadiusPanel extends StatelessWidget {
  final double radiusKm;
  final bool isWithin;
  final ValueChanged<double> onChanged;
  final Color bgPrimary, bgCard, bgAccent, textPrimary, textSecond;

  const _RadiusPanel({
    required this.radiusKm, required this.isWithin, required this.onChanged,
    required this.bgPrimary, required this.bgCard, required this.bgAccent,
    required this.textPrimary, required this.textSecond,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20, left: 16, right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: textPrimary.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.radar, color: Color(0xFFE1CBB1), size: 18),
                const SizedBox(width: 8),
                const Text('Search Radius',
                    style: TextStyle(
                        color: Color(0xFFE1CBB1),
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bgPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${radiusKm.toStringAsFixed(0)} km',
                      style: const TextStyle(
                          color: Color(0xFFE1CBB1),
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: bgPrimary,
                inactiveTrackColor: bgPrimary.withOpacity(0.25),
                thumbColor: bgPrimary,
                overlayColor: bgPrimary.withOpacity(0.15),
                trackHeight: 3,
              ),
              child: Slider(
                value: radiusKm,
                min: 10,
                max: 500,
                divisions: 49,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isWithin
                        ? Colors.green.withOpacity(0.25)
                        : Colors.red.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isWithin
                          ? Colors.green.withOpacity(0.5)
                          : Colors.red.withOpacity(0.4),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isWithin ? Icons.check_circle_outline : Icons.cancel_outlined,
                        color: isWithin ? Colors.greenAccent : Colors.redAccent,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isWithin
                            ? 'Vendor is within your radius'
                            : 'Vendor is outside your radius',
                        style: TextStyle(
                          color: isWithin ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Route Info Panel ───────────────────────────────────────────────
class _RouteInfoPanel extends StatelessWidget {
  final String distance, travel;
  final Color bgPrimary, bgCard, textPrimary;

  const _RouteInfoPanel({
    required this.distance, required this.travel,
    required this.bgPrimary, required this.bgCard, required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20, left: 16, right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: textPrimary.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.alt_route, color: Color(0xFFE1CBB1), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Driving Route',
                      style: TextStyle(
                          color: Color(0xFFE1CBB1),
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 3),
                  Text('Your location → Vendor factory',
                      style: TextStyle(
                          color: bgPrimary.withOpacity(0.6), fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(distance,
                    style: const TextStyle(
                        color: Color(0xFFE1CBB1),
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(travel,
                    style: TextStyle(
                        color: bgPrimary.withOpacity(0.65), fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Street View Badge ──────────────────────────────────────────────
class _StreetViewBadge extends StatelessWidget {
  final Color bgAccent, bgPrimary;
  const _StreetViewBadge({required this.bgAccent, required this.bgPrimary});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12, left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bgAccent.withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.streetview, color: Color(0xFFE1CBB1), size: 14),
            const SizedBox(width: 6),
            Text('Street View — Factory Entrance',
                style: TextStyle(
                    color: bgPrimary.withOpacity(0.95),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}