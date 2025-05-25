---
sidebar_position: 9
---

# Real-time Updates (Reactive Queries)

QuantaDB provides support for **Reactive Queries**, enabling your application to receive real-time updates whenever the data relevant to a specific query changes. This is a powerful feature for building dynamic and responsive user interfaces.

Reactive queries allow you to subscribe to the results of a query. Instead of manually re-executing the query to check for changes, QuantaDB will automatically notify your application and provide the updated results whenever underlying data modifications (like additions, updates, or deletions) affect the query's output.

This is particularly useful for:

- **Live Data Display:** Automatically refresh UI elements (e.g., lists, charts) when the data they display changes.
- **Synchronization:** Keep different parts of your application or even different clients (in a synchronized scenario) up-to-date with the latest data.
- **Responding to Changes:** Trigger specific actions or logic in your application whenever relevant data changes.

While the exact implementation details of reactive queries in QuantaDB depend on its API, a typical pattern in Dart/Flutter local databases involves listening to a stream or observable provided by the query result.

```dart
// Example (Conceptual - specific API might vary)

// Assume 'yourQuery' is a query object from QuantaDB's API
final resultsStream = yourQuery.watch(); // Method to get a stream of results

resultsStream.listen((latestResults) {
  // Handle the latest results received from the database
  print('Data updated: $latestResults');
  // Update your UI or application state here
});

// Remember to cancel the subscription when no longer needed
// subscription.cancel();
```

This conceptual example illustrates how you might listen for changes. Refer to the dedicated Querying section for the exact API and more detailed examples on constructing and observing queries. 