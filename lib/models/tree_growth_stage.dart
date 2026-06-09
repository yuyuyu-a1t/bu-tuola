import 'package:hive/hive.dart';

@HiveType(typeId: 5)
enum TreeGrowthStage {
  @HiveField(0)
  seed,

  @HiveField(1)
  sprout,

  @HiveField(2)
  sapling,

  @HiveField(3)
  growingTree,

  @HiveField(4)
  flourishingTree,
}

TreeGrowthStage treeGrowthStageFromEnergy(int energy) {
  if (energy < 30) {
    return TreeGrowthStage.seed;
  }
  if (energy < 80) {
    return TreeGrowthStage.sprout;
  }
  if (energy < 150) {
    return TreeGrowthStage.sapling;
  }
  if (energy < 250) {
    return TreeGrowthStage.growingTree;
  }

  return TreeGrowthStage.flourishingTree;
}

extension TreeGrowthStageInfo on TreeGrowthStage {
  int get minEnergy {
    return switch (this) {
      TreeGrowthStage.seed => 0,
      TreeGrowthStage.sprout => 30,
      TreeGrowthStage.sapling => 80,
      TreeGrowthStage.growingTree => 150,
      TreeGrowthStage.flourishingTree => 250,
    };
  }

  int? get maxEnergy {
    return switch (this) {
      TreeGrowthStage.seed => 30,
      TreeGrowthStage.sprout => 80,
      TreeGrowthStage.sapling => 150,
      TreeGrowthStage.growingTree => 250,
      TreeGrowthStage.flourishingTree => null,
    };
  }

  int? get nextStageEnergy {
    return switch (this) {
      TreeGrowthStage.seed => TreeGrowthStage.sprout.minEnergy,
      TreeGrowthStage.sprout => TreeGrowthStage.sapling.minEnergy,
      TreeGrowthStage.sapling => TreeGrowthStage.growingTree.minEnergy,
      TreeGrowthStage.growingTree => TreeGrowthStage.flourishingTree.minEnergy,
      TreeGrowthStage.flourishingTree => null,
    };
  }

  String get displayName {
    return switch (this) {
      TreeGrowthStage.seed => '种子',
      TreeGrowthStage.sprout => '小芽',
      TreeGrowthStage.sapling => '小树苗',
      TreeGrowthStage.growingTree => '成长中的树',
      TreeGrowthStage.flourishingTree => '茂盛大树',
    };
  }

  String get emoji {
    return switch (this) {
      TreeGrowthStage.seed => '🌰',
      TreeGrowthStage.sprout => '🌱',
      TreeGrowthStage.sapling => '🌿',
      TreeGrowthStage.growingTree => '🌳',
      TreeGrowthStage.flourishingTree => '🌲',
    };
  }

  String get moodText {
    return switch (this) {
      TreeGrowthStage.seed => '把小小开始埋进今天。',
      TreeGrowthStage.sprout => '冒出一点绿，也很了不起。',
      TreeGrowthStage.sapling => '小树苗正在认真长高。',
      TreeGrowthStage.growingTree => '枝叶展开，学习力上线。',
      TreeGrowthStage.flourishingTree => '已经是一棵很稳的校园大树啦。',
    };
  }

  double progressForEnergy(int energy) {
    final max = maxEnergy;
    if (max == null) {
      return 1;
    }

    final rawProgress = energy / max;
    return rawProgress.clamp(0, 1).toDouble();
  }

  String encouragementForEnergy(int energy) {
    final nextEnergy = nextStageEnergy;
    if (nextEnergy == null) {
      return '你的小树已经长成最终形态，继续给它攒阳光吧。';
    }

    final remainingEnergy = nextEnergy - energy;
    final safeRemainingEnergy = remainingEnergy < 0 ? 0 : remainingEnergy;
    final nextStage = treeGrowthStageFromEnergy(nextEnergy);
    return '距离长成${nextStage.displayName}还需 $safeRemainingEnergy 点能量';
  }

  String progressTextForEnergy(int energy) {
    final max = maxEnergy;
    if (max == null) {
      return '$energy 点能量 · 已抵达最高阶段';
    }

    return '$energy / $max 能量';
  }
}
