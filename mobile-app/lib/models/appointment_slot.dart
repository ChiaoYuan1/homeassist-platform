class AppointmentSlot {
  final DateTime start;
  final DateTime end;
  final String technicianId;
  final String technicianName;
  const AppointmentSlot({required this.start, required this.end, required this.technicianId, required this.technicianName});
  int get durationMinutes => end.difference(start).inMinutes;
}
