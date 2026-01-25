// Gearsh App - Import Artists from Twitter
// UI for importing followers/following from Twitter as artists

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gearsh_app/services/twitter_api_service.dart';

class ImportTwitterArtistsPage extends StatefulWidget {
  const ImportTwitterArtistsPage({super.key});

  @override
  State<ImportTwitterArtistsPage> createState() => _ImportTwitterArtistsPageState();
}

class _ImportTwitterArtistsPageState extends State<ImportTwitterArtistsPage> {
  // Color constants
  static const Color _slate950 = Color(0xFF020617);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _sky500 = Color(0xFF0EA5E9);
  static const Color _sky400 = Color(0xFF38BDF8);
  static const Color _cyan500 = Color(0xFF06B6D4);
  static const Color _green500 = Color(0xFF22C55E);

  bool _isLoading = false;
  bool _isImporting = false;
  String? _error;
  String _importType = 'followers'; // 'followers' or 'following'

  List<TwitterUser> _users = [];
  final Set<String> _selectedUsers = {};
  final Map<String, String> _userCategories = {};
  final Map<String, int> _userPrices = {};

  final List<String> _categoryOptions = [
    'DJ', 'Rapper', 'Producer', 'Singer', 'Musician',
    'Photographer', 'Videographer', 'Designer', 'Fashion Designer',
    'Visual Artist', 'Mural Artist', 'Dancer', 'Comedian', 'MC',
    'Model', 'Influencer', 'Actor', 'Director', 'Writer',
    'Make Up Artist', 'Stylist', 'Tech', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _checkApiConfig();
  }

  void _checkApiConfig() {
    if (TwitterConfig.bearerToken == 'YOUR_TWITTER_BEARER_TOKEN') {
      setState(() {
        _error = 'Twitter API not configured. Please add your Bearer Token in twitter_api_service.dart';
      });
    }
  }

  Future<void> _fetchUsers() async {
    if (TwitterConfig.bearerToken == 'YOUR_TWITTER_BEARER_TOKEN') {
      setState(() {
        _error = 'Please configure your Twitter API Bearer Token first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _users = [];
      _selectedUsers.clear();
    });

    try {
      List<TwitterUser> users;
      if (_importType == 'followers') {
        users = await twitterApiService.getFollowers(
          username: TwitterConfig.gearshUsername,
          maxResults: 100,
        );
      } else {
        users = await twitterApiService.getFollowing(
          username: TwitterConfig.gearshUsername,
          maxResults: 100,
        );
      }

      setState(() {
        _users = users;
        _isLoading = false;
        if (users.isEmpty) {
          _error = 'No users found. Make sure your API token has the correct permissions.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error fetching users: $e';
      });
    }
  }

  void _toggleSelection(String userId) {
    setState(() {
      if (_selectedUsers.contains(userId)) {
        _selectedUsers.remove(userId);
      } else {
        _selectedUsers.add(userId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedUsers.length == _users.length) {
        _selectedUsers.clear();
      } else {
        _selectedUsers.addAll(_users.map((u) => u.id));
      }
    });
  }

  Future<void> _importSelectedUsers() async {
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one user to import')),
      );
      return;
    }

    setState(() => _isImporting = true);

    try {
      final selectedUsersList = _users.where((u) => _selectedUsers.contains(u.id)).toList();

      // Generate Dart code for the artists
      final dartCode = _generateDartCode(selectedUsersList);

      // Show the generated code
      await _showGeneratedCode(dartCode);

      setState(() => _isImporting = false);
    } catch (e) {
      setState(() {
        _isImporting = false;
        _error = 'Error importing users: $e';
      });
    }
  }

  String _generateDartCode(List<TwitterUser> users) {
    final buffer = StringBuffer();
    buffer.writeln('// Add these artists to lib/data/gearsh_artists.dart');
    buffer.writeln('// Imported from Twitter @${TwitterConfig.gearshUsername} on ${DateTime.now().toString().split(' ')[0]}');
    buffer.writeln();

    for (final user in users) {
      final category = _userCategories[user.id] ?? 'Artist';
      final price = _userPrices[user.id] ?? 2000;

      buffer.writeln('  // ${user.name} (@${user.username})');
      buffer.writeln('  GearshArtist(');
      buffer.writeln("    id: '${user.username.toLowerCase()}',");
      buffer.writeln("    name: '${_escapeString(user.name)}',");
      buffer.writeln("    username: '@${user.username}',");
      buffer.writeln("    category: '$category',");
      buffer.writeln("    subcategories: ['$category'],");
      buffer.writeln("    location: '${_escapeString(user.location ?? 'South Africa')}',");
      buffer.writeln("    countryCode: 'ZA',");
      buffer.writeln("    currencyCode: 'ZAR',");
      buffer.writeln('    rating: 4.5,');
      buffer.writeln('    reviewCount: 0,');
      buffer.writeln('    hoursBooked: 0,');
      buffer.writeln("    responseTime: '< 24 hours',");
      buffer.writeln("    image: 'assets/images/artists/${user.username.toLowerCase()}.png',");
      buffer.writeln('    isVerified: ${user.isVerified},');
      buffer.writeln('    isAvailable: true,');
      buffer.writeln("    bio: '${_escapeString(user.bio ?? 'Artist on Gearsh')}',");
      buffer.writeln('    bookingFee: $price,');
      buffer.writeln('    highlights: [');
      buffer.writeln("      'New on Gearsh',");
      if (user.isVerified) buffer.writeln("      'Verified on X',");
      if (user.followersCount > 1000) {
        buffer.writeln("      '${(user.followersCount / 1000).toStringAsFixed(1)}K Followers',");
      }
      buffer.writeln('    ],');
      buffer.writeln('    services: [');
      buffer.writeln('      {');
      buffer.writeln("        'id': 's1',");
      buffer.writeln("        'name': 'Standard Booking',");
      buffer.writeln("        'price': $price.0,");
      buffer.writeln("        'description': 'Book ${_escapeString(user.name)} for your event.',");
      buffer.writeln("        'duration': '1 hour',");
      buffer.writeln("        'includes': ['Performance', 'Meet & greet'],");
      buffer.writeln('      },');
      buffer.writeln('    ],');
      buffer.writeln('  ),');
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _escapeString(String input) {
    return input
        .replaceAll("'", "\\'")
        .replaceAll('\n', ' ')
        .replaceAll('\r', '');
  }

  Future<void> _showGeneratedCode(String code) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: _slate900,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.code, color: _sky400),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Generated Artist Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
            ),
            // Instructions
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _sky500.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _sky500.withAlpha(77)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: _sky400, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Copy this code and paste it into lib/data/gearsh_artists.dart before the closing ];',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Code view
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _slate950,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _slate800),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    code,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
            // Copy button
            Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: () {
                  // Copy to clipboard would go here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Code ready to copy! Long-press the code above to select and copy.'),
                      backgroundColor: _green500,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_sky500, _cyan500]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(TwitterUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _slate900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select category for ${user.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Price input
            Row(
              children: [
                const Text('Base Price: R', style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '2000',
                      hintStyle: TextStyle(color: Colors.white.withAlpha(77)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _sky500.withAlpha(77)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _sky500.withAlpha(77)),
                      ),
                    ),
                    onChanged: (value) {
                      _userPrices[user.id] = int.tryParse(value) ?? 2000;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categoryOptions.map((category) {
                final isSelected = _userCategories[user.id] == category;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _userCategories[user.id] = category;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected ? const LinearGradient(colors: [_sky500, _cyan500]) : null,
                      color: isSelected ? null : _slate800,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? Colors.transparent : _sky500.withAlpha(51)),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_slate950, _slate900, _slate950],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.only(
                top: padding.top + 16,
                left: 20,
                right: 20,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                color: _slate950.withAlpha(242),
                border: Border(
                  bottom: BorderSide(color: _sky500.withAlpha(51)),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _slate900.withAlpha(128),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: _sky500.withAlpha(77)),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Import from Twitter',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '@${TwitterConfig.gearshUsername}',
                              style: TextStyle(
                                color: Colors.white.withAlpha(153),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Twitter logo
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DA1F2).withAlpha(26),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.flutter_dash, // Placeholder for X logo
                          color: Color(0xFF1DA1F2),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Import type toggle
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _importType = 'followers'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: _importType == 'followers'
                                  ? const LinearGradient(colors: [_sky500, _cyan500])
                                  : null,
                              color: _importType == 'followers' ? null : _slate800,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Followers',
                                style: TextStyle(
                                  color: _importType == 'followers' ? Colors.white : Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _importType = 'following'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: _importType == 'following'
                                  ? const LinearGradient(colors: [_sky500, _cyan500])
                                  : null,
                              color: _importType == 'following' ? null : _slate800,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Following',
                                style: TextStyle(
                                  color: _importType == 'following' ? Colors.white : Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Error message
            if (_error != null)
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withAlpha(77)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Fetch button or loading
            if (_users.isEmpty && !_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.white.withAlpha(51),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Fetch your $_importType from Twitter',
                        style: TextStyle(
                          color: Colors.white.withAlpha(153),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _fetchUsers,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [_sky500, _cyan500]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.download, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Fetch ${_importType.substring(0, 1).toUpperCase()}${_importType.substring(1)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Loading
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: _sky500),
                      SizedBox(height: 16),
                      Text(
                        'Fetching from Twitter...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),

            // Users list
            if (_users.isNotEmpty && !_isLoading)
              Expanded(
                child: Column(
                  children: [
                    // Select all bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Text(
                            '${_users.length} users found',
                            style: TextStyle(color: Colors.white.withAlpha(153)),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _selectAll,
                            child: Text(
                              _selectedUsers.length == _users.length ? 'Deselect All' : 'Select All',
                              style: const TextStyle(color: _sky400, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final isSelected = _selectedUsers.contains(user.id);
                          final category = _userCategories[user.id] ?? 'Tap to set category';

                          return GestureDetector(
                            onTap: () => _toggleSelection(user.id),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? _sky500.withAlpha(26) : _slate900.withAlpha(128),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? _sky500 : _sky500.withAlpha(51),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Checkbox
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? _sky500 : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected ? _sky500 : Colors.white38,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  // Avatar
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: _slate800,
                                    backgroundImage: user.profileImageUrl != null
                                        ? NetworkImage(user.profileImageUrl!)
                                        : null,
                                    child: user.profileImageUrl == null
                                        ? const Icon(Icons.person, color: Colors.white54)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                user.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (user.isVerified) ...[
                                              const SizedBox(width: 4),
                                              const Icon(Icons.verified, color: Color(0xFF1DA1F2), size: 16),
                                            ],
                                          ],
                                        ),
                                        Text(
                                          '@${user.username}',
                                          style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        GestureDetector(
                                          onTap: () => _showCategoryPicker(user),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _userCategories.containsKey(user.id)
                                                  ? _sky500.withAlpha(51)
                                                  : _slate800,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              category,
                                              style: TextStyle(
                                                color: _userCategories.containsKey(user.id)
                                                    ? _sky400
                                                    : Colors.white54,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Followers count
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatCount(user.followersCount),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'followers',
                                        style: TextStyle(color: Colors.white.withAlpha(102), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Import button
            if (_users.isNotEmpty && !_isLoading)
              Container(
                padding: EdgeInsets.fromLTRB(20, 16, 20, padding.bottom + 16),
                decoration: BoxDecoration(
                  color: _slate950.withAlpha(242),
                  border: Border(top: BorderSide(color: _sky500.withAlpha(51))),
                ),
                child: GestureDetector(
                  onTap: _isImporting ? null : _importSelectedUsers,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: _selectedUsers.isNotEmpty
                          ? const LinearGradient(colors: [_sky500, _cyan500])
                          : null,
                      color: _selectedUsers.isEmpty ? _slate800 : null,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: _isImporting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              _selectedUsers.isEmpty
                                  ? 'Select users to import'
                                  : 'Generate Code for ${_selectedUsers.length} Artists',
                              style: TextStyle(
                                color: _selectedUsers.isNotEmpty ? Colors.white : Colors.white54,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
