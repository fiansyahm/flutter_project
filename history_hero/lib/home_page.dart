import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'model_main.dart'; // Ganti dengan path file ModelMain Anda
import 'detail_page.dart';

void main() {
  runApp(const Home());
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() {
    return _HomeState();
  }
}

class _HomeState extends State<HomePage> {
  // URL untuk mengambil data JSON
  final String url = 'https://api.npoint.io/c84c0eeacbdb62b5da1d';

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

  TextEditingController searchController = TextEditingController();
  String? filterData;
  ScrollController scrollController = ScrollController();
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
      if (scrollController.offset > 10) {
        setState(() {
          showFab = true;
        });
      } else {
        setState(() {
          showFab = false;
        });
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
            'Sejarah Pahlawan',
            style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 30),
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
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                  hintText: 'Cari nama pahlawan',
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
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  )),
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
                      return filterData == null || filterData == ""
                          ? GestureDetector(
                        onTap: () {
                          String nama = items[index].nama.toString();
                          String nama2 = items[index].nama2.toString();
                          String kategori = items[index].kategori.toString();
                          String asal = items[index].asal.toString();
                          String usia = items[index].usia.toString();
                          String lahir = items[index].lahir.toString();
                          String gugur = items[index].gugur.toString();
                          String lokasimakam = items[index].lokasimakam.toString();
                          String history = items[index].history.toString();
                          String img = items[index].img.toString();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailPahlawan(
                                nama: nama,
                                nama2: nama2,
                                kategori: kategori,
                                asal: asal,
                                usia: usia,
                                lahir: lahir,
                                gugur: gugur,
                                lokasimakam: lokasimakam,
                                history: history,
                                img: img,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 5,
                          margin: const EdgeInsets.all(10),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Container(
                                  margin:
                                  const EdgeInsets.only(right: 14),
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: NetworkImage(
                                        items[index].img.toString(),
                                      ),
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        items[index].nama.toString(),
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 18),
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        items[index].nama2.toString(),
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 14),
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      )
                          : '${items[index].nama}'
                          .toLowerCase()
                          .contains(filterData!.toLowerCase())
                          ? GestureDetector(
                        onTap: () {},
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(10)),
                          elevation: 4,
                          margin: const EdgeInsets.all(10),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(
                                      right: 14),
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: NetworkImage(
                                        items[index].img.toString(),
                                      ),
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        items[index]
                                            .nama
                                            .toString(),
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 18),
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding:
                                        const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                            BorderRadius
                                                .circular(10),
                                            color: Colors.green),
                                        child: Text(
                                          items[index]
                                              .kategori
                                              .toString(),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10),
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      )
                          : Container();
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
}
