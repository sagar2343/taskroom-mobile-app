import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../config/constant/google_places_constants.dart';

/// One autocomplete suggestion — mirrors what the search box shows on a
/// real map app: a bold primary line (place name) and a lighter secondary
/// line (the rest of the address), plus the placeId needed to resolve it
/// to real coordinates via [PlacesAutocompleteService.getPlaceDetails].
class PlaceSuggestion {
  final String placeId;
  final String primaryText;
  final String secondaryText;

  const PlaceSuggestion({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
  });

  String get fullText =>
      secondaryText.isEmpty ? primaryText : '$primaryText, $secondaryText';
}

/// Result of resolving a [PlaceSuggestion] to actual coordinates.
class PlaceDetails {
  final double latitude;
  final double longitude;
  final String address;

  const PlaceDetails({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class PlacesAutocompleteService {
  static const _uuid = Uuid();

  /// Google bills autocomplete+details as one cheaper "session" if the same
  /// sessionToken is reused across every keystroke of one search, then a
  /// details call closes it out. Call [newSession] once when the user starts
  /// typing a fresh search (screen open, or right after a place is picked).
  String? _sessionToken;

  void newSession() => _sessionToken = _uuid.v4();

  /// Searches for places matching [query]. Optionally biased toward
  /// [biasLat]/[biasLng] (e.g. the user's current map position) so nearby
  /// results rank higher — same idea as how Google Maps itself biases
  /// results toward wherever you're currently looking.
  Future<List<PlaceSuggestion>> search(
      String query, {
        double? biasLat,
        double? biasLng,
      }) async {
    if (GooglePlacesConstants.apiKey.isEmpty) {
      debugPrint('[Places] ERROR: apiKey is empty — did you forget '
          '--dart-define-from-file=secrets.json when building/running?');
      return [];
    }

    _sessionToken ??= _uuid.v4();

    try {
      final body = <String, dynamic>{
        'input': query,
        'sessionToken': _sessionToken,
        // Field-work SaaS is India-focused — restrict results to India so
        // "Main Street" style queries don't return other countries first.
        'includedRegionCodes': ['in'],
        if (biasLat != null && biasLng != null)
          'locationBias': {
            'circle': {
              'center': {'latitude': biasLat, 'longitude': biasLng},
              'radius': 50000.0, // 50 km — nudges ranking, doesn't hard-filter
            },
          },
      };

      final response = await http.post(
        Uri.parse(GooglePlacesConstants.autocompleteUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': GooglePlacesConstants.apiKey,
          'X-Goog-FieldMask':
          'suggestions.placePrediction.placeId,'
              'suggestions.placePrediction.structuredFormat',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        debugPrint('[Places] autocomplete failed ${response.statusCode}: ${response.body}');
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final suggestions = (data['suggestions'] as List?) ?? [];

      return suggestions
          .map((s) {
        final pred = s['placePrediction'] as Map<String, dynamic>?;
        if (pred == null) return null;
        final structured = pred['structuredFormat'] as Map<String, dynamic>?;
        return PlaceSuggestion(
          placeId: pred['placeId'] as String? ?? '',
          primaryText: structured?['mainText']?['text'] as String? ?? '',
          secondaryText: structured?['secondaryText']?['text'] as String? ?? '',
        );
      })
          .whereType<PlaceSuggestion>()
          .where((s) => s.placeId.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[Places] autocomplete error: $e');
      return [];
    }
  }

  /// Resolves a picked [PlaceSuggestion] to real coordinates. This also
  /// closes out the billing session — call [newSession] again before the
  /// next search.
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final response = await http.get(
        Uri.parse(GooglePlacesConstants.placeDetailsUrl(placeId))
            .replace(queryParameters: {'sessionToken': _sessionToken}),
        headers: {
          'X-Goog-Api-Key': GooglePlacesConstants.apiKey,
          'X-Goog-FieldMask': 'location,formattedAddress',
        },
      );

      _sessionToken = null; // session closed — next search starts a fresh one

      if (response.statusCode != 200) {
        debugPrint('[Places] details failed ${response.statusCode}: ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final location = data['location'] as Map<String, dynamic>?;
      if (location == null) return null;

      return PlaceDetails(
        latitude: (location['latitude'] as num).toDouble(),
        longitude: (location['longitude'] as num).toDouble(),
        address: data['formattedAddress'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('[Places] details error: $e');
      return null;
    }
  }
}