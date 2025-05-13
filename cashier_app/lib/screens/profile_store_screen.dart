import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../db/adapters.dart';
import 'home_page.dart';

class ProfileStoreScreen extends StatefulWidget {
  const ProfileStoreScreen({super.key});

  @override
  State<ProfileStoreScreen> createState() => _ProfileStoreScreenState();
}

class _ProfileStoreScreenState extends State<ProfileStoreScreen> {
  final _storeNameController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadStoreProfile();
  }

  void _loadStoreProfile() async {
    final profile = await DatabaseHelper.instance.getStoreProfile();
    if (profile != null) {
      setState(() {
        _storeNameController.text = profile.storeName;
        _isEditing = true;
      });
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    super.dispose();
  }

  void _saveStoreProfile() async {
    final storeName = _storeNameController.text.trim();
    if (storeName.isNotEmpty) {
      await DatabaseHelper.instance.saveStoreProfile(StoreProfile(storeName: storeName));
      if (!_isEditing) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        Navigator.of(context).pop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama toko tidak boleh kosong')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Toko'),
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan Nama Toko',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _storeNameController,
              decoration: const InputDecoration(labelText: 'Nama Toko'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveStoreProfile,
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}