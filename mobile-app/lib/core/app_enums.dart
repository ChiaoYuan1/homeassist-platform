enum UserRole {
  customer,
  provider,
  technician,
  admin
}

enum BookingStatus {
  pending,
  accepted,
  rejected,
  onTheWay,
  arrived,
  inProgress,
  completed,
  cancelled,
  expired,
}

enum VerificationStatus {
  pending,
  approved,
  rejected
}

enum AvailabilityOverrideType {
  unavailable,
  available
}

enum ReportStatus {
  open,
  underReview,
  resolved,
  dismissed
}

extension UserRoleX on UserRole {
  String get value => name;
  static UserRole fromValue(String value) => UserRole.values.firstWhere(
        (role) => role.name == value,
    orElse: () => UserRole.customer,
  );
}

extension BookingStatusX on BookingStatus {
  String get value => name;

  String get label {
    switch (this) {
      case BookingStatus.pending: return 'Pending';
      case BookingStatus.accepted: return 'Accepted';
      case BookingStatus.rejected: return 'Rejected';
      case BookingStatus.onTheWay: return 'On the Way';
      case BookingStatus.arrived: return 'Arrived';
      case BookingStatus.inProgress: return 'In Progress';
      case BookingStatus.completed: return 'Completed';
      case BookingStatus.cancelled: return 'Cancelled';
      case BookingStatus.expired: return 'Expired';
    }
  }

  bool get blocksSchedule => {
    BookingStatus.pending,
    BookingStatus.accepted,
    BookingStatus.onTheWay,
    BookingStatus.arrived,
    BookingStatus.inProgress,
  }.contains(this);
  static BookingStatus fromValue(String value) => BookingStatus.values.firstWhere(
        (status) => status.name == value,
    orElse: () => BookingStatus.pending,
  );
}

extension VerificationStatusX on VerificationStatus {
  String get value => name;

  String get label {
    switch (this) {
      case VerificationStatus.pending: return 'Pending';
      case VerificationStatus.approved: return 'Approved';
      case VerificationStatus.rejected: return 'Rejected';
    }
  }
  static VerificationStatus fromValue(String value) => VerificationStatus.values.firstWhere(
        (status) => status.name == value,
    orElse: () => VerificationStatus.pending,
  );
}

extension ReportStatusX on ReportStatus {
  String get value => name;

  String get label {
    switch (this) {
      case ReportStatus.open: return 'Open';
      case ReportStatus.underReview: return 'Under Review';
      case ReportStatus.resolved: return 'Resolved';
      case ReportStatus.dismissed: return 'Dismissed';
    }
  }
  static ReportStatus fromValue(String value) => ReportStatus.values.firstWhere(
        (status) => status.name == value,
    orElse: () => ReportStatus.open,
  );
}
