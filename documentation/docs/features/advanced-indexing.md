---
sidebar_position: 8
---

:::caution Coming Soon
This section is currently under development.
:::

# Advanced Indexing

QuantaDB supports advanced indexing capabilities to significantly improve the performance of your queries, especially as your dataset grows.

Indexing allows the database to quickly locate data without scanning the entire dataset. QuantaDB provides support for:

- **Single Indexes:** Create an index on a specific field within your stored objects. This is beneficial for queries that frequently filter or sort data based on that single field.
- **Composite Indexes:** Create an index on multiple fields. Composite indexes are useful for queries that filter or sort based on a combination of fields. The order of fields in a composite index is important and should match the typical order of fields in your queries for optimal performance.

By creating relevant indexes, you can drastically reduce the time it takes to execute read operations, making your application more responsive.

---
sidebar_position: 8
---

# Advanced Indexing

QuantaDB supports advanced indexing capabilities to significantly improve the performance of your queries, especially as your dataset grows.

Indexing allows the database to quickly locate data without scanning the entire dataset. QuantaDB provides support for:

- **Single Indexes:** Create an index on a specific field within your stored objects. This is beneficial for queries that frequently filter or sort data based on that single field.
- **Composite Indexes:** Create an index on multiple fields. Composite indexes are useful for queries that filter or sort based on a combination of fields. The order of fields in a composite index is important and should match the typical order of fields in your queries for optimal performance.

By creating relevant indexes, you can drastically reduce the time it takes to execute read operations, making your application more responsive.

Detailed instructions and examples on how to define and use indexes in your QuantaDB schema will be provided in the dedicated section on Schema and Indexing. 