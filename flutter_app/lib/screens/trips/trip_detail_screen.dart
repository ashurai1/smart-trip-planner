import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/trips/trip_bloc.dart';
import '../../blocs/notifications/notification_bloc.dart';
import '../../widgets/notification_badge.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/avatar_widget.dart';
import '../../utils/date_time_utils.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;

  const TripDetailScreen({Key? key, required this.tripId}) : super(key: key);

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  int? _currentUserId;
  Map<String, dynamic>? _tripData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Mark initial tab as read (Itinerary)
    context.read<NotificationBloc>().add(MarkAsRead(widget.tripId, 'itinerary'));
    
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        String type = 'itinerary';
        switch (_tabController.index) {
          case 0: type = 'itinerary'; break;
          case 1: type = 'poll'; break;
          case 2: type = 'chat'; break;
        }
        context.read<NotificationBloc>().add(MarkAsRead(widget.tripId, type));
      }
    });

    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      final profile = await _apiService.getProfile();
      final trip = await _apiService.getTripDetail(widget.tripId);
      if (mounted) {
        setState(() {
          _currentUserId = profile.userId;
          _tripData = trip;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _deleteTrip() async {
      final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text('Are you sure you want to delete this ENTIRE trip? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      // Optimistic delete via Bloc
      context.read<TripBloc>().add(DeleteTrip(widget.tripId));
      Navigator.pop(context); // Return to list immediately
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleting trip...')));
    }
  }

  Future<void> _showAddMemberDialog(BuildContext context) async {
    final controller = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Invite Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               const Text("Enter the email or username of the person you want to invite.", style: TextStyle(color: Colors.grey)),
               const SizedBox(height: 16),
               TextField(
                 controller: controller,
                 decoration: const InputDecoration(
                   labelText: 'Email or Username',
                   hintText: 'user@example.com or username',
                   prefixIcon: Icon(Icons.person_add_outlined),
                   border: OutlineInputBorder(),
                 ),
                 autofocus: true,
               ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Cancel')
            ),
            ElevatedButton(
                onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                        Navigator.pop(context);
                        context.read<TripBloc>().add(InviteMember(widget.tripId, controller.text));
                    }
                }, 
                child: const Text('Send Invite')
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _tripData != null && _currentUserId != null && _tripData!['owner']['id'] == _currentUserId;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocListener<TripBloc, TripState>(
        listener: (context, state) {
          if (state is TripOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
            ));
          } else if (state is TripError) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
            ));
          } else if (state is TripOperationLoading) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Sending invitation...'),
                duration: Duration(seconds: 1),
            ));
          }
        },
        child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              title: Text(
                _tripData?['title'] ?? 'Trip Details',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              centerTitle: false,
              backgroundColor: Theme.of(context).colorScheme.primary,
              expandedHeight: 140,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
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
                        right: -40,
                        top: -20,
                        child: Icon(Icons.map, size: 200, color: Colors.white.withOpacity(0.1)),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_add_outlined, color: Colors.white), 
                  onPressed: () => _showAddMemberDialog(context),
                  tooltip: 'Invite Member',
                ),
                if (isOwner)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'delete') _deleteTrip();
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete Trip', style: TextStyle(color: Colors.red)),
                        ),
                      ];
                    },
                  ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: BlocBuilder<NotificationBloc, NotificationState>(
                  builder: (context, state) {
                    return TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.white,
                      indicatorWeight: 4,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                      tabs: [
                        Tab(
                          child: NotificationBadge(
                            count: state.getCount(widget.tripId, 'itinerary'),
                            color: Colors.orange,
                            child: const Text('Itinerary'),
                          ),
                        ),
                        Tab(
                          child: NotificationBadge(
                            count: state.getCount(widget.tripId, 'poll'),
                            color: Colors.orange,
                            child: const Text('Polls'),
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              NotificationBadge(
                                count: state.getCount(widget.tripId, 'chat'),
                                color: Colors.orange,
                                child: const Text('Chat'),
                              ),
                              if (state.getCount(widget.tripId, 'chat') > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ).animate(onPlay: (controller) => controller.repeat())
                                  .fadeIn(duration: 600.ms)
                                  .then()
                                  .fadeOut(duration: 600.ms),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            ItineraryTab(tripId: widget.tripId, apiService: _apiService, currentUserId: _currentUserId, isTripOwner: isOwner),
            PollsTab(tripId: widget.tripId, apiService: _apiService, currentUserId: _currentUserId, isTripOwner: isOwner),
            ChatTab(tripId: widget.tripId, apiService: _apiService, currentUserId: _currentUserId),
          ],
        ),
      ),
    ),
    );
  }
}

// ========== ITINERARY TAB ==========

class ItineraryTab extends StatefulWidget {
  final String tripId;
  final ApiService apiService;
  final int? currentUserId;
  final bool isTripOwner;

  const ItineraryTab({Key? key, required this.tripId, required this.apiService, this.currentUserId, this.isTripOwner = false}) : super(key: key);

  @override
  State<ItineraryTab> createState() => _ItineraryTabState();
}

class _ItineraryTabState extends State<ItineraryTab> {
  List<ItineraryItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final data = await widget.apiService.getItineraryItems(widget.tripId);
      if (mounted) {
        setState(() {
          _items = data.map((json) => ItineraryItem.fromJson(json)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteItem(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this plan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      // Optimistic Update
      final previousItems = List<ItineraryItem>.from(_items);
      setState(() {
        _items.removeWhere((item) => item.id == id);
      });

      try {
        await widget.apiService.deleteItineraryItem(widget.tripId, id);
      } catch (e) {
        // Revert on failure
        if (mounted) {
            setState(() => _items = previousItems);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      }
    }
  }
  
  Future<void> _addItem() async {
      final titleController = TextEditingController();
      final descController = TextEditingController();
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Plan'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
          ],
        ),
      );
      if (result == true) {
         await widget.apiService.addItineraryItem(widget.tripId, titleController.text, descController.text);
         _loadItems();
      }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      backgroundColor: Colors.transparent, // Let parent background show
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem, 
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        onReorder: (oldIndex, newIndex) {
            // Reorder Logic
        },
        itemBuilder: (context, index) {
          final item = _items[index];
          final isCreator = widget.currentUserId != null && item.createdBy == widget.currentUserId;
          final canDelete = isCreator || widget.isTripOwner;
          
          return Container(
            key: ValueKey(item.id),
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline Column
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Container(
                      height: 50, // Line height
                      width: 2,
                      color: index == _items.length - 1 ? Colors.transparent : Colors.grey.withOpacity(0.3),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Content Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: const Color(0xFF102A43),
                                ),
                              ),
                            ),
                            if (canDelete)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _deleteItem(item.id),
                              ),
                          ],
                        ),
                        if (item.description != null && item.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            item.description!,
                            style: GoogleFonts.inter(
                              color: Colors.grey[600],
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ========== POLLS TAB ==========

class PollsTab extends StatefulWidget {
  final String tripId;
  final ApiService apiService;
  final int? currentUserId;
  final bool isTripOwner;

  const PollsTab({Key? key, required this.tripId, required this.apiService, this.currentUserId, this.isTripOwner = false}) : super(key: key);

  @override
  State<PollsTab> createState() => _PollsTabState();
}

class _PollsTabState extends State<PollsTab> {
  List<Poll> _polls = [];
  bool _loading = true;
  final Map<int, int> _selectedOptions = {}; 

  @override
  void initState() {
    super.initState();
    _loadPolls();
  }

  Future<void> _loadPolls() async {
      try {
        final data = await widget.apiService.getPolls(widget.tripId);
        if (mounted) {
            setState(() {
                _polls = data.map((json) => Poll.fromJson(json)).toList();
                _loading = false;
            });
        }
      } catch (e) {
         if (mounted) setState(() => _loading = false);
      }
  }

  Future<void> _vote(int pollId) async {
      final optionId = _selectedOptions[pollId];
      if (optionId == null) return;
      
      try {
          await widget.apiService.vote(pollId, optionId);
          await _loadPolls();
          setState(() {
              _selectedOptions.remove(pollId);
          });
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voted successfully!')));
      } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vote failed: $e')));
      }
  }

  Future<void> _deletePoll(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Poll'),
        content: const Text('Are you sure you want to dismiss this poll?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      // Optimistic Update
      final previousPolls = List<Poll>.from(_polls);
      setState(() {
        _polls.removeWhere((p) => p.id == id);
      });

      try {
          await widget.apiService.deletePoll(widget.tripId, id);
      } catch (e) {
          // Revert
          if (mounted) {
              setState(() => _polls = previousPolls);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
          }
      }
    }
  }
  
  Future<void> _createPoll() async {
      final questionController = TextEditingController();
      final List<TextEditingController> optionControllers = [
          TextEditingController(),
          TextEditingController()
      ];
      
      await showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
              builder: (context, setDialogState) => AlertDialog(
                  title: const Text('Create Poll'),
                  content: SingleChildScrollView(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                              TextField(controller: questionController, decoration: const InputDecoration(labelText: 'Question')),
                              const SizedBox(height: 16),
                              ...optionControllers.asMap().entries.map((entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(children: [
                                      Expanded(child: TextField(controller: entry.value, decoration: InputDecoration(labelText: 'Option ${entry.key + 1}'))),
                                  ])
                              )),
                              TextButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Option'),
                                  onPressed: () {
                                      setDialogState(() {
                                          optionControllers.add(TextEditingController());
                                      });
                                  }
                              )
                          ]
                      )
                  ),
                  actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      ElevatedButton(
                          onPressed: () async {
                              final question = questionController.text;
                              final options = optionControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList();
                              if (question.isNotEmpty && options.length >= 2) {
                                  Navigator.pop(context);
                                  try {
                                      await widget.apiService.createPoll(widget.tripId, question, options);
                                      _loadPolls();
                                  } catch (e) {
                                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                  }
                              }
                          },
                          child: const Text('Create')
                      ),
                  ],
              )
          )
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    
    if (_polls.isEmpty) {
        return Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _createPoll, 
              label: const Text('Create Poll'), 
              icon: const Icon(Icons.poll),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.how_to_vote_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Start a vote!', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            ),
        );
    }

    return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          onPressed: _createPoll, 
          child: const Icon(Icons.add),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _polls.length,
            itemBuilder: (context, index) {
                final poll = _polls[index];
                final isCreator = widget.currentUserId != null && poll.createdBy.id == widget.currentUserId;
                final canDelete = isCreator || widget.isTripOwner;
                
                return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.06),
                           blurRadius: 15,
                           offset: const Offset(0, 5),
                         ),
                      ],
                    ),
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                        Expanded(
                                          child: Text(
                                            poll.question, 
                                            style: GoogleFonts.poppins(
                                              fontSize: 18, 
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF102A43)
                                            )
                                          )
                                        ),
                                        if (canDelete) 
                                            IconButton(
                                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                                onPressed: () => _deletePoll(poll.id),
                                                tooltip: 'Delete Poll',
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                            )
                                    ],
                                ),
                                const SizedBox(height: 16),
                                if (poll.hasVoted) 
                                    // RESULTS VIEW
                                    ...poll.options.map((option) {
                                        final totalVotes = poll.options.fold(0, (sum, item) => sum + item.voteCount);
                                        final percentage = totalVotes == 0 ? 0.0 : (option.voteCount / totalVotes);
                                        final isLeading = percentage > 0 && percentage == poll.options.map((o) => o.voteCount / totalVotes).reduce((curr, next) => curr > next ? curr : next);
                                        
                                        return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                    Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                            Text(
                                                              option.text,
                                                              style: TextStyle(
                                                                fontWeight: isLeading ? FontWeight.bold : FontWeight.normal,
                                                                color: isLeading ? Theme.of(context).colorScheme.primary : Colors.black87,
                                                              ),
                                                            ),
                                                            Text('${(percentage * 100).toStringAsFixed(0)}%', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                                                        ]
                                                    ),
                                                    const SizedBox(height: 6),
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(4),
                                                      child: LinearProgressIndicator(
                                                        value: percentage, 
                                                        backgroundColor: Colors.grey[100],
                                                        valueColor: AlwaysStoppedAnimation<Color>(
                                                          isLeading ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withOpacity(0.5)
                                                        ),
                                                        minHeight: 8,
                                                      ),
                                                    ),
                                                ]
                                            )
                                        );
                                    })
                                else 
                                    // VOTE VIEW
                                    Column(
                                        children: [
                                            ...poll.options.map((option) => Container(
                                              margin: const EdgeInsets.only(bottom: 8),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: _selectedOptions[poll.id] == option.id 
                                                      ? Theme.of(context).colorScheme.primary 
                                                      : Colors.grey[200]!
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                                color: _selectedOptions[poll.id] == option.id 
                                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                                                    : Colors.transparent,
                                              ),
                                              child: RadioListTile<int>(
                                                  title: Text(option.text, style: GoogleFonts.inter(fontSize: 14)),
                                                  value: option.id,
                                                  groupValue: _selectedOptions[poll.id],
                                                  onChanged: (val) {
                                                      setState(() {
                                                          _selectedOptions[poll.id] = val!;
                                                      });
                                                  },
                                                  activeColor: Theme.of(context).colorScheme.primary,
                                                  dense: true,
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                            )),
                                            const SizedBox(height: 12),
                                            SizedBox(
                                                width: double.infinity,
                                                height: 48,
                                                child: ElevatedButton(
                                                    onPressed: _selectedOptions[poll.id] == null ? null : () => _vote(poll.id),
                                                    style: ElevatedButton.styleFrom(
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                      elevation: 0,
                                                    ),
                                                    child: const Text('Submit Vote'),
                                                )
                                            )
                                        ]
                                    ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.person, size: 14, color: Colors.grey[400]),
                                    const SizedBox(width: 4),
                                    Text('Poll by ${poll.createdBy.username}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                  ],
                                ),
                            ]
                        )
                    )
                );
            }
        )
    );
  }
}

// ========== CHAT TAB ==========

class ChatTab extends StatefulWidget {
  final String tripId;
  final ApiService apiService;
  final int? currentUserId;

  const ChatTab({
    Key? key, 
    required this.tripId, 
    required this.apiService, 
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  List<ChatMessage> _messages = [];
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadMessages(initialLoad: true);
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _loadMessages());
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages({bool initialLoad = false}) async {
      final data = await widget.apiService.getChatMessages(widget.tripId);
      if (!mounted) return;
      setState(() {
          _messages = data.map((json) => ChatMessage.fromJson(json)).toList();
      });
      // Scroll handling...
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;
    
    // Optimistic Append (optional, but requested "update instantly")
    // For now, let's stick to delete fix first as it was critical. 
    // Actually, user said "Any create ... works only after refresh".
    // I should implement optimistic send too.
    
    final tempMsg = ChatMessage(
      id: -1, 
      sender: User(
        id: widget.currentUserId ?? 0, 
        username: 'Me', 
        email: '', // Not needed for UI
        avatar: AvatarData(style: 'circle', color: 'blue', icon: 'person')
      ),
      message: _messageController.text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(tempMsg);
    });

    final textToSend = _messageController.text;
    _messageController.clear();
    
    try {
        await widget.apiService.sendMessage(
          widget.tripId, 
          textToSend, 
        );
        _loadMessages(); // Refresh to get real ID
    } catch (e) {
        if (mounted) {
           setState(() {
             _messages.remove(tempMsg);
           });
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
        }
    }
  }

  Future<void> _deleteMessage(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Remove this message?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
       final previousMessages = List<ChatMessage>.from(_messages);
       setState(() {
         _messages.removeWhere((m) => m.id == id);
       });
       
       try {
         await widget.apiService.deleteMessage(widget.tripId, id);
       } catch (e) {
         if (mounted) {
            setState(() => _messages = previousMessages);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
         }
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
            Expanded(
                child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe = widget.currentUserId != null && msg.sender.id == widget.currentUserId;
                        
                        return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                    if (!isMe) ...[
                                      AvatarWidget(
                                          avatar: msg.sender.avatar,
                                          size: 28,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    
                                    GestureDetector(
                                      onLongPress: () {
                                         if (isMe) _deleteMessage(msg.id);
                                      },
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                        child: Column(
                                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                            children: [
                                                if (!isMe)
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                                                    child: Text(msg.sender.username, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                                  ),
                                                
                                                Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                        color: isMe ? Theme.of(context).colorScheme.primary : Colors.white,
                                                        borderRadius: BorderRadius.only(
                                                            topLeft: const Radius.circular(16),
                                                            topRight: const Radius.circular(16),
                                                            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                                                            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                                                        ),
                                                        boxShadow: [
                                                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))
                                                        ]
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        if (msg.message.isNotEmpty)
                                                          Text(
                                                            msg.message, 
                                                            style: GoogleFonts.inter(
                                                              fontSize: 14, 
                                                              color: isMe ? Colors.white : Colors.black87
                                                            )
                                                          ),
                                                      ],
                                                    ),
                                                ),
                                                
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4, left: 4),
                                                  child: Text(
                                                    DateTimeUtils.formatSmartDate(msg.createdAt),
                                                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                                                  ),
                                                ),
                                            ],
                                        ),
                                      ),
                                    ),
                                ],
                            )
                        );
                    }
                )
            ),
            
            // Input Area
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                    ],
                ),
                child: SafeArea(
                  child: Row(
                      children: [
                          Expanded(
                              child: TextField(
                                  controller: _messageController, 
                                  decoration: InputDecoration(
                                      hintText: 'Type a message...',
                                      hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(24),
                                          borderSide: BorderSide.none,
                                      ),
                                  ),
                                  textCapitalization: TextCapitalization.sentences,
                              )
                          ),
                          const SizedBox(width: 12),
                          Container(
                              decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), 
                                  onPressed: _sendMessage
                              ),
                          ),
                      ]
                  )
                )
            )
        ]
    );
  }
}
