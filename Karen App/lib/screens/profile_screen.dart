import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isGoldTheme;

  const ProfileScreen({super.key, required this.onThemeToggle, required this.isGoldTheme});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String userName;
  final TextEditingController _nameController = TextEditingController();
  late Box<String> _userBox;

  @override
  void initState() {
    super.initState();
    // Open the Hive box and load the user name
    _userBox = Hive.box<String>('userBox');
    userName = _userBox.get('userName', defaultValue: 'John Doe')!;
    _nameController.text = userName;
  }

  void _editName() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nama',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              final newName = _nameController.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  userName = newName;
                  _userBox.put('userName', userName);
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama tidak boleh kosong')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saya'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.edit,
                      size: 20, color: Theme.of(context).textTheme.bodyLarge?.color),
                  onPressed: _editName,
                ),
              ],
            ),
            const SizedBox(height: 32),
            ListTile(
              leading: Icon(Icons.color_lens,
                  color: Theme.of(context).textTheme.bodyLarge?.color),
              title: Text(
                'Ubah Tema (Gold/Black)',
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              trailing: Switch(
                value: widget.isGoldTheme,
                activeColor: Colors.yellow[700],
                inactiveTrackColor: Colors.grey,
                onChanged: (value) {
                  widget.onThemeToggle();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}