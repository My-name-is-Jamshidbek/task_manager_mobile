import '../../core/utils/multilingual_message.dart';

/// Base class for API responses with multilingual message support
abstract class BaseApiResponse {
  final bool success;
  final MultilingualMessage? message;
  final int? statusCode;

  const BaseApiResponse({required this.success, this.message, this.statusCode});

  /// Gets the localized message for display
  String? getLocalizedMessage() {
    return message?.getMessage();
  }

  /// Gets message in a specific language
  String? getMessageInLanguage(String languageCode) {
    return message?.getMessageInLanguage(languageCode);
  }

  /// Check if response has any message
  bool get hasMessage => message?.hasMessage ?? false;
}

/// Generic API response wrapper with multilingual support
class ApiResponseWrapper<T> extends BaseApiResponse {
  final T? data;
  final String? error;

  const ApiResponseWrapper({
    required super.success,
    super.message,
    super.statusCode,
    this.data,
    this.error,
  });

  factory ApiResponseWrapper.success(
    T data, {
    MultilingualMessage? message,
    int? statusCode,
  }) {
    return ApiResponseWrapper<T>(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ApiResponseWrapper.error(
    String error, {
    MultilingualMessage? message,
    int? statusCode,
  }) {
    return ApiResponseWrapper<T>(
      success: false,
      error: error,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ApiResponseWrapper.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    return ApiResponseWrapper<T>(
      success: json['success'] ?? false,
      data: json['data'] != null && fromJson != null
          ? fromJson(json['data'])
          : json['data'],
      message: json['message'] != null
          ? MultilingualMessage.fromJson(json['message'])
          : null,
      statusCode: json['statusCode'],
      error: json['error'],
    );
  }

  /// Get the best available error message (prioritizing API message)
  String? getBestErrorMessage() {
    // Try localized API message first
    final localizedMessage = getLocalizedMessage();
    if (localizedMessage != null && localizedMessage.isNotEmpty) {
      return localizedMessage;
    }

    // Fall back to error field
    return error;
  }

  bool get isSuccess => success;
  bool get isFailure => !success;
}

/// Example usage for Task API responses
class TaskResponse extends BaseApiResponse {
  final List<Task>? tasks;
  final Task? task;

  const TaskResponse({
    required super.success,
    super.message,
    super.statusCode,
    this.tasks,
    this.task,
  });

  factory TaskResponse.fromJson(Map<String, dynamic> json) {
    return TaskResponse(
      success: json['success'] ?? false,
      message: json['message'] != null
          ? MultilingualMessage.fromJson(json['message'])
          : null,
      statusCode: json['statusCode'],
      tasks: json['tasks'] != null
          ? (json['tasks'] as List).map((e) => Task.fromJson(e)).toList()
          : null,
      task: json['task'] != null ? Task.fromJson(json['task']) : null,
    );
  }
}

// Placeholder Task class - you should use your actual Task model
class Task {
  final int id;
  final String title;

  const Task({required this.id, required this.title});

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(id: json['id'], title: json['title']);
  }
}
