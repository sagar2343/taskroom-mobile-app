import 'package:http_interceptor/http_interceptor.dart';
import '../http_interceptors/logger_intercepter.dart';
import '/../core/resources/http_client_factory.dart' as http_factory;

final kHttpClient = InterceptedClient.build(
    interceptors: [LoggerInterceptor()],
    requestTimeout: const Duration(seconds: 30),
    client: http_factory.httpClient(),
);