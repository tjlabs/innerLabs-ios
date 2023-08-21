// ignore_for_file: public_member_api_docs, sort_constructors_first
class MapComponent {
  double width;
  double height;
  final double _offsetX;
  final double _offsetY;
  String imageURL;

  double get offsetX => _offsetX;
  double get offsetY => _offsetY;
  MapComponent({
    required this.width,
    required this.height,
    required double offsetX,
    required double offsetY,
    required this.imageURL,
  })  : _offsetX = offsetX,
        _offsetY = offsetY;
}
