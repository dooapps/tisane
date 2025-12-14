import '../client/tt_client.dart';
import '../client/tt_link.dart';

/// Factory for constructing `TTClient` instances.
abstract class TTClientFactory {
  TTClient create({TTLink? link, TTOptions? options});
}

class DefaultTTClientFactory implements TTClientFactory {
  const DefaultTTClientFactory();

  @override
  TTClient create({TTLink? link, TTOptions? options}) {
    return TTClient(linkClass: link, options: options);
  }
}
