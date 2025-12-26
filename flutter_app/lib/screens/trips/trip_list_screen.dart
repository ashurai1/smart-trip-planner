import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animations/animations.dart';
import '../../blocs/trips/trip_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/avatar_widget.dart';
import '../auth/login_screen.dart';
import 'trip_detail_screen.dart';
import 'invitations_screen.dart';
import '../../blocs/notifications/notification_bloc.dart';
import '../../widgets/notification_badge.dart';
import '../../widgets/notification_badge.dart';
import '../../widgets/notification_badge.dart';

import '../profile/profile_screen.dart'; // Add import

class TripListScreen extends StatefulWidget {
  const TripListScreen({Key? key}) : super(key: key);

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger load on init
    context.read<TripBloc>().add(LoadTrips());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: Text(
              'My Trips',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            centerTitle: false,
            backgroundColor: Theme.of(context).colorScheme.primary,
            expandedHeight: 120,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: FlexibleSpaceBar(
                 background: Stack(
                   children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Icon(Icons.flight_takeoff, size: 150, color: Colors.white.withOpacity(0.1)),
                      ),
                   ]
                 ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white),
                tooltip: 'My Profile',
                onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                },
              ),
              BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  return IconButton(
                    icon: NotificationBadge(
                      count: state.invitesCount,
                      child: const Icon(Icons.mail_outlined, color: Colors.white),
                    ),
                    tooltip: 'Invitations',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InvitationsScreen()),
                      ).then((_) {
                          if (mounted) context.read<TripBloc>().add(LoadTrips());
                          // Reload notifications on return to refresh badge
                          context.read<NotificationBloc>().add(LoadNotifications());
                      });
                    },
                  );
                }
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () {
                  context.read<AuthBloc>().add(LogoutRequested());
                  Navigator.of(context).pushReplacementNamed('/login');
                },
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            sliver: BlocBuilder<TripBloc, TripState>(
              builder: (context, state) {
                if (state is TripLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                // Handle Initial state explicitly (show loader too)
                if (state is TripInitial) {
                   return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is TripError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                          const SizedBox(height: 16),
                          Text(state.message),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.read<TripBloc>().add(LoadTrips()),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is TripLoaded) {
                  if (state.trips.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0,10))
                                ]
                              ),
                              child: Icon(
                                Icons.map_outlined,
                                size: 64,
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No trips yet',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create your first trip to get started!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final trip = state.trips[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _TripCard(trip: trip, index: index),
                        );
                      },
                      childCount: state.trips.length,
                    ),
                  );
                }

                return const SliverToBoxAdapter(child: SizedBox());
              },
            ),
          ),
          
          // COPYRIGHT FOOTER
          SliverFillRemaining(
             hasScrollBody: false,
             child: Column(
               mainAxisAlignment: MainAxisAlignment.end,
               children: [
                 const Divider(height: 1),
                 Container(
                   width: double.infinity,
                   padding: const EdgeInsets.symmetric(vertical: 24),
                   color: Colors.grey[50],
                   child: Column(
                     children: [
                        Text(
                          '© 2025 Smart Trip Planner', 
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Built by Ashwani Rai', 
                          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500])
                        ),
                     ],
                   ),
                 ),
               ],
             ),
          ),
        ],
      ),
      floatingActionButton: OpenContainer(
        transitionType: ContainerTransitionType.fadeThrough,
        openBuilder: (context, _) => const _CreateTripForm(), 
        closedElevation: 8,
        closedShape: const RoundedRectangleBorder(
           borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        closedColor: Theme.of(context).colorScheme.secondary,
        tappable: false, 
        closedBuilder: (context, openContainer) => FloatingActionButton.extended(
          onPressed: openContainer,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          icon: const Icon(Icons.add_rounded),
          label: Text('New Trip', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final int index;

  const _TripCard({required this.trip, required this.index});

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 600),
      openBuilder: (context, closeContainer) => TripDetailScreen(tripId: trip.id),
      closedElevation: 0,
      closedColor: Colors.transparent, 
      closedBuilder: (context, openContainer) {
        return InkWell(
          onTap: openContainer,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                 BoxShadow(
                   color: const Color(0xFF90A4AE).withOpacity(0.15),
                   blurRadius: 20,
                   offset: const Offset(0, 8),
                 ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Cover Image Area
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    gradient: LinearGradient(
                      colors: [
                         Theme.of(context).colorScheme.primary, // Darker
                         const Color(0xFF4DB6AC), // Lighter Teal
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative pattern
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Icon(Icons.public, size: 140, color: Colors.white.withOpacity(0.1)),
                      ),
                      Positioned(
                        left: 24,
                        bottom: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Text(
                                'TRIP',
                                style: GoogleFonts.inter(
                                  color: Colors.white, 
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              trip.title,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.1,
                                shadows: [
                                  Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: Offset(0, 2))
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                
                // 2. Info Area
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (trip.description != null && trip.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            trip.description!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
                            ),
                            child: AvatarWidget(
                              avatar: trip.owner.avatar,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Organized by',
                                style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.w600),
                              ),
                              Text(
                                trip.owner.username,
                                style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(
                               color: Colors.grey[50],
                               shape: BoxShape.circle,
                             ),
                             child: Icon(
                               Icons.arrow_forward_rounded,
                               size: 16,
                               color: Theme.of(context).colorScheme.primary,
                             ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


class _CreateTripForm extends StatefulWidget {
  const _CreateTripForm({Key? key}) : super(key: key);

  @override
  State<_CreateTripForm> createState() => _CreateTripFormState();
}

class _CreateTripFormState extends State<_CreateTripForm> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;
  Future<void> _createTrip() async {
    if (_titleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a trip title'), backgroundColor: Colors.orange),
        );
        return;
    }

    setState(() => _isLoading = true);
    
    try {
      final api = ApiService(); 
      await api.createTrip(
        _titleController.text.trim(), 
        _descController.text.trim(),
      );
      if (mounted) {
         // Trigger refresh in background
         context.read<TripBloc>().add(RefreshTrips());
         Navigator.pop(context);
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip created successfully')),
         );
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
         );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Trip')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
           Text(
             'Where to next?',
             style: Theme.of(context).textTheme.headlineMedium?.copyWith(
               color: Theme.of(context).colorScheme.primary,
               fontWeight: FontWeight.bold,
             ),
           ),
           const SizedBox(height: 8),
           const Text(
             'Start planning your next adventure by giving it a name.',
             style: TextStyle(color: Colors.grey),
           ),
           const SizedBox(height: 24),
            

            
            const SizedBox(height: 24),
           TextField(
             controller: _titleController,
             decoration: const InputDecoration(
               labelText: 'Trip Title (e.g., Summer in Paris)',
               prefixIcon: Icon(Icons.flight),
             ),
           ),
           const SizedBox(height: 24),
           TextField(
             controller: _descController,
             decoration: const InputDecoration(
               labelText: 'Description (Optional)',
               prefixIcon: Icon(Icons.notes),
               alignLabelWithHint: true,
             ),
             maxLines: 4,
           ),
           const SizedBox(height: 48),
           ElevatedButton(
             onPressed: _isLoading ? null : _createTrip,
             child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text('Create Trip'),
           ),
        ],
      ),
    );
  }
}
