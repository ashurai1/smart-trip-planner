import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';

// Events
abstract class NotificationEvent {}

class LoadNotifications extends NotificationEvent {}
class MarkAsRead extends NotificationEvent {
  final String tripId;
  final String type; // 'chat', 'poll', 'itinerary'
  MarkAsRead(this.tripId, this.type);
}

// State
class NotificationState {
  final int invitesCount;
  final Map<String, Map<String, int>> tripCounts; // tripId -> {chat: 5, poll: 0...}

  NotificationState({
    this.invitesCount = 0,
    this.tripCounts = const {},
  });
  
  // Helper to get count for a specific trip & type
  int getCount(String tripId, String type) {
    if (!tripCounts.containsKey(tripId)) return 0;
    return tripCounts[tripId]?[type] ?? 0;
  }
}

// Bloc
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final ApiService _apiService;
  Timer? _pollingTimer;

  NotificationBloc(this._apiService) : super(NotificationState()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkAsRead>(_onMarkAsRead);
    
    // Auto-poll every 10 seconds (Simple polling for MVP)
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      add(LoadNotifications());
    });
  }

  Future<void> _onLoadNotifications(LoadNotifications event, Emitter<NotificationState> emit) async {
    try {
      final data = await _apiService.getNotifications();
      
      final int newInvites = data['invitations'] ?? 0;
      final Map<String, dynamic> rawTrips = data['trips'] ?? {};
      
      final Map<String, Map<String, int>> newTripCounts = {};
      
      rawTrips.forEach((key, value) {
         if (value is Map) {
           newTripCounts[key] = {
             'chat': value['chat'] ?? 0,
             'poll': value['poll'] ?? 0,
             'itinerary': value['itinerary'] ?? 0,
           };
         }
      });
      
      emit(NotificationState(
        invitesCount: newInvites,
        tripCounts: newTripCounts,
      ));
    } catch (e) {
      print('NotificationBloc Error: $e');
    }
  }

  Future<void> _onMarkAsRead(MarkAsRead event, Emitter<NotificationState> emit) async {
    try {
      // Optimistic update
      final currentMap = Map<String, Map<String, int>>.from(state.tripCounts);
      if (currentMap.containsKey(event.tripId)) {
        final innerMap = Map<String, int>.from(currentMap[event.tripId]!);
        innerMap[event.type] = 0;
        currentMap[event.tripId] = innerMap;
        emit(NotificationState(invitesCount: state.invitesCount, tripCounts: currentMap));
      }
      
      // Call API
      await _apiService.markNotificationAsRead(event.tripId, event.type);
      
      // Reload to ensure sync
      add(LoadNotifications());
    } catch (e) {
      // Revert if needed, but simple reload next tick handles it mostly
      print('MarkAsRead Error: $e');
    }
  }
  
  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }
}
