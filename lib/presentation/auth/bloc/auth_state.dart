part of 'auth_cubit.dart';

@freezed
abstract class PendingCloudReplaceRequest with _$PendingCloudReplaceRequest {
  const factory PendingCloudReplaceRequest({
    required final String uid,
  }) = _PendingCloudReplaceRequest;
}

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    required final bool isAvailable,
    final User? user,
    required final bool isLoading,
    final String? errorMessage,
    final PendingCloudReplaceRequest? pendingCloudReplace,
  }) = _AuthState;

  const AuthState._();

  factory AuthState.initial({required final bool isAvailable}) => AuthState(
    isAvailable: isAvailable,
    isLoading: isAvailable,
  );
}
