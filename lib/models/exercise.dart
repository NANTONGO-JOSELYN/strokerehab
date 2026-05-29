class Exercise {
  final String id;
  final String name;
  final String description;
  final String targetArea; // e.g., "Shoulder", "Elbow", "Wrist"
  final int durationSeconds;
  final String difficulty; // "Easy", "Medium", "Hard"
  final String instructions;
  final int setsRecommended;
  final int repsPerSet;
  final String imageAsset;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.targetArea,
    required this.durationSeconds,
    required this.difficulty,
    required this.instructions,
    required this.setsRecommended,
    required this.repsPerSet,
    required this.imageAsset,
  });

  // Mock data for 5 exercises
  static List<Exercise> getMockExercises() {
    return [
      Exercise(
        id: 'ex_1',
        name: 'Shoulder Flexion',
        description: 'Raise your arm forward and up',
        targetArea: 'Shoulder',
        durationSeconds: 30,
        difficulty: 'Easy',
        instructions:
            '1. Stand with feet shoulder-width apart\n2. Slowly raise your arm forward\n3. Hold at the top for 2 seconds\n4. Lower slowly back down',
        setsRecommended: 3,
        repsPerSet: 10,
        imageAsset: 'assets/exercises/shoulder_flexion.png',
      ),
      Exercise(
        id: 'ex_2',
        name: 'Elbow Flexion',
        description: 'Bend and straighten your elbow',
        targetArea: 'Elbow',
        durationSeconds: 30,
        difficulty: 'Easy',
        instructions:
            '1. Keep your upper arm still\n2. Bend your elbow bringing hand toward shoulder\n3. Hold for 1 second\n4. Straighten slowly',
        setsRecommended: 3,
        repsPerSet: 12,
        imageAsset: 'assets/exercises/elbow_flexion.png',
      ),
      Exercise(
        id: 'ex_3',
        name: 'Wrist Rotation',
        description: 'Rotate your wrist in circles',
        targetArea: 'Wrist',
        durationSeconds: 45,
        difficulty: 'Medium',
        instructions:
            '1. Extend your arm in front of you\n2. Make slow circular motions with your wrist\n3. Rotate 10 times clockwise\n4. Rotate 10 times counter-clockwise',
        setsRecommended: 2,
        repsPerSet: 10,
        imageAsset: 'assets/exercises/wrist_rotation.png',
      ),
      Exercise(
        id: 'ex_4',
        name: 'Grip Strengthening',
        description: 'Squeeze and release exercise',
        targetArea: 'Hand',
        durationSeconds: 60,
        difficulty: 'Medium',
        instructions:
            '1. Hold a soft ball or therapy putty\n2. Squeeze gently for 3 seconds\n3. Release slowly\n4. Rest for 2 seconds and repeat',
        setsRecommended: 3,
        repsPerSet: 15,
        imageAsset: 'assets/exercises/grip_strength.png',
      ),
      Exercise(
        id: 'ex_5',
        name: 'Standing Balance',
        description: 'Improve standing stability',
        targetArea: 'Full Body',
        durationSeconds: 60,
        difficulty: 'Hard',
        instructions:
            '1. Stand near a wall or sturdy support\n2. Maintain balance with feet shoulder-width apart\n3. Keep eyes open and focused\n4. Hold position for 30-60 seconds',
        setsRecommended: 2,
        repsPerSet: 1,
        imageAsset: 'assets/exercises/standing_balance.png',
      ),
    ];
  }
}
