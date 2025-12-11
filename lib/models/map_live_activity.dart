class MapLiveActivity {
  final String remainingDistanceStr;
  final int progress;
  final int minutesToArrive;

  MapLiveActivity({ 
    required this.remainingDistanceStr,
    required this.progress,
    required this.minutesToArrive,
  });

  Map<String, dynamic> toJson() => {
    'remainingDistanceStr': remainingDistanceStr,
    'progress': progress,
    'minutesToArrive': minutesToArrive,
  };
}
