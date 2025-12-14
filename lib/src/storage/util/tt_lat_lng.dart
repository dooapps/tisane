class TTLatLng {
  const TTLatLng(this.latitude, this.longitude);
  final double latitude;
  final double longitude;

  @override
  String toString() => 'LatLng(lat: $latitude, lng: $longitude)';

  String serialize() => '$latitude,$longitude';

  @override
  int get hashCode => latitude.hashCode + longitude.hashCode;

  @override
  bool operator ==(other) =>
      other is TTLatLng &&
      latitude == other.latitude &&
      longitude == other.longitude;
}
