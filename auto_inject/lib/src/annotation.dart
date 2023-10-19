class Injectable {
  final Type? as;

  final List<Type> group;
  final List<String> env;

  final Function? dispose;

  const Injectable({
    this.env = const ['default'],
    this.as,
    this.dispose,
    this.group = const [],
  });
}

class Singleton extends Injectable {
  final bool lazy;

  const Singleton({
    super.env,
    super.as,
    super.dispose,
    super.group,
    this.lazy = false,
  });
}

class Module {
  final bool extern;

  const Module._(this.extern);
}

const module = Module._(false);
const externModule = Module._(true);

class GroupField {
  const GroupField._();
}

const group = GroupField._();

class AssistedField {
  const AssistedField._();
}

const assisted = AssistedField._();

class DisposeMethod {
  const DisposeMethod._();
}

const disposeMethod = DisposeMethod._();
