part of 'public_profile_cubit.dart';

@freezed
abstract class PublicProfileState with _$PublicProfileState {
  const factory PublicProfileState({
    required final bool isAvailable,
    required final bool isLoading,
    required final bool isUpdating,
    required final bool enabled,
    required final SyncStatus syncStatus,
    final String? errorMessage,
  }) = _PublicProfileState;

  factory PublicProfileState.initial({required final SyncStatus syncStatus}) => PublicProfileState(
    isAvailable: true,
    isLoading: true,
    isUpdating: false,
    enabled: false,
    syncStatus: syncStatus,
  );
}
