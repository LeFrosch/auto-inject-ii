import 'package:equatable/equatable.dart';

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
    required TargetType target,
    required List<String> env,
    required List<Dependency> dependencies,
    required List<TargetType> groups,
    required RegisterWriter writer,
    required this.moduleId,
    required this.accessorName,
  }) : super(target: target, env: env, dependencies: dependencies, groups: groups, writer: writer);

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

  @override
  List<Object?> get props => [target, group, assisted];
}

class GroupDependency extends Dependency {
  final bool list;

  const GroupDependency(TargetType target, {required this.list}) : super(target);

  @override
  bool get group => true;

  @override
  List<Object?> get props => super.props + [list];
}

class AssistedDependency extends Dependency {
  final String name;

  const AssistedDependency(TargetType target, {required this.name}) : super(target);

  @override
  bool get assisted => true;

  @override
  List<Object?> get props => super.props + [name];
}
