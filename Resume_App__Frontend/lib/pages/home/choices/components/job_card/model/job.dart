class Job {
  final int id;
  final String title;
  final String company;
  final String? location;
  final String? salary;
  final String? companyLogo;
  final String? description;
  final bool isPremium;
  bool isSaved;

  Job({
    required this.id,
    required this.title,
    required this.company,
    this.location,
    this.salary,
    this.companyLogo,
    this.description,
    this.isSaved = false,
    this.isPremium = false,
  });

  factory Job.fromMap(Map<String, dynamic> data) {
    return Job(
      id: data['id'],
      title: data['title'] ?? 'Unknown Title',
      company: data['company'] ?? 'Unknown Company',
      location: data['location'],
      salary: data['salary'],
      companyLogo: data['companyLogo'],
      description: data['desc'],
      isSaved: data['isSaved'] ?? false,
      isPremium: data['premium'] ?? false,
    );
  }

  // Convert a Job instance to a Map (e.g., for saving to a database)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'company': company,
      'location': location,
      'salary': salary,
      'companyLogo': companyLogo,
      'isSaved': isSaved,
      'premium': isPremium,
    };
  }
}
