---
sidebar_position: 5
---

# Query Operations

QuantaDB provides a powerful query engine that allows you to filter, sort, and paginate your data efficiently. This section covers the various query operations available in QuantaDB.

## Basic Query Setup

First, you'll need to create a QueryEngine instance from your database storage:

```dart
final queryEngine = QueryEngine(db.storage);
```

## Query Types and Examples

### 1. Basic Filtering

Filter records based on a condition:

```dart
// Query active users
final activeUsers = await queryEngine.query<User>(
  Query<User>().where((user) => user.isActive),
);
print('Active users: ${activeUsers.length}');
```

### 2. Sorting

Sort records based on a field:

```dart
// Sort users by last login time
final sortedUsers = await queryEngine.query<User>(
  Query<User>().sortBy((user) => user.lastLogin),
);
print('Users sorted by last login: ${sortedUsers.length}');
```

### 3. Pagination

Retrieve a specific subset of records:

```dart
// Get 2 users, skipping the first one
final paginatedUsers = await queryEngine.query<User>(
  Query<User>().take(2).skip(1),
);
print('Paginated users: ${paginatedUsers.length}');
```

### 4. Complex Queries

Combine multiple conditions in a single query:

```dart
// Complex query with multiple conditions
final complexQuery = await queryEngine.query<User>(
  Query<User>()
      .where((user) => user.isActive)
      .where((user) => user.email.contains('example.com'))
      .sortBy((user) => user.name),
);
print('Complex query results: ${complexQuery.length}');
```

## Reactive Queries

QuantaDB supports reactive queries that automatically update when the underlying data changes. This is useful for real-time applications:

### 1. Watching Individual Records

```dart
// Watch for changes in active users
final activeUsersStream = queryEngine.watch<User, User>(
  Query<User>().where((user) => user.isActive),
);

// Listen to the stream
final subscription = activeUsersStream.listen(
  (user) => print('Active user updated: ${user.name}'),
  onError: (error) => print('Error in active users stream: $error'),
);

// Don't forget to cancel the subscription when done
subscription.cancel();
```

### 2. Watching Aggregated Data

```dart
// Watch aggregated user statistics
final userStatsStream = queryEngine.watch<User, Map<String, dynamic>>(
  Query<User>().aggregate((users) {
    return {
      'total': users.length,
      'active': users.where((u) => u.isActive).length,
      'domains': users.map((u) => u.email.split('@').last).toSet().length,
    };
  }),
);

// Listen to the stream
final subscription = userStatsStream.listen(
  (stats) => print('User stats updated: $stats'),
  onError: (error) => print('Error in stats stream: $error'),
);

// Don't forget to cancel the subscription when done
subscription.cancel();
```

## Best Practices

1. **Type Safety**: Always specify the type parameter when querying to ensure type safety:
   ```dart
   queryEngine.query<User>(...)
   ```

2. **Error Handling**: Wrap queries in try-catch blocks to handle potential errors:
   ```dart
   try {
     final results = await queryEngine.query<User>(...);
   } catch (e) {
     print('Query error: $e');
   }
   ```

3. **Resource Management**: Always cancel reactive query subscriptions when they're no longer needed to prevent memory leaks.

4. **Query Optimization**: 
   - Use specific conditions in `where` clauses
   - Limit the number of records returned using `take`
   - Use `skip` for pagination instead of retrieving all records

## Example Data Structure

For the examples above, we used a `User` model that looks like this:

```dart
class User {
  final String id;
  String name;
  String email;
  bool isActive;
  DateTime lastLogin;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
    required this.lastLogin,
  });
}
```
