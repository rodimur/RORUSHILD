class VisitedDomain {
  final int? id;
  final String url;
  final String domain;
  final String? path;
  final DateTime timestamp;
  final bool isSafe;

  VisitedDomain({
    this.id,
    required this.url,
    required this.domain,
    this.path,
    required this.timestamp,
    required this.isSafe,
  });

  factory VisitedDomain.fromMap(Map<String, dynamic> map) {
    return VisitedDomain(
      id: map['id'] as int?,
      url: map['url'] as String,
      domain: map['domain'] as String,
      path: map['path'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      isSafe: map['isSafe'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'domain': domain,
      'path': path,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isSafe': isSafe ? 1 : 0,
    };
  }

  // SQLite için JSON dönüşümleri
  factory VisitedDomain.fromJson(Map<String, dynamic> json) => VisitedDomain(
    id: json['id'] as int?,
    url: json['url'] as String,
    domain: json['domain'] as String,
    path: json['path'] as String?,
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    isSafe: json['isSafe'] == 1,
  );

  Map<String, dynamic> toJson() => {
    'url': url,
    'domain': domain,
    'path': path,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'isSafe': isSafe ? 1 : 0,
  };

  VisitedDomain copyWith({
    int? id,
    String? url,
    String? domain,
    String? path,
    DateTime? timestamp,
    bool? isSafe,
  }) {
    return VisitedDomain(
      id: id ?? this.id,
      url: url ?? this.url,
      domain: domain ?? this.domain,
      path: path ?? this.path,
      timestamp: timestamp ?? this.timestamp,
      isSafe: isSafe ?? this.isSafe,
    );
  }
} 