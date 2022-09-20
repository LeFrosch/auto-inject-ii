import 'package:get_it/get_it.dart';

abstract class GroupProvider<T> {
  Iterable<T> call();
}

extension GroupProviderExtension on GetIt {
  Iterable<T> getGroup<T extends Object>() {
    if (isRegistered<GroupProvider<T>>()) {
      return get<GroupProvider<T>>().call();
    } else {
      return const [];
    }
  }
}
