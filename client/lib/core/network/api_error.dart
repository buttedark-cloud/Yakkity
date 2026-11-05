import 'package:dio/dio.dart';

String apiErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Не удаётся связаться с сервером';
      default:
        break;
    }
    switch (error.response?.statusCode) {
      case 401:
        return 'Неверный или просроченный код';
      case 422:
        return 'Проверь введённые данные';
    }
  }
  return 'Что-то пошло не так';
}
