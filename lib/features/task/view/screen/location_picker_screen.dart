import 'dart:async';
import 'package:field_work/features/task/model/task_form_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../config/theme/app_pallete.dart';
import '../../data/places_autocomplete_service.dart';

class LocationPickerScreen extends StatefulWidget {
  final PickedLocation? initial;
  const LocationPickerScreen({super.key, this.initial});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapCtrl;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  LatLng? _pinned;
  String? _address;
  bool _geocoding = false;
  bool _locating = false;
  bool _showSuggestions = false;
  bool _searching = false;
  List<PlaceSuggestion> _suggestions = [];
  final _places = PlacesAutocompleteService();
  Timer? _debounce;
  late AnimationController _panelAnim;
  late Animation<double> _panelSlide;

  static const _kInitialIndia = CameraPosition(target: LatLng(20.5937, 78.9629), zoom: 5);

  @override
  void initState() {
    super.initState();
    _places.newSession();
    _panelAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _panelSlide = CurvedAnimation(parent: _panelAnim, curve: Curves.easeOutCubic);

    if (widget.initial != null) {
      _pinned = LatLng(widget.initial!.latitude, widget.initial!.longitude);
      _address = widget.initial!.address;
      _panelAnim.forward();
    }
    _goToMyLocation();
  }

  @override
  void dispose() {
    _mapCtrl?.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    _panelAnim.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  //  PERMISSION
  // ─────────────────────────────────────────────────────────

  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied) {
        _showMsg('Location permission denied');
        return;
      }

      if (perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        _showPermPermanentDialog();
        return;
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        _showMsg('Please enable location services');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final ll = LatLng(pos.latitude, pos.longitude);
      await _pin(ll);
      _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(ll, 17));
    } catch (e) {
      _showMsg('Could not get your location');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showPermPermanentDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Location Permission Required'),
        content: const Text(
            'Location access is permanently denied. Please open Settings and enable it for this app.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  MAP INTERACTION
  // ─────────────────────────────────────────────────────────

  Future<void> _pin(LatLng ll) async {
    setState(() {
      _pinned = ll;
      _address = null;
      _geocoding = true;
    });
    if (_pinned != null) _panelAnim.forward();

    try {
      final marks = await placemarkFromCoordinates(ll.latitude, ll.longitude);
      if (marks.isNotEmpty && mounted) {
        final p = marks.first;
        final parts = [p.name, p.subLocality, p.locality, p.administrativeArea]
            .where((s) => s != null && s.isNotEmpty)
            .toList();
        setState(() => _address = parts.join(', '));
      }
    } catch (_) {
      // geocoding failed — lat/lng still captured
    } finally {
      if (mounted) setState(() => _geocoding = false);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  SEARCH
  // ─────────────────────────────────────────────────────────

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 3) {
      setState(() { _suggestions = []; _showSuggestions = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() => _searching = true);

    final results = await _places.search(
      q,
      // Bias toward wherever the user is currently looking on the map —
      // falls back to no bias (India-wide) if nothing's pinned/moved yet.
      biasLat: _pinned?.latitude,
      biasLng: _pinned?.longitude,
    );

    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _showSuggestions = results.isNotEmpty;
      _searching = false;
    });
  }

  Future<void> _pickSuggestion(PlaceSuggestion s) async {
    _searchCtrl.text = s.primaryText;
    _searchFocus.unfocus();
    setState(() => _showSuggestions = false);

    setState(() => _geocoding = true);
    final details = await _places.getPlaceDetails(s.placeId);
    // Next search (if any) should start a brand-new billing session.
    _places.newSession();

    if (!mounted) return;

    if (details == null) {
      setState(() => _geocoding = false);
      _showMsg('Could not load that place — please try another result');
      return;
    }

    final ll = LatLng(details.latitude, details.longitude);
    setState(() {
      _pinned = ll;
      _address = details.address.isNotEmpty ? details.address : s.fullText;
      _geocoding = false;
    });
    _panelAnim.forward();
    _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(ll, 16));
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safePad = MediaQuery.of(context).padding;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            // ── MAP
            GoogleMap(
              initialCameraPosition: _pinned != null
                  ? CameraPosition(target: _pinned!, zoom: 15)
                  : _kInitialIndia,
              onMapCreated: (c) => _mapCtrl = c,
              onTap: _pin,
              markers: _pinned == null
                  ? {}
                  : {
                Marker(
                  markerId: const MarkerId('dest'),
                  position: _pinned!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
                )
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),

            // ── TOP: back + search bar
            Positioned(
              top: safePad.top + 12,
              left: 12,
              right: 12,
              child: Column(
                children: [
                  Row(
                    children: [
                      // Back
                      _FloatBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 10),
                      // Search
                      Expanded(
                        child: _SearchBar(
                          controller: _searchCtrl,
                          focusNode: _searchFocus,
                          onChanged: _onSearchChanged,
                          onClear: () {
                            _searchCtrl.clear();
                            _debounce?.cancel();
                            setState(() { _showSuggestions = false; _searching = false; _suggestions = []; });
                          },
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  // ── Suggestions dropdown
                  if (_showSuggestions || _searching)
                    _SuggestionsPanel(
                      suggestions: _suggestions,
                      loading: _searching,
                      onTap: _pickSuggestion,
                      isDark: isDark,
                    ),
                ],
              ),
            ),

            // ── TAP HINT (when nothing pinned)
            if (_pinned == null)
              const Center(
                child: IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded, color: Colors.white70, size: 52),
                      SizedBox(height: 10),
                      _HintPill('Tap the map to pin destination'),
                    ],
                  ),
                ),
              ),

            // ── RIGHT: zoom + locate buttons
            Positioned(
              right: 14,
              bottom: _pinned != null ? 270 : 120,
              child: Column(
                children: [
                  _FloatBtn(
                    icon: _locating ? null : Icons.my_location_rounded,
                    isLoading: _locating,
                    onTap: _goToMyLocation,
                    accent: Pallete.primaryColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _FloatBtn(
                    icon: Icons.add_rounded,
                    onTap: () => _mapCtrl?.animateCamera(CameraUpdate.zoomIn()),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _FloatBtn(
                    icon: Icons.remove_rounded,
                    onTap: () => _mapCtrl?.animateCamera(CameraUpdate.zoomOut()),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            // ── BOTTOM: confirm panel (slides up)
            if (_pinned != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                      .animate(_panelSlide),
                  child: _ConfirmPanel(
                    lat: _pinned!.latitude,
                    lng: _pinned!.longitude,
                    address: _address,
                    geocoding: _geocoding,
                    onConfirm: () => Navigator.pop(
                      context,
                      PickedLocation(
                        latitude: _pinned!.latitude,
                        longitude: _pinned!.longitude,
                        address: _address,
                      ),
                    ),
                    onClear: () {
                      setState(() { _pinned = null; _address = null; });
                      _panelAnim.reverse();
                    },
                    isDark: isDark,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
//  Search bar widget
// ─────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isDark;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.18), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: 'Search location or address...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Pallete.primaryColor),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18), onPressed: onClear)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 15),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
//  Suggestions panel
// ─────────────────────────────────────────────────────────────────────

class _SuggestionsPanel extends StatelessWidget {
  final List<PlaceSuggestion> suggestions;
  final bool loading;
  final ValueChanged<PlaceSuggestion> onTap;
  final bool isDark;

  const _SuggestionsPanel({
    required this.suggestions,
    required this.onTap,
    required this.isDark,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      constraints: const BoxConstraints(maxHeight: 280), // ~4-5 rows, scrolls beyond that
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.15), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: loading && suggestions.isEmpty
            ? const Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Center(
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Pallete.primaryColor),
            ),
          ),
        )
            : ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.grey.withValues(alpha:0.1)),
          itemBuilder: (_, i) {
            final s = suggestions[i];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.location_on_rounded, size: 18, color: Pallete.primaryColor),
              title: Text(
                s.primaryText,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: s.secondaryText.isEmpty
                  ? null
                  : Text(
                s.secondaryText,
                style: TextStyle(
                    fontSize: 12,
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha:0.5)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => onTap(s),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
//  Confirm panel (slides up when pin placed)
// ─────────────────────────────────────────────────────────────────────

class _ConfirmPanel extends StatelessWidget {
  final double lat, lng;
  final String? address;
  final bool geocoding;
  final VoidCallback onConfirm;
  final VoidCallback onClear;
  final bool isDark;

  const _ConfirmPanel({
    required this.lat,
    required this.lng,
    required this.address,
    required this.geocoding,
    required this.onConfirm,
    required this.onClear,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.2), blurRadius: 24, offset: const Offset(0, -6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha:0.3),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Pallete.primaryColor.withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.location_on_rounded, color: Pallete.primaryColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SELECTED DESTINATION',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Pallete.primaryColor, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    if (geocoding)
                      Row(children: [
                        SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: const AlwaysStoppedAnimation(Pallete.primaryColor)),
                        ),
                        const SizedBox(width: 8),
                        Text('Getting address...', style: TextStyle(fontSize: 13, color: Colors.grey.withValues(alpha:0.7))),
                      ])
                    else
                      Text(
                        address ?? 'Location pinned',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Clear pin
              IconButton(
                icon: Icon(Icons.close_rounded, color: Colors.grey.withValues(alpha:0.6), size: 20),
                onPressed: onClear,
                splashRadius: 20,
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: onConfirm,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Pallete.primaryColor, Pallete.primaryLightColor]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Pallete.primaryColor.withValues(alpha:0.35), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text('Confirm Destination', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
//  Floating action button
// ─────────────────────────────────────────────────────────────────────

class _FloatBtn extends StatelessWidget {
  final IconData? icon;
  final VoidCallback onTap;
  final Color? accent;
  final bool isLoading;
  final bool isDark;

  const _FloatBtn({
    required this.onTap,
    this.icon,
    this.accent,
    this.isLoading = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.18), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: isLoading
            ? Padding(
          padding: const EdgeInsets.all(13),
          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(accent ?? Pallete.primaryColor)),
        )
            : Icon(icon, size: 20, color: accent ?? (isDark ? Colors.white70 : Colors.black54)),
      ),
    );
  }
}

class _HintPill extends StatelessWidget {
  final String text;
  const _HintPill(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha:0.65),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
  );
}