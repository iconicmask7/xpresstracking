class CheckpointModel {
  final String checkpointId;
  final String deliveryManId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String photoUrl;
  final String? notes;
  final String? taskId;

  CheckpointModel({
    required this.checkpointId,
    required this.deliveryManId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.photoUrl,
    this.notes,
    this.taskId,
  });

  factory CheckpointModel.fromMap(Map<String, dynamic> data, String documentId) {
    return CheckpointModel(
      checkpointId: documentId,
      deliveryManId: data['deliveryManId'] ?? '',
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as dynamic).toDate() 
          : DateTime.now(),
      latitude: (data['location'] != null && data['location']['latitude'] != null)
          ? (data['location']['latitude'] as num).toDouble()
          : 0.0,
      longitude: (data['location'] != null && data['location']['longitude'] != null)
          ? (data['location']['longitude'] as num).toDouble()
          : 0.0,
      photoUrl: data['photoUrl'] ?? '',
      notes: data['notes'],
      taskId: data['taskId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deliveryManId': deliveryManId,
      'timestamp': timestamp,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'photoUrl': photoUrl,
      if (notes != null) 'notes': notes,
      if (taskId != null) 'taskId': taskId,
    };
  }
}
