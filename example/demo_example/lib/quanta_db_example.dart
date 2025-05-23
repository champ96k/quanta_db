// ignore_for_file: avoid_print

import 'package:quanta_db/quanta_db.dart';

import 'user.dart';

void main() async {
  // Initialize the database
  final db = await QuantaDB.open('example', baseDir: 'quanta_db');
  await db.init();

  try {
    // Create a query engine
    final queryEngine = QueryEngine(db.storage);

    // Example 1: Basic query with filtering and sorting
    print('\nExample 1: Basic Query');
    final activeUsersStream = queryEngine.watch<User, User>(Query<User>()
        .where((user) => user.isActive)
        .sortBy((user) => user.lastLogin)
        .take(5));

    // Listen for updates on active users
    final subscription = activeUsersStream.listen(
      (user) => print('Active user updated: $user'),
      onError: (error) => print('Error in active users stream: $error'),
    );

    // Example 2: Aggregation - Count active users
    print('\nExample 2: Aggregation - Count');
    final activeUserCountStream = queryEngine.watch<User, int>(Query<User>()
        .where((user) => user.isActive)
        .aggregate((users) => users.length));

    activeUserCountStream.listen(
      (count) => print('Active user count: $count'),
      onError: (error) => print('Error in count stream: $error'),
    );

    // Example 3: Aggregation - Average last login time
    print('\nExample 3: Aggregation - Average');
    final avgLastLoginStream = queryEngine.watch<User, double?>(
        Query<User>().where((user) => user.isActive).aggregate((users) {
      if (users.isEmpty) return null;
      final total = users.fold<Duration>(
        Duration.zero,
        (sum, user) => sum + DateTime.now().difference(user.lastLogin),
      );
      return total.inMinutes / users.length;
    }));

    avgLastLoginStream.listen(
      (avg) => print('Average minutes since last login: ${avg ?? "N/A"}'),
      onError: (error) => print('Error in average stream: $error'),
    );

    // Example 4: Complex query with multiple aggregations
    print('\nExample 4: Complex Query with Multiple Aggregations');
    final userStatsStream = queryEngine.watch<User, Map<String, dynamic>>(
        Query<User>().where((user) => user.isActive).aggregate((users) {
      final stats = <String, dynamic>{
        'total': users.length,
        'byEmailDomain': <String, int>{},
        'recentLogins': users
            .where((u) => DateTime.now().difference(u.lastLogin).inHours < 24)
            .length,
      };

      // Group by email domain
      for (final user in users) {
        final domain = user.email.split('@').last;
        stats['byEmailDomain'][domain] =
            (stats['byEmailDomain'][domain] ?? 0) + 1;
      }

      return stats;
    }));

    userStatsStream.listen(
      (stats) => print('User statistics: $stats'),
      onError: (error) => print('Error in stats stream: $error'),
    );

    // Store some test data
    print('\nStoring test data...');
    await _storeTestData(db);

    // Wait to see the reactive updates
    await Future.delayed(const Duration(seconds: 2));

    // Clean up
    subscription.cancel();
    await db.close();
  } catch (e, stackTrace) {
    print('Error in main: $e');
    print('Stack trace: $stackTrace');
  }
}

Future<void> _storeTestData(QuantaDB db) async {
  try {
    // Store a user model
    final user1 = User(
      id: '1',
      name: 'John Doe',
      email: 'john@example.com',
      isActive: true,
      lastLogin: DateTime.now(),
    );
    await db.put('user:1', user1);

    // Add another active user
    final user2 = User(
      id: '2',
      name: 'Jane Smith',
      email: 'jane@company.com',
      isActive: true,
      lastLogin: DateTime.now().subtract(const Duration(hours: 1)),
    );
    await db.put('user:2', user2);

    // Add an inactive user
    final user3 = User(
      id: '3',
      name: 'Bob Wilson',
      email: 'bob@example.com',
      isActive: false,
      lastLogin: DateTime.now().subtract(const Duration(days: 1)),
    );
    await db.put('user:3', user3);

    // Add more users with different email domains
    final user4 = User(
      id: '4',
      name: 'Alice Brown',
      email: 'alice@company.com',
      isActive: true,
      lastLogin: DateTime.now().subtract(const Duration(hours: 2)),
    );
    await db.put('user:4', user4);

    final user5 = User(
      id: '5',
      name: 'Charlie Davis',
      email: 'charlie@other.com',
      isActive: true,
      lastLogin: DateTime.now().subtract(const Duration(hours: 3)),
    );
    await db.put('user:5', user5);

    print('Test data stored successfully');
  } catch (e) {
    print('Error storing test data: $e');
    rethrow;
  }
}
