import 'package:equatable/equatable.dart';

import '../utils/global.dart';
import '../utils/type.dart';
import '../write/writer.dart';

enum ProviderType { injectable, singleton, lazySingleton }

class DependencyProvider extends Equatable {
  final TargetType target;
  final List<String> env;

  final List<Dependency> dependencies;
  final List<TargetType> groups;

  final RegisterWriter writer;

  const DependencyProvider({
    required this.target,
    required this.env,
    required this.dependencies,
    required this.groups,
    required this.writer,
  });

  bool get module => false;

  @override
  List<Object?> get props => [env, dependencies, target, groups, module];
}

class ModuleDependencyProvider extends DependencyProvider {
  final int moduleId;
  final String accessorName;

  const ModuleDependencyProvider({
    required super.target,
    required super.env,
    required super.dependencies,
    required super.groups,
    required super.writer,
    required this.moduleId,
    required this.accessorName,
  });

  @override
  bool get module => true;

  @override
  List<Object?> get props => super.props + [moduleId, accessorName];
}

class Dependency extends Equatable {
  final TargetType target;

  const Dependency(this.target);

  bool get group => false;

  bool get assisted => false;

  bool get factory => false;

  @override
  List<Object?> get props => [target, group, assisted, factory];
}

class GroupDependency extends Dependency {
  final bool list;

  const GroupDependency(super.target, {required this.list});

  @override
  bool get group => true;

  @override
  List<Object?> get props => super.props + [list];
}

class AssistedDependency extends Dependency {
  final String name;

  const AssistedDependency(super.target, {required this.name});

  @override
  bool get assisted => true;

  @override
  List<Object?> get props => super.props + [name];
}

class FactoryDependency extends Dependency {
  FactoryDependency() : super(TargetType(symbol: factoryClassName, url: null));

  @override
  bool get factory => true;
}
