// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class PP {
  int x;
  int y;
  PP(
    this.x,
    this.y,
  );

  PP copyWith({
    int? x,
    int? y,
  }) {
    return PP(
      x ?? this.x,
      y ?? this.y,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'x': x,
      'y': y,
    };
  }

  factory PP.fromMap(Map<String, dynamic> map) {
    return PP(
      map['x'] as int,
      map['y'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory PP.fromJson(String source) => PP.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'PP(x: $x, y: $y)';

  @override
  bool operator ==(covariant PP other) {
    if (identical(this, other)) return true;

    return other.x == x && other.y == y;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}
