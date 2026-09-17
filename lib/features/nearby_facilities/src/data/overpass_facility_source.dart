// Explicit constructors follow Development Standard §7.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:locatemy/features/map_location/map_location.dart';

import '../domain/facility_models.dart';

OverpassFacilitySource createOverpassFacilitySource(
  http.Client client, {
  Uri? endpoint,
}) {
  return HttpOverpassFacilitySource(client, endpoint: endpoint);
}

final class HttpOverpassFacilitySource implements OverpassFacilitySource {
  final http.Client client;
  final Uri endpoint;
  HttpOverpassFacilitySource(http.Client client, {Uri? endpoint})
    : client = client,
      endpoint =
          endpoint ?? Uri.parse('https://overpass-api.de/api/interpreter');

  @override
  Future<OverpassFacilityOutcome> query(OverpassFacilityQuery query) async {
    try {
      final http.Response response = await client
          .post(
            endpoint,
            headers: const <String, String>{
              'user-agent':
                  'LocateMY/1.0 (https://github.com/chewjs-wm25/LocateMY)',
              'content-type':
                  'application/x-www-form-urlencoded; charset=utf-8',
            },
            body: <String, String>{'data': _query(query)},
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 429) {
        return const OverpassFacilityFailed(
          failure: OverpassFailure.rateLimited,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const OverpassFacilityFailed(
          failure: OverpassFailure.networkUnavailable,
        );
      }
      final Object? decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return const OverpassFacilityFailed(
          failure: OverpassFailure.invalidPayload,
        );
      }
      final Map<String, dynamic> payload = Map<String, dynamic>.from(decoded);
      if (payload['remark'] != null) {
        return const OverpassFacilityPartial(
          failure: OverpassFailure.responseTruncated,
        );
      }
      final Object? raw = payload['elements'];
      if (raw is! List) {
        return const OverpassFacilityFailed(
          failure: OverpassFailure.invalidPayload,
        );
      }
      final List<OverpassElement> elements = <OverpassElement>[];
      for (final Object? value in raw) {
        final OverpassElement? element = _element(value);
        if (element == null) {
          return const OverpassFacilityFailed(
            failure: OverpassFailure.invalidPayload,
          );
        }
        elements.add(element);
      }
      return OverpassFacilityComplete(
        elements: elements,
        queriedAt: DateTime.now().toUtc(),
      );
    } on http.ClientException {
      return const OverpassFacilityFailed(
        failure: OverpassFailure.networkUnavailable,
      );
    } on TimeoutException {
      return const OverpassFacilityFailed(failure: OverpassFailure.timeout);
    } on FormatException {
      return const OverpassFacilityFailed(
        failure: OverpassFailure.invalidPayload,
      );
    } catch (_) {
      return const OverpassFacilityFailed(
        failure: OverpassFailure.networkUnavailable,
      );
    }
  }

  String _query(OverpassFacilityQuery query) {
    final String centre =
        '${query.centre.latitude.toStringAsFixed(6)},${query.centre.longitude.toStringAsFixed(6)}';
    final String radius = query.radiusMetres.toString();
    return '[out:json][timeout:18];(nwr(around:$radius,$centre)[amenity];nwr(around:$radius,$centre)[shop];nwr(around:$radius,$centre)[highway=bus_stop];nwr(around:$radius,$centre)[public_transport];nwr(around:$radius,$centre)[railway];nwr(around:$radius,$centre)[leisure];);out center tags;';
  }

  OverpassElement? _element(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final Map<String, dynamic> value = Map<String, dynamic>.from(raw);
    final String? elementType = value['type'] is String
        ? value['type'] as String
        : null;
    if (!const <String>{'node', 'way', 'relation'}.contains(elementType) ||
        value['id'] is! int ||
        (value['id'] as int) <= 0 ||
        value['tags'] is! Map) {
      return null;
    }
    Map<String, dynamic> coordinates = value;
    if (elementType != 'node') {
      if (value['center'] is! Map) {
        return null;
      }
      coordinates = Map<String, dynamic>.from(value['center'] as Map);
    }
    final double? latitude = _number(coordinates['lat']);
    final double? longitude = _number(coordinates['lon']);
    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      return null;
    }
    final Map<String, String> tags = <String, String>{};
    final Map<dynamic, dynamic> rawTags = value['tags'] as Map;
    for (final MapEntry<dynamic, dynamic> entry in rawTags.entries) {
      if (entry.key is! String || entry.value is! String) {
        return null;
      }
      tags[entry.key as String] = entry.value as String;
    }
    return OverpassElement(
      elementType: elementType!,
      osmId: value['id'].toString(),
      representativePoint: GeographicPoint(
        latitude: latitude,
        longitude: longitude,
      ),
      tags: Map<String, String>.unmodifiable(tags),
    );
  }

  double? _number(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }
}
