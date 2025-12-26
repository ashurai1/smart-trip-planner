/// Trip model matching Django backend
class Trip {
  final String id;
  final String title;
  final String? description;
  final User owner;
  final List<User> collaborators;
  final DateTime createdAt;

  Trip({
    required this.id,
    required this.title,
    this.description,
    required this.owner,
    required this.collaborators,
    required this.createdAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Untitled Trip',
      description: json['description'],
      owner: User.fromJson(json['owner'] ?? {}),
      collaborators: (json['collaborators'] as List? ?? [])
          .map((c) => User.fromJson(c))
          .toList(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}

/// Avatar Data model
class AvatarData {
  final String style;
  final String color;
  final String icon;

  AvatarData({
    this.style = 'circle',
    this.color = 'blue',
    this.icon = 'person',
  });

  factory AvatarData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AvatarData();
    return AvatarData(
      style: json['style'] ?? 'circle',
      color: json['color'] ?? 'blue',
      icon: json['icon'] ?? 'person',
    );
  }
  
  Map<String, dynamic> toJson() => {
    'style': style,
    'color': color,
    'icon': icon,
  };
}

/// User model
class User {
  final int id;
  final String username;
  final String email;
  final AvatarData avatar;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : 0,
      username: json['username'] ?? 'Unknown User',
      email: json['email'] ?? '',
      avatar: AvatarData.fromJson(json['avatar']),
    );
  }
}

/// Itinerary Item model
class ItineraryItem {
  final int id;
  final String title;
  final String? description;
  final int order;
  final int? createdBy; // ID of creator
  final DateTime createdAt;

  ItineraryItem({
    required this.id,
    required this.title,
    this.description,
    required this.order,
    this.createdBy,
    required this.createdAt,
  });

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Untitled Item',
      description: json['description'],
      order: json['order'] ?? 0,
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}

/// Poll model
class Poll {
  final int id;
  final String question;
  final List<PollOption> options;
  final bool hasVoted;
  final User createdBy;
  final DateTime createdAt;

  Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.hasVoted,
    required this.createdBy,
    required this.createdAt,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'] ?? 0,
      question: json['question'] ?? 'No Question',
      options: (json['options'] as List? ?? [])
          .map((o) => PollOption.fromJson(o))
          .toList(),
      hasVoted: json['has_voted'] ?? false,
      createdBy: User.fromJson(json['created_by'] ?? {}),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}

/// Poll Option model
class PollOption {
  final int id;
  final String text;
  final int voteCount;

  PollOption({
    required this.id,
    required this.text,
    required this.voteCount,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'],
      text: json['text'],
      voteCount: json['vote_count'] ?? 0,
    );
  }
}

/// Chat Message model
class ChatMessage {
  final int id;
  final User sender;
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      sender: User.fromJson(json['sender']),
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Full User Profile model
class UserProfile {
  final int userId;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String bio;
  final String phoneNumber;
  final AvatarData avatar;

  UserProfile({
    required this.userId,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.bio,
    required this.phoneNumber,
    required this.avatar,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      bio: json['bio'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      avatar: AvatarData.fromJson(json['avatar']),
    );
  }

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? username : name;
  }
}
