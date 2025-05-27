import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generator/quanta_generator.dart';

/// Creates a builder that generates code using the QuantaGenerator.
///
/// This builder is used to generate `.g.dart` files containing the generated code
/// from the QuantaGenerator. The generated code includes:
/// - Type adapters for serialization
/// - Data access objects (DAOs) for database operations
/// - Validation logic for entity fields
/// - Index and reactive field support
///
/// The builder is configured in `build.yaml` to run on all Dart files except
/// those in the `lib/annotations` and `lib/src/generator` directories.
Builder quantaBuilder(BuilderOptions options) =>
    PartBuilder([QuantaGenerator()], '.g.dart');
