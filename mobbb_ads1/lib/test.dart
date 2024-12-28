import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'model_main.dart';
import 'detail_page.dart';
import 'package:flutter/services.dart'; // <-- Add this import

void main() {
  runApp(const Home());
}

class Home extends StatelessWidget {
  static const MethodChannel _channel = MethodChannel('com.example.mobbb_ads/ad');

  const Home({super.key});

  void _showAdIfNeeded(String heroName) {
    if (heroName == "Time Boxing") {
      _channel.invokeMethod('showAd');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leadership Skill'),
      ),
      body: ListView.builder(
        itemCount: 10, // Example count
        itemBuilder: (context, index) {
          final heroName = 'Time Boxing'; // Example hero name
          return ListTile(
            title: Text(heroName),
            onTap: () {
              _showAdIfNeeded(heroName);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailPahlawan(
                    title: item.title ?? 'Unknown',
                    category: item.category ?? '',
                    img: item.img ?? '',
                    description: item.description ?? [],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  // URL dasar
  final String baseUrl = 'https://api.npoint.io';

  // URL untuk mengambil data JSON
  late String url;

  // Bahasa yang tersedia
  final List<String> languages = ['ID', 'EN', 'SA', 'RU', 'BR'];
  String selectedLanguage = 'ID';

  // Fungsi untuk memuat data dari URL
  Future<List<ModelMain>> readJsonData() async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final listData = json.decode(response.body) as List<dynamic>;
        return listData.map((e) => ModelMain.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  final TextEditingController searchController = TextEditingController();
  String? filterData;
  final ScrollController scrollController = ScrollController();
  bool showFab = false;

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        filterData = searchController.text;
      });
    });

    scrollController.addListener(() {
      setState(() {
        showFab = scrollController.offset > 10;
      });
    });

    // Set URL default berdasarkan bahasa awal
    updateUrl();
  }

  void updateUrl() {
    setState(() {
      // URL berdasarkan bahasa
      switch (selectedLanguage) {
        case 'ID':
          url = '$baseUrl/c84c0eeacbdb62b5da1d';
          break;
        case 'EN':
          url = '$baseUrl/ae05acbfaa6c3de7c208';
          break;
        case 'SA':
          url = '$baseUrl/54f32e52aaf8118a5793';
          break;
        case 'RU':
          url = '$baseUrl/199619da9d3d6665813c';
          break;
        case 'BR':
          url = '$baseUrl/d92c6aa366a8fa658d99';
          break;
        default:
          url = '';
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Leadership Skill',
            style: TextStyle(
                color: Colors.green, fontWeight: FontWeight.bold, fontSize: 30),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: AnimatedOpacity(
        duration: const Duration(milliseconds: 1000),
        opacity: showFab ? 1.0 : 0.0,
        child: FloatingActionButton(
          onPressed: () {
            scrollController.animateTo(0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.fastOutSlowIn);
          },
          backgroundColor: Colors.green,
          child: const Icon(Icons.arrow_upward),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Dropdown untuk memilih bahasa
                DropdownButton<String>(
                  value: selectedLanguage,
                  items: languages.map((lang) {
                    return DropdownMenuItem<String>(
                      value: lang,
                      child: Text(_getLanguageLabel(lang)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedLanguage = value!;
                      updateUrl();
                    });
                  },
                ),
                const SizedBox(height: 10),
                // Search bar
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search skill',
                    suffixIcon: searchController.text.isEmpty
                        ? null
                        : IconButton(
                      onPressed: searchController.clear,
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.red,
                      ),
                    ),
                    contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                      const BorderSide(color: Colors.green, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ModelMain>>(
              future: readJsonData(),
              builder: (context, data) {
                if (data.hasError) {
                  return Center(child: Text("${data.error}"));
                } else if (data.hasData) {
                  var items = data.data!;
                  return ListView.builder(
                    controller: scrollController,
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _filterAndBuildCard(items, index);
                    },
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterAndBuildCard(List<ModelMain> items, int index) {
    final item = items[index];
    final query = filterData?.toLowerCase() ?? '';

    if (query.isNotEmpty &&
        !(item.title?.toLowerCase().contains(query) ?? false)) {
      return const SizedBox.shrink();
    }

    return buildCard(items, index);
  }

  Widget buildCard(List<ModelMain> items, int index) {
    final item = items[index];
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPahlawan(
              title: item.title ?? 'Unknown',
              category: item.category ?? '',
              img: item.img ?? '',
              description: item.description ?? [],
            ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 5,
        margin: const EdgeInsets.all(10),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 14),
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(item.img ?? ''),
                    onError: (exception, stackTrace) => AssetImage(
                        'assets/placeholder.png'), // Placeholder jika gagal
                  ),
                ),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title ?? 'Unknown',
                      style: const TextStyle(color: Colors.black, fontSize: 18),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.category ?? '',
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageLabel(String lang) {
    switch (lang) {
      case 'ID':
        return 'Bahasa Indonesia';
      case 'EN':
        return 'English';
      case 'SA':
        return 'العربية (Arabic)';
      case 'RU':
        return 'Русский (Russian)';
      case 'BR':
        return 'Português (Portuguese)';
      default:
        return 'Unknown';
    }
  }
}
