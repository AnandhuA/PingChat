part of 'devices_list_cubit.dart';

@immutable
sealed class DevicesListState {}

final class DevicesListInitial extends DevicesListState {}

final class DevicesListLoadingState extends DevicesListState {}

final class DevicesListErrorState extends DevicesListState {}

final class DevicesListSuccessState extends DevicesListState {
  final Map<String, String> devices;

  DevicesListSuccessState({required this.devices});
}
