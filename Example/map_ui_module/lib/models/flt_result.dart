// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class FLTResult {
  int index;
  int x;
  int y;
  double absoluteHeading;
  FLTResult({
    required this.index,
    required this.x,
    required this.y,
    required this.absoluteHeading,
  });

  FLTResult copyWith({
    int? index,
    int? x,
    int? y,
    double? absoluteHeading,
  }) {
    return FLTResult(
      index: index ?? this.index,
      x: x ?? this.x,
      y: y ?? this.y,
      absoluteHeading: absoluteHeading ?? this.absoluteHeading,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'index': index,
      'x': x,
      'y': y,
      'absoluteHeading': absoluteHeading,
    };
  }

  factory FLTResult.fromMap(Map<String, dynamic> map) {
    return FLTResult(
      index: map['index'] as int,
      x: map['x'] as int,
      y: map['y'] as int,
      absoluteHeading: map['absoluteHeading'] as double,
    );
  }

  String toJson() => json.encode(toMap());

  factory FLTResult.fromJson(String source) => FLTResult.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'FLTResult(index: $index, x: $x, y: $y, absoluteHeading: $absoluteHeading)';
  }

  @override
  bool operator ==(covariant FLTResult other) {
    if (identical(this, other)) return true;

    return other.index == index && other.x == x && other.y == y && other.absoluteHeading == absoluteHeading;
  }

  @override
  int get hashCode {
    return index.hashCode ^ x.hashCode ^ y.hashCode ^ absoluteHeading.hashCode;
  }
}

List<FLTResult> testDataset = [
  FLTResult(index: 82, x: 6, y: 7, absoluteHeading: 212.03101176342858),
  FLTResult(index: 83, x: 6, y: 7, absoluteHeading: 201.57130853840602),
  FLTResult(index: 84, x: 6, y: 6, absoluteHeading: 235.44885767805937),
  FLTResult(index: 84, x: 6, y: 9, absoluteHeading: 0.0),
  FLTResult(index: 85, x: 6, y: 10, absoluteHeading: 96.39423051947077),
  FLTResult(index: 86, x: 6, y: 10, absoluteHeading: 85.32326819412326),
  FLTResult(index: 87, x: 6, y: 11, absoluteHeading: 90.92258238773972),
  FLTResult(index: 88, x: 6, y: 12, absoluteHeading: 82.36993872596081),
  FLTResult(index: 88, x: 6, y: 10, absoluteHeading: 90.0),
  FLTResult(index: 89, x: 6, y: 11, absoluteHeading: 96.27244980723167),
  FLTResult(index: 90, x: 6, y: 11, absoluteHeading: 88.78560150446091),
  FLTResult(index: 91, x: 6, y: 12, absoluteHeading: 91.28973976393975),
  FLTResult(index: 92, x: 6, y: 13, absoluteHeading: 65.99274424152152),
  FLTResult(index: 92, x: 8, y: 16, absoluteHeading: 112.05694624712376),
  FLTResult(index: 93, x: 8, y: 16, absoluteHeading: 89.0582135461427),
  FLTResult(index: 94, x: 8, y: 16, absoluteHeading: 73.38746899037682),
  FLTResult(index: 95, x: 9, y: 16, absoluteHeading: 47.85754089831988),
  FLTResult(index: 96, x: 9, y: 16, absoluteHeading: 46.15896620466913),
  FLTResult(index: 97, x: 10, y: 16, absoluteHeading: 38.73231778603878),
  FLTResult(index: 98, x: 10, y: 16, absoluteHeading: 39.74246016467225),
  FLTResult(index: 99, x: 11, y: 16, absoluteHeading: 19.22140005638505),
  FLTResult(index: 100, x: 11, y: 16, absoluteHeading: 0.23678402250135377),
  FLTResult(index: 100, x: 6, y: 16, absoluteHeading: 270.0),
  FLTResult(index: 101, x: 6, y: 15, absoluteHeading: 229.3694890746499),
  FLTResult(index: 102, x: 6, y: 15, absoluteHeading: 223.50934863138474),
  FLTResult(index: 103, x: 6, y: 15, absoluteHeading: 223.06820466799485),
  FLTResult(index: 104, x: 6, y: 14, absoluteHeading: 224.92001351744833),
  FLTResult(index: 104, x: 11, y: 15, absoluteHeading: 279.0036724892138),
  FLTResult(index: 105, x: 11, y: 14, absoluteHeading: 273.7159407949295),
  FLTResult(index: 106, x: 11, y: 14, absoluteHeading: 283.00977773189504),
  FLTResult(index: 107, x: 11, y: 13, absoluteHeading: 280.6677526422513),
  FLTResult(index: 108, x: 11, y: 12, absoluteHeading: 287.8462824090742),
  FLTResult(index: 108, x: 11, y: 12, absoluteHeading: 284.1266056809931),
  FLTResult(index: 109, x: 11, y: 11, absoluteHeading: 276.8465436723601),
  FLTResult(index: 110, x: 11, y: 11, absoluteHeading: 283.0367673918646),
  FLTResult(index: 111, x: 11, y: 10, absoluteHeading: 277.1549136060721),
  FLTResult(index: 112, x: 11, y: 9, absoluteHeading: 281.6828561619351),
  FLTResult(index: 112, x: 11, y: 8, absoluteHeading: 288.28525522021687),
  FLTResult(index: 113, x: 11, y: 7, absoluteHeading: 277.14922973629626),
  FLTResult(index: 114, x: 11, y: 7, absoluteHeading: 259.38334811966894),
  FLTResult(index: 115, x: 10, y: 6, absoluteHeading: 218.9830936266667),
  FLTResult(index: 116, x: 10, y: 6, absoluteHeading: 203.75394192294553),
  FLTResult(index: 116, x: 11, y: 7, absoluteHeading: 270.67717229215924),
  FLTResult(index: 117, x: 11, y: 6, absoluteHeading: 257.2850242864804),
  FLTResult(index: 117, x: 11, y: 6, absoluteHeading: 255.81296684234337),
  FLTResult(index: 118, x: 11, y: 6, absoluteHeading: 263.45660027977635),
  FLTResult(index: 119, x: 11, y: 6, absoluteHeading: 253.36394590706993),
  FLTResult(index: 120, x: 10, y: 6, absoluteHeading: 254.73545336504785),
  FLTResult(index: 121, x: 10, y: 6, absoluteHeading: 234.95577068641538),
  FLTResult(index: 122, x: 10, y: 6, absoluteHeading: 219.8805227290611),
  FLTResult(index: 123, x: 9, y: 6, absoluteHeading: 179.01222918148773),
  FLTResult(index: 124, x: 8, y: 6, absoluteHeading: 172.73856316133077),
  FLTResult(index: 125, x: 7, y: 6, absoluteHeading: 165.41704973755816),
  FLTResult(index: 126, x: 7, y: 6, absoluteHeading: 171.2846162002238),
  FLTResult(index: 126, x: 6, y: 6, absoluteHeading: 114.29983410928463),
  FLTResult(index: 127, x: 6, y: 6, absoluteHeading: 121.04951039731401),
  FLTResult(index: 128, x: 6, y: 6, absoluteHeading: 127.46537452322066),
  FLTResult(index: 129, x: 6, y: 7, absoluteHeading: 118.78411778219198),
  FLTResult(index: 130, x: 6, y: 7, absoluteHeading: 126.8760394158309),
  FLTResult(index: 131, x: 6, y: 8, absoluteHeading: 118.3687535469237),
  FLTResult(index: 132, x: 6, y: 8, absoluteHeading: 124.51248681145458),
  FLTResult(index: 133, x: 6, y: 9, absoluteHeading: 115.32404142469312),
  FLTResult(index: 134, x: 6, y: 10, absoluteHeading: 117.60974514650401),
  FLTResult(index: 135, x: 6, y: 10, absoluteHeading: 114.47593275660103),
  FLTResult(index: 136, x: 6, y: 11, absoluteHeading: 110.30571358175662),
  FLTResult(index: 137, x: 6, y: 12, absoluteHeading: 96.81581258950777),
  FLTResult(index: 138, x: 6, y: 12, absoluteHeading: 73.23455047825266),
  FLTResult(index: 138, x: 6, y: 14, absoluteHeading: 59.41089987935028),
  FLTResult(index: 139, x: 6, y: 15, absoluteHeading: 33.403211655575774),
  FLTResult(index: 140, x: 6, y: 15, absoluteHeading: 31.20820465002015),
  FLTResult(index: 141, x: 8, y: 16, absoluteHeading: 19.640560590002792),
  FLTResult(index: 142, x: 8, y: 16, absoluteHeading: 24.493796885835877),
  FLTResult(index: 143, x: 9, y: 16, absoluteHeading: 20.39847811124082),
  FLTResult(index: 144, x: 10, y: 16, absoluteHeading: 14.863964761986722),
  FLTResult(index: 145, x: 10, y: 16, absoluteHeading: 329.2832612329058),
  FLTResult(index: 146, x: 11, y: 16, absoluteHeading: 312.3896634572556),
  FLTResult(index: 147, x: 11, y: 15, absoluteHeading: 283.83158343470404),
  FLTResult(index: 148, x: 11, y: 14, absoluteHeading: 295.2648099413533),
  FLTResult(index: 148, x: 11, y: 15, absoluteHeading: 283.5027484251968),
  FLTResult(index: 149, x: 11, y: 14, absoluteHeading: 292.9522426399956),
  FLTResult(index: 150, x: 12, y: 13, absoluteHeading: 297.90352162065744),
  FLTResult(index: 151, x: 11, y: 13, absoluteHeading: 227.89687316662057),
  FLTResult(index: 152, x: 11, y: 13, absoluteHeading: 197.7998111160029),
  FLTResult(index: 153, x: 11, y: 13, absoluteHeading: 190.24540035893213),
  FLTResult(index: 154, x: 11, y: 12, absoluteHeading: 203.9997300818021),
  FLTResult(index: 155, x: 11, y: 12, absoluteHeading: 236.2926680368415),
  FLTResult(index: 156, x: 11, y: 11, absoluteHeading: 273.49310952647295),
  FLTResult(index: 157, x: 11, y: 11, absoluteHeading: 303.532686174952),
  FLTResult(index: 158, x: 11, y: 10, absoluteHeading: 349.05490383633656),
  FLTResult(index: 159, x: 11, y: 11, absoluteHeading: 5.743183999154098),
  FLTResult(index: 159, x: 11, y: 11, absoluteHeading: 4.031724513381505),
  FLTResult(index: 160, x: 13, y: 11, absoluteHeading: 16.930971799379996),
  FLTResult(index: 161, x: 13, y: 11, absoluteHeading: 354.7736962758376),
  FLTResult(index: 162, x: 13, y: 11, absoluteHeading: 331.6241523820867),
  FLTResult(index: 163, x: 14, y: 9, absoluteHeading: 283.4158296279319),
  FLTResult(index: 164, x: 14, y: 9, absoluteHeading: 276.36741239924925)
];
