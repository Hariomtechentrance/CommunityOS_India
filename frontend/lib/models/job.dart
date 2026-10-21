import 'user.dart';

enum JobType { fullTime, partTime, internship, freelance, dailyWage }

JobType jobTypeFromJson(String value) {
  switch (value) {
    case 'PART_TIME':
      return JobType.partTime;
    case 'INTERNSHIP':
      return JobType.internship;
    case 'FREELANCE':
      return JobType.freelance;
    case 'DAILY_WAGE':
      return JobType.dailyWage;
    default:
      return JobType.fullTime;
  }
}

String jobTypeToJson(JobType type) {
  switch (type) {
    case JobType.partTime:
      return 'PART_TIME';
    case JobType.internship:
      return 'INTERNSHIP';
    case JobType.freelance:
      return 'FREELANCE';
    case JobType.dailyWage:
      return 'DAILY_WAGE';
    case JobType.fullTime:
      return 'FULL_TIME';
  }
}

String jobTypeLabel(JobType type) {
  switch (type) {
    case JobType.fullTime:
      return 'Full-time';
    case JobType.partTime:
      return 'Part-time';
    case JobType.internship:
      return 'Internship';
    case JobType.freelance:
      return 'Freelance';
    case JobType.dailyWage:
      return 'Daily wage';
  }
}

const allJobTypes = JobType.values;

class JobPosting {
  final String id;
  final String area;
  final String? pincode;
  final String title;
  final String description;
  final String? companyName;
  final JobType jobType;
  final int? salaryMin;
  final int? salaryMax;
  final String? salaryPeriod;
  final String? location;
  final String? contactPhone;
  final String status;
  final DateTime createdAt;
  final AppUser? poster;
  final int applicationCount;

  JobPosting({
    required this.id,
    required this.area,
    this.pincode,
    required this.title,
    required this.description,
    this.companyName,
    required this.jobType,
    this.salaryMin,
    this.salaryMax,
    this.salaryPeriod,
    this.location,
    this.contactPhone,
    required this.status,
    required this.createdAt,
    this.poster,
    this.applicationCount = 0,
  });

  factory JobPosting.fromJson(Map<String, dynamic> json) => JobPosting(
        id: json['id'] as String,
        area: json['area'] as String,
        pincode: json['pincode'] as String?,
        title: json['title'] as String,
        description: json['description'] as String,
        companyName: json['companyName'] as String?,
        jobType: jobTypeFromJson(json['jobType'] as String),
        salaryMin: json['salaryMin'] as int?,
        salaryMax: json['salaryMax'] as int?,
        salaryPeriod: json['salaryPeriod'] as String?,
        location: json['location'] as String?,
        contactPhone: json['contactPhone'] as String?,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        poster: json['poster'] != null ? AppUser.fromJson(json['poster'] as Map<String, dynamic>) : null,
        applicationCount: json['_count'] != null
            ? (json['_count'] as Map<String, dynamic>)['applications'] as int? ?? 0
            : 0,
      );
}

class JobApplication {
  final String id;
  final String jobId;
  final String? message;
  final String status;
  final DateTime createdAt;
  final AppUser? applicant;
  final JobPosting? job;

  JobApplication({
    required this.id,
    required this.jobId,
    this.message,
    required this.status,
    required this.createdAt,
    this.applicant,
    this.job,
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) => JobApplication(
        id: json['id'] as String,
        jobId: json['jobId'] as String,
        message: json['message'] as String?,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        applicant:
            json['applicant'] != null ? AppUser.fromJson(json['applicant'] as Map<String, dynamic>) : null,
        job: json['job'] != null ? JobPosting.fromJson(json['job'] as Map<String, dynamic>) : null,
      );
}
