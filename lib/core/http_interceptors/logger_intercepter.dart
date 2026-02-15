import 'package:flutter/material.dart';
import 'package:http_interceptor/http_interceptor.dart';

class LoggerInterceptor extends InterceptorContract {
  @override
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    debugPrint('----- Request -----');
    debugPrint(request.toString());
    debugPrint(request.headers.toString());
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    debugPrint('----- Response -----');
    debugPrint('Code: ${response.statusCode}');
    if (response is Response) {
      debugPrint((response).body);
    }
    return response;
  }
}
