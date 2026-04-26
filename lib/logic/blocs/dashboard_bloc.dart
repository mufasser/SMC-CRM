import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/car_model.dart';
import '../../data/repositories/car_repository.dart';

// Events
abstract class DashboardEvent {}

class FetchDashboardData extends DashboardEvent {}

// States
class DashboardState {
  final List<CarModel> recentLeads;
  final bool isLoading;
  final String? error;

  DashboardState({
    this.recentLeads = const [],
    this.isLoading = false,
    this.error,
  });
}

// Bloc
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final CarRepository repository;

  DashboardBloc(this.repository) : super(DashboardState(isLoading: true)) {
    on<FetchDashboardData>((event, emit) async {
      emit(DashboardState(isLoading: true));
      try {
        final leads = await repository.getDashboardLeads();
        emit(DashboardState(recentLeads: leads, isLoading: false));
      } catch (e) {
        emit(DashboardState(isLoading: false, error: e.toString()));
      }
    });
  }
}
