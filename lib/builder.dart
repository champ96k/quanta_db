import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generator/quanta_generator.dart';

Builder quantaBuilder(BuilderOptions options) =>
    PartBuilder([QuantaGenerator()], '.g.dart');
