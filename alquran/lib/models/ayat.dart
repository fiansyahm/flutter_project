class Ayat {
  final int id;
  final int surah;
  final int nomor;
  final String ar; // Teks Arab
  final String tr; // Teks transliterasi
  final String idn; // Terjemahan dalam bahasa Indonesia

  Ayat({
    required this.id,
    required this.surah,
    required this.nomor,
    required this.ar,
    required this.tr,
    required this.idn,
  });

  factory Ayat.fromJson(Map<String, dynamic> json) {
    return Ayat(
      id: json['id'],
      surah: json['surah'],
      nomor: json['nomor'],
      ar: json['ar'],
      tr: json['tr'],
      idn: json['idn'],
    );
  }
}