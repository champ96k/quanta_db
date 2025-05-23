import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generator/quanta_generator.dart';

/// Creates a builder that generates code using the QuantaGenerator.
///
/// This builder is used to generate `.g.dart` files containing the generated code
/// from the QuantaGenerator.
Builder quantaBuilder(BuilderOptions options) =>
    PartBuilder([QuantaGenerator()], '.g.dart');
