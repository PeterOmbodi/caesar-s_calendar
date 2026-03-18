part of 'auth_cubit.dart';

@freezed
abstract class AccountSwitchRequest with _$AccountSwitchRequest {
  const factory AccountSwitchRequest({
    required final AuthProviderKind providerKind,
    final AuthCredential? credential,
  }) = _AccountSwitchRequest;
}

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    required final bool isAvailable,
    final User? user,
    required final bool isLoading,
    final String? errorMessage,
    final AccountSwitchRequest? pendingAccountSwitch,
  }) = _AuthState;

  const AuthState._();

  factory AuthState.initial({required final bool isAvailable}) => AuthState(
    isAvailable: isAvailable,
    isLoading: isAvailable,
  );
}
