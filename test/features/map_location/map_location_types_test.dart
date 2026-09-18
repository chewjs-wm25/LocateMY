import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/map_location/map_location.dart';

void main() {
  test('exposes an immutable location reference for analysis consumers', () {
    const location = ValidLocationReference(
      locationId: 'single-1',
      point: GeographicPoint(latitude: 3.139, longitude: 101.6869),
      displayName: 'Kuala Lumpur',
    );

    expect(location.locationId, 'single-1');
    expect(location.point.latitude, 3.139);
    expect(location.point.longitude, 101.6869);
    expect(location.displayName, 'Kuala Lumpur');
  });
}
