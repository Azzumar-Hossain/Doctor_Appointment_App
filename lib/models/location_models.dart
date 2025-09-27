class Division {
  final int id;
  final String name;
  final List<District> districts;

  Division({required this.id, required this.name, required this.districts});

  factory Division.fromJson(Map<String, dynamic> json) {
    return Division(
      id: json['id'],
      name: json['name'],
      districts: (json['district'] as List<dynamic>)
          .map((d) => District.fromJson(d))
          .toList(),
    );
  }
}

class District {
  final int id;
  final String name;
  final List<Upazila> upazilas;

  District({required this.id, required this.name, required this.upazilas});

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'],
      name: json['district_name'],
      upazilas: (json['upazila'] as List<dynamic>)
          .map((u) => Upazila.fromJson(u))
          .toList(),
    );
  }
}

class Upazila {
  final int id;
  final String name;
  final List<Union> unions;

  Upazila({required this.id, required this.name, required this.unions});

  factory Upazila.fromJson(Map<String, dynamic> json) {
    return Upazila(
      id: json['id'],
      name: json['upazila_name'],
      unions: (json['union'] as List<dynamic>)
          .map((u) => Union.fromJson(u))
          .toList(),
    );
  }
}

class Union {
  final int id;
  final String name;

  Union({required this.id, required this.name});

  factory Union.fromJson(Map<String, dynamic> json) {
    return Union(id: json['id'], name: json['union_name']);
  }
}
