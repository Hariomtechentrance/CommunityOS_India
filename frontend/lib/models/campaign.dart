enum CampaignObjective { sales, downloads, awareness, engagement }

enum CampaignTargetType { nearby, pincode, states, allIndia }

enum CampaignStatus { draft, pendingPayment, active, completed, rejected }

CampaignObjective campaignObjectiveFromJson(String value) =>
    CampaignObjective.values.firstWhere((e) => e.name.toUpperCase() == value, orElse: () => CampaignObjective.awareness);

CampaignTargetType campaignTargetTypeFromJson(String value) {
  switch (value) {
    case 'NEARBY':
      return CampaignTargetType.nearby;
    case 'PINCODE':
      return CampaignTargetType.pincode;
    case 'STATES':
      return CampaignTargetType.states;
    case 'ALL_INDIA':
    default:
      return CampaignTargetType.allIndia;
  }
}

String campaignTargetTypeToJson(CampaignTargetType type) {
  switch (type) {
    case CampaignTargetType.nearby:
      return 'NEARBY';
    case CampaignTargetType.pincode:
      return 'PINCODE';
    case CampaignTargetType.states:
      return 'STATES';
    case CampaignTargetType.allIndia:
      return 'ALL_INDIA';
  }
}

String campaignObjectiveToJson(CampaignObjective objective) => objective.name.toUpperCase();

CampaignStatus campaignStatusFromJson(String value) {
  switch (value) {
    case 'DRAFT':
      return CampaignStatus.draft;
    case 'PENDING_PAYMENT':
      return CampaignStatus.pendingPayment;
    case 'ACTIVE':
      return CampaignStatus.active;
    case 'COMPLETED':
      return CampaignStatus.completed;
    case 'REJECTED':
      return CampaignStatus.rejected;
    default:
      return CampaignStatus.draft;
  }
}

String campaignStatusLabel(CampaignStatus status) {
  switch (status) {
    case CampaignStatus.draft:
      return 'Draft';
    case CampaignStatus.pendingPayment:
      return 'Awaiting payment';
    case CampaignStatus.active:
      return 'Active';
    case CampaignStatus.completed:
      return 'Completed';
    case CampaignStatus.rejected:
      return 'Rejected';
  }
}

class CampaignAuthor {
  final String id;
  final String? name;
  final String? avatarUrl;

  CampaignAuthor({required this.id, this.name, this.avatarUrl});

  factory CampaignAuthor.fromJson(Map<String, dynamic> json) => CampaignAuthor(
        id: json['id'] as String,
        name: json['name'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );
}

class Campaign {
  final String id;
  final CampaignObjective objective;
  final String title;
  final String description;
  final String? imageUrl;
  final String? ctaUrl;
  final CampaignTargetType targetType;
  final String? targetPincode;
  final List<String> targetStates;
  final double? targetLatitude;
  final double? targetLongitude;
  final double? targetRadiusKm;
  final int budgetInPaise;
  final CampaignStatus status;
  final DateTime? startDate;
  final DateTime createdAt;
  final CampaignAuthor? user;

  Campaign({
    required this.id,
    required this.objective,
    required this.title,
    required this.description,
    this.imageUrl,
    this.ctaUrl,
    required this.targetType,
    this.targetPincode,
    required this.targetStates,
    this.targetLatitude,
    this.targetLongitude,
    this.targetRadiusKm,
    required this.budgetInPaise,
    required this.status,
    this.startDate,
    required this.createdAt,
    this.user,
  });

  double get budgetInRupees => budgetInPaise / 100;

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
        id: json['id'] as String,
        objective: campaignObjectiveFromJson(json['objective'] as String),
        title: json['title'] as String,
        description: json['description'] as String,
        imageUrl: json['imageUrl'] as String?,
        ctaUrl: json['ctaUrl'] as String?,
        targetType: campaignTargetTypeFromJson(json['targetType'] as String),
        targetPincode: json['targetPincode'] as String?,
        targetStates: (json['targetStates'] as List?)?.map((e) => e as String).toList() ?? [],
        targetLatitude: (json['targetLatitude'] as num?)?.toDouble(),
        targetLongitude: (json['targetLongitude'] as num?)?.toDouble(),
        targetRadiusKm: (json['targetRadiusKm'] as num?)?.toDouble(),
        budgetInPaise: json['budgetInPaise'] as int,
        status: campaignStatusFromJson(json['status'] as String),
        startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        user: json['user'] != null ? CampaignAuthor.fromJson(json['user'] as Map<String, dynamic>) : null,
      );
}
