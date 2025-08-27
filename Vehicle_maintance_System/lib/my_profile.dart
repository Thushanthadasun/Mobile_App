import 'package:flutter/material.dart';
import 'api_service.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({super.key});

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  bool _loading = true;
  bool _saving = false;

  String _fname = '';
  String _lname = '';
  String _email = '';
  String _mobile = '';

  final _emailCtl = TextEditingController();
  final _mobileCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final data = await ApiService().getUserProfile();
    if (!mounted) return;
    if (data != null) {
      setState(() {
        _fname = data['fname'] ?? '';
        _lname = data['lname'] ?? '';
        _email = data['email'] ?? '';
        _mobile = data['mobile'] ?? '';
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      _snack('Failed to load profile');
    }
  }

  Future<void> _saveEmail() async {
    final newEmail = _emailCtl.text.trim();
    if (newEmail.isEmpty || !newEmail.contains('@')) {
      _snack('Enter a valid email');
      return;
    }
    setState(() => _saving = true);
    final ok = await ApiService().updateEmail(newEmail);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      _snack('Email updated');
      setState(() => _email = newEmail);
      Navigator.pop(context);
    } else {
      _snack('Could not update email');
    }
  }

  Future<void> _saveMobile() async {
    final newMobile = _mobileCtl.text.trim();
    if (newMobile.isEmpty) {
      _snack('Enter a valid contact number');
      return;
    }
    setState(() => _saving = true);
    final ok = await ApiService().updateContact(newMobile);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      _snack('Contact number updated');
      setState(() => _mobile = newMobile);
      Navigator.pop(context);
    } else {
      _snack('Could not update contact number');
    }
  }

  void _editEmailDialog() {
    _emailCtl.text = _email;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Email'),
        content: TextField(
          controller: _emailCtl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'Enter new email'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: _saving ? null : _saveEmail,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editMobileDialog() {
    _mobileCtl.text = _mobile;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Contact Number'),
        content: TextField(
          controller: _mobileCtl,
          keyboardType: TextInputType.phone,
          decoration:
              const InputDecoration(hintText: 'Enter new contact number'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: _saving ? null : _saveMobile,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _mobileCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text('My Profile',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red)),
          const SizedBox(height: 12),

          Text('Name: $_fname $_lname', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text('Contact: $_mobile',
                      style: const TextStyle(fontSize: 18))),
              IconButton(
                  icon: const Icon(Icons.edit), onPressed: _editMobileDialog),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text('Email: $_email',
                      style: const TextStyle(fontSize: 18))),
              IconButton(
                  icon: const Icon(Icons.edit), onPressed: _editEmailDialog),
            ],
          ),

          const SizedBox(height: 24),
          const Text('Maintenance Messages',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // You can replace this section with your real messages feed.
          _maintenanceTile(
              'Oil Change Reminder - ABC-1234',
              "It's been over 6 months since your last oil change",
              'Recommended every 6 months'),
          const Divider(),
          _maintenanceTile(
              'Brake Check Reminder - ABC-1234',
              'Time for your annual brake inspection',
              'Recommended every 12 months'),
          const Divider(),
          _maintenanceTile(
              'Tire Check Reminder - XYZ-5678',
              "Time to check your tires' condition",
              'Recommended every 24 months'),
        ],
      ),
    );
  }

  Widget _maintenanceTile(String title, String description, String note) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(description),
          const SizedBox(height: 4),
          Text(note, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
