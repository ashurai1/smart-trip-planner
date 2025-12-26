import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

// ========== EVENTS ==========

abstract class TripEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTrips extends TripEvent {}

class DeleteTrip extends TripEvent {
  final String tripId;
  DeleteTrip(this.tripId);
  @override
  List<Object?> get props => [tripId];
}

class RefreshTrips extends TripEvent {}

class InviteMember extends TripEvent {
  final String tripId;
  final String identifier;

  InviteMember(this.tripId, this.identifier);

  @override
  List<Object?> get props => [tripId, identifier];
}

// ... unchanged ...


// ... (skipping unchanged states) ...


// ========== STATES ==========

abstract class TripState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TripInitial extends TripState {}

class TripLoading extends TripState {}

class TripLoaded extends TripState {
  final List<Trip> trips;

  TripLoaded(this.trips);

  @override
  List<Object?> get props => [trips];
}

class TripOperationLoading extends TripState {}

class TripOperationSuccess extends TripState {
  final String message;
  TripOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class TripError extends TripState {
  final String message;

  TripError(this.message);

  @override
  List<Object?> get props => [message];
}

// ========== BLOC ==========

class TripBloc extends Bloc<TripEvent, TripState> {
  final ApiService apiService;

  TripBloc(this.apiService) : super(TripInitial()) {
    on<LoadTrips>(_onLoadTrips);
    on<RefreshTrips>(_onRefreshTrips);
    on<InviteMember>(_onInviteMember);
    on<DeleteTrip>(_onDeleteTrip);
  }

  Future<void> _onLoadTrips(
    LoadTrips event,
    Emitter<TripState> emit,
  ) async {
    print('TripBloc: Loading trips...');
    emit(TripLoading());
    try {
      final data = await apiService.getTrips();
      print('TripBloc: Received ${data.length} records. Parsing...');
      final trips = data.map((json) => Trip.fromJson(json)).toList();
      print('TripBloc: Parsed ${trips.length} trips. Emitting TripLoaded.');
      emit(TripLoaded(trips));
    } catch (e) {
      print('TripBloc: Error loading trips: $e');
      emit(TripError('Failed to load trips: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshTrips(
    RefreshTrips event,
    Emitter<TripState> emit,
  ) async {
    try {
      final data = await apiService.getTrips();
      final trips = data.map((json) => Trip.fromJson(json)).toList();
      emit(TripLoaded(trips));
    } catch (e) {
      emit(TripError('Failed to refresh trips: ${e.toString()}'));
    }
  }

  Future<void> _onInviteMember(
    InviteMember event,
    Emitter<TripState> emit,
  ) async {
    emit(TripOperationLoading());
    try {
      await apiService.inviteUser(event.tripId, event.identifier);
      emit(TripOperationSuccess('Invitation sent successfully'));
      add(RefreshTrips()); 
    } catch (e) {
      String msg = e.toString();
      // Clean up error message
      if (msg.contains('400')) msg = 'Invalid request. User might already be invited or member.';
      if (msg.contains('403')) msg = 'You are not authorized to invite members.';
      if (msg.contains('404')) msg = 'User not found.';
      emit(TripError(msg));
      add(LoadTrips());
    }
  }

  Future<void> _onDeleteTrip(
    DeleteTrip event,
    Emitter<TripState> emit,
  ) async {
    // 1. Optimistic Update
    final currentState = state;
    List<Trip> currentTrips = [];
    
    if (currentState is TripLoaded) {
      currentTrips = List.from(currentState.trips);
      // Remove immediately
      final updatedTrips = currentTrips.where((t) => t.id != event.tripId).toList();
      emit(TripLoaded(updatedTrips));
    }

    try {
      // 2. Perform API Call
      await apiService.deleteTrip(event.tripId);
      // Success
    } catch (e) {
      // 3. Revert on Failure
      if (currentTrips.isNotEmpty) {
         emit(TripError('Delete failed. Restoring...'));
         await Future.delayed(const Duration(milliseconds: 1500));
         emit(TripLoaded(currentTrips)); 
      } else {
         emit(TripError('Delete failed: $e'));
         add(LoadTrips());
      }
    }
  }
}
