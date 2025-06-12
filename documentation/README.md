# QuantaDB Documentation

[![Pub Version](https://img.shields.io/pub/v/quanta_db.svg)](https://pub.dev/packages/quanta_db)
[![License](https://img.shields.io/github/license/champ96k/quanta_db)](https://github.com/champ96k/quanta_db/blob/master/LICENSE)
[![Dart CI](https://github.com/champ96k/quanta_db/actions/workflows/dart.yml/badge.svg)](https://github.com/champ96k/quanta_db/actions/workflows/dart.yml)
[![codecov](https://codecov.io/gh/champ96k/quanta_db/branch/master/graph/badge.svg)](https://codecov.io/gh/champ96k/quanta_db)
[![Documentation](https://img.shields.io/badge/Documentation-API-blue)](https://quantadb.netlify.app/)
[![Sponsor](https://img.shields.io/badge/Sponsor-%F0%9F%92%96-blueviolet)](https://github.com/sponsors/champ96k)

<iframe src="https://github.com/sponsors/champ96k/button" title="Sponsor champ96k" height="32" width="114" style="border: 0; border-radius: 6px;"></iframe>

This website is built using [Docusaurus](https://docusaurus.io/), a modern static website generator.

### Installation

```
$ yarn
```

### Local Development

```
$ yarn start
```

This command starts a local development server and opens up a browser window. Most changes are reflected live without having to restart the server.

### Build

```
$ yarn build
```

This command generates static content into the `build` directory and can be served using any static contents hosting service.

### Deployment

Using SSH:

```
$ USE_SSH=true yarn deploy
```

Not using SSH:

```
$ GIT_USER=<Your GitHub username> yarn deploy
```

If you are using GitHub pages for hosting, this command is a convenient way to build the website and push to the `gh-pages` branch.

## Code Generation Details

### Type Support

The code generator supports a comprehensive range of data types:

#### Primitive Types
- `String` - Text data
- `int` - Integer numbers
- `double` - Floating-point numbers
- `num` - Any numeric value
- `bool` - Boolean values
- `DateTime` - Date and time values

#### Complex Types
- `List<T>` - Arrays of any supported type
- `Map<K,V>` - Key-value pairs (where K and V are supported types)
- `Set<T>` - Unique collections of any supported type

#### Enums
Both nullable and non-nullable enums are supported:

```dart
enum UserType {
  admin,
  user,
  guest,
}

@QuantaEntity(version: 1)
class User {
  final UserType? userType; // Nullable enum
  final UserType role;      // Non-nullable enum
}
```

Generated code handles nullability:
```dart
Map<String, dynamic> toJson() {
  return {
    'userType': userType?.name,  // Safe access for nullable enum
    'role': role.name,          // Direct access for non-nullable enum
  };
}
```

#### Custom Types
Any class that implements serialization methods:
```dart
class Address {
  final String street;
  final String city;
  
  Address({required this.street, required this.city});
  
  Map<String, dynamic> toJson() => {
    'street': street,
    'city': city,
  };
  
  factory Address.fromJson(Map<String, dynamic> json) => Address(
    street: json['street'] as String,
    city: json['city'] as String,
  );
}
```

#### Nullable Types
All types can be nullable (using `?`):
```dart
@QuantaEntity(version: 1)
class User {
  final String? name;           // Nullable String
  final int? age;              // Nullable int
  final List<String>? tags;    // Nullable List
  final UserType? userType;    // Nullable enum
  final Address? address;      // Nullable custom type
}
```

#### Nested Types
Support for nested data structures:
```dart
@QuantaEntity(version: 1)
class Order {
  final String id;
  final List<OrderItem> items;  // List of custom type
  final Map<String, dynamic> metadata;  // Map with dynamic values
  final Set<String> tags;      // Set of strings
}

class OrderItem {
  final String productId;
  final int quantity;
  // ... toJson and fromJson methods
}
```

### Best Practices

1. **Nullable Fields**
   - Use `?` for optional fields
   - Generator will handle null safety
   - Custom types must implement null-safe serialization

2. **Enums**
   - Can be nullable or non-nullable
   - Use `?.name` for nullable enums
   - Use `.name` for non-nullable enums

3. **Lists and Collections**
   - Can contain any supported type
   - Nullable collections are properly handled
   - Inner types must be supported
   - Use appropriate collection type (List, Set, Map) based on needs

4. **Custom Types**
   - Always implement `toJson()` and `fromJson`
   - Handle nullability properly
   - Consider using code generation for custom types too

5. **Nested Structures**
   - Keep nesting depth reasonable
   - Ensure all nested types are supported
   - Consider performance implications of deep nesting
