import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'splash_screen.dart';

// Model untuk Barang
class Barang extends HiveObject {
  @HiveField(0)
  String nama;
  @HiveField(1)
  String kodeBarcode;
  @HiveField(2)
  int jumlah;

  Barang({required this.nama, required this.kodeBarcode, required this.jumlah});
}

// Adapter untuk Hive
class BarangAdapter extends TypeAdapter<Barang> {
  @override
  final int typeId = 0;

  @override
  Barang read(BinaryReader reader) {
    return Barang(
      nama: reader.readString(),
      kodeBarcode: reader.readString(),
      jumlah: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Barang obj) {
    writer.writeString(obj.nama);
    writer.writeString(obj.kodeBarcode);
    writer.writeInt(obj.jumlah);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi Hive
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  Hive.registerAdapter(BarangAdapter());
  await Hive.openBox<Barang>('barangBox');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Perhitungan Barang Dengan Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _barangBox = Hive.box<Barang>('barangBox');
  final _namaController = TextEditingController();
  String? _errorMessage;

  // Fungsi untuk scan barcode
  Future<void> _scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        // Cek apakah barcode sudah ada
        bool barcodeExists = false;
        for (var i = 0; i < _barangBox.length; i++) {
          final barang = _barangBox.getAt(i);
          if (barang?.kodeBarcode == result.rawContent) {
            barang!.jumlah += 1;
            barang.save();
            barcodeExists = true;
            setState(() {});
            break;
          }
        }

        if (!barcodeExists) {
          // Jika barcode baru, tampilkan dialog input nama
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Masukkan Nama Barang'),
              content: TextField(
                controller: _namaController,
                decoration: const InputDecoration(hintText: 'Nama Barang'),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    if (_namaController.text.isNotEmpty) {
                      // Simpan barang baru ke Hive
                      _barangBox.add(Barang(
                        nama: _namaController.text,
                        kodeBarcode: result.rawContent,
                        jumlah: 1,
                      ));
                      _namaController.clear();
                      Navigator.pop(context);
                      setState(() {});
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal scan barcode: $e';
      });
    }
  }

  // Fungsi untuk hapus barang
  void _hapusBarang(int index) {
    _barangBox.deleteAt(index);
    setState(() {});
  }

  // Fungsi untuk tambah jumlah
  void _tambahJumlah(int index) {
    final barang = _barangBox.getAt(index);
    if (barang != null) {
      barang.jumlah += 1;
      barang.save();
      setState(() {});
    }
  }

  // Fungsi untuk kurang jumlah
  void _kurangJumlah(int index) {
    final barang = _barangBox.getAt(index);
    if (barang != null && barang.jumlah > 1) {
      barang.jumlah -= 1;
      barang.save();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Karen Scanner'),
        backgroundColor: Colors.yellow[700], // Hanya AppBar berwarna kuning
      ),
      backgroundColor: Colors.white, // Background body berwarna putih
      body: Column(
        children: [
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _barangBox.listenable(),
              builder: (context, Box<Barang> box, _) {
                if (box.isEmpty) {
                  return const Center(child: Text('Belum ada barang', style: TextStyle(color: Colors.black)));
                }
                return ListView.builder(
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final barang = box.getAt(index);
                    return ListTile(
                      title: Text(barang?.nama ?? '', style: const TextStyle(color: Colors.black)),
                      subtitle: Text('Kode: ${barang?.kodeBarcode}', style: const TextStyle(color: Colors.black)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, color: Colors.black),
                            onPressed: () => _kurangJumlah(index),
                          ),
                          Text('${barang?.jumlah}', style: const TextStyle(color: Colors.black)),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.black),
                            onPressed: () => _tambahJumlah(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.black),
                            onPressed: () => _hapusBarang(index),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanBarcode,
        backgroundColor: Colors.yellow[700], // Warna FAB sesuai tema
        child: const Icon(Icons.qr_code_scanner, color: Colors.black),
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    Hive.close();
    super.dispose();
  }
}