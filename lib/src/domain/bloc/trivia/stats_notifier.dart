import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/data/local_storage/game_storage.dart';
import 'package:trivia_app/src/data/trivia/model_dto/trivia_config_models.dart';

import 'quizzes/model/quiz.model.dart';

class TriviaStatsProvider extends QuizStatsNotifier {
  TriviaStatsProvider({required super.storage});

  static final instance = AutoDisposeProvider<TriviaStatsProvider>((ref) {
    return TriviaStatsProvider(
      storage: ref.watch(GameStorage.instance),
    );
  });

  late final statsOnDifficulty = AutoDisposeProvider<
      Map<TriviaQuizDifficulty, (int correctly, int uncorrectly)>>(
    (ref) => _calculateStatsOnDifficulty(ref.watch(quizzesPlayed)),
  );

  late final statsOnCategory =
      AutoDisposeProvider<Map<_CategoryName, (int correctly, int uncorrectly)>>(
    (ref) => _calculateStatsOnCategory(ref.watch(quizzesPlayed)),
  );

  late final quizzesPlayed = AutoDisposeProvider<List<Quiz>>((ref) {
    return _storage.attach(
      GameCard.quizzesPlayed,
      (value) => ref.state = value,
      detacher: ref.onDispose,
      onRemove: () => ref.state = [],
    );
  });

  late final winning = AutoDisposeProvider<int>((ref) {
    return _storage.attach(
      GameCard.winning,
      (value) => ref.state = value,
      detacher: ref.onDispose,
      onRemove: () => ref.state = 0,
    );
  });

  late final losing = AutoDisposeProvider<int>((ref) {
    return _storage.attach(
      GameCard.losing,
      (value) => ref.state = value,
      detacher: ref.onDispose,
      onRemove: () => ref.state = 0,
    );
  });
}

typedef _CategoryName = String;

class QuizStatsNotifier {
  QuizStatsNotifier({
    required GameStorage storage,
  }) : _storage = storage;

  final GameStorage _storage;

  // ***************************************************************************
  // counting quizzes played by their difficulty

  Map<TriviaQuizDifficulty, (int correctly, int uncorrectly)>
      _calculateStatsOnDifficulty(
    List<Quiz> quizzes,
  ) {
    final result = <TriviaQuizDifficulty, (int correctly, int uncorrectly)>{};

    for (final q in quizzes) {
      var (int correctly, int uncorrectly) = result[q.difficulty] ?? (0, 0);

      if (q.correctlySolved!) {
        result[q.difficulty] = (++correctly, uncorrectly);
      } else {
        result[q.difficulty] = (correctly, ++uncorrectly);
      }
    }

    return result;
  }

  // ***************************************************************************
  // counting quizzes played by their category

  Map<_CategoryName, (int correctly, int uncorrectly)>
      _calculateStatsOnCategory(
    List<Quiz> quizzes,
  ) {
    final result = <_CategoryName, (int correctly, int uncorrectly)>{};

    for (final q in quizzes) {
      var (int correctly, int uncorrectly) = result[q.category] ?? (0, 0);

      if (q.correctlySolved!) {
        result[q.category] = (++correctly, uncorrectly);
      } else {
        result[q.category] = (correctly, ++uncorrectly);
      }
    }

    return result;
  }

  /// Use only in the scope `domain`.
  Future<void> savePoints(bool isWin) async {
    isWin
        ? await _storage.set<int>(
            GameCard.winning,
            _storage.get(GameCard.winning) + 1,
          )
        : await _storage.set<int>(
            GameCard.losing,
            _storage.get(GameCard.losing) + 1,
          );
  }

  Future<void> resetStats() async {
    await _storage.remove(GameCard.winning);
    await _storage.remove(GameCard.losing);
    await _storage.remove(GameCard.quizzesPlayed);
  }
}