import 'dart:async';
import 'dart:collection' show Queue;
import 'dart:core';
import 'dart:developer' show log;
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'
    show AutoDisposeNotifier, AutoDisposeNotifierProvider;
import 'package:http/http.dart' as http;
import 'package:trivia_app/extension/bidirectional_iterator.dart';
import 'package:trivia_app/extension/binary_reduction.dart';
import 'package:trivia_app/internal/debug_flags.dart';
import 'package:trivia_app/src/data/trivia/model_dto/quiz/quiz.dto.dart';
import 'package:trivia_app/src/data/trivia/trivia_repository.dart';
import 'package:trivia_app/src/domain/bloc/trivia/quiz_game/quiz_game_result.dart';
import 'package:trivia_app/src/domain/bloc/trivia/token_notifier.dart';

import '../cached_quizzes/cached_quizzes_notifier.dart';
import '../model/quiz.model.dart';
import '../quiz_config/quiz_config_model.dart';
import '../quiz_config/quiz_config_notifier.dart';
import '../stats/trivia_stats_bloc.dart';
typedef TriviaResultAsyncCallback = Future<TriviaResult> Function();

class _QuizRequest {
  const _QuizRequest({
    required this.execution,
    required this.quizConfig,
    this.onlyCache = false,
    this.clearIfSuccess = false,
  });
  final TriviaResultAsyncCallback execution;
  final bool onlyCache;
  final bool clearIfSuccess;
  final QuizConfig quizConfig;

  _QuizRequest copyWith({
    TriviaResultAsyncCallback? execution,
    bool? onlyCache,
    bool? clearIfSuccess,
    QuizConfig? quizConfig,
  }) {
    return _QuizRequest(
      execution: execution ?? this.execution,
      onlyCache: onlyCache ?? this.onlyCache,
      clearIfSuccess: clearIfSuccess ?? this.clearIfSuccess,
      quizConfig: quizConfig ?? this.quizConfig,
    );
  }
}

/// Notifier is a certain state machine for the game process and methods
/// for managing this state.
class QuizGameNotifier extends AutoDisposeNotifier<QuizGameResult> {
  static final instance =
      AutoDisposeNotifierProvider<QuizGameNotifier, QuizGameResult>(
    QuizGameNotifier.new,
  );

  late QuizStatsNotifier _quizStatsNotifier;
  late QuizzesNotifier _quizzesNotifier;
  late TriviaRepository _triviaRepository;
  late QuizConfigNotifier _quizConfigNotifier;
  late TokenNotifier _tokenNotifier;

  // internal state
  Iterator<Quiz>? _cachedQuizzesIterator;
  final _executionRequestQueue = Queue<_QuizRequest>();
  bool _queueAtWork = false;

  @override
  QuizGameResult build() {
    _quizStatsNotifier = ref.watch(TriviaStatsProvider.instance);
    _quizzesNotifier = ref.watch(QuizzesNotifier.instance.notifier);
    _tokenNotifier = ref.watch(TokenNotifier.instance.notifier);
    _triviaRepository = TriviaRepository(
      client: http.Client(),
      useMockData: DebugFlags.triviaRepoUseMock,
    );
    _quizConfigNotifier = ref.watch(QuizConfigNotifier.instance.notifier);
    _quizConfigNotifier = ref.watch(QuizConfigNotifier.instance.notifier);

    ref.onDispose(() {
      _executionRequestQueue.clear();
    });

    // this allows you to run method immediately after this build has finished running
    Future.microtask(nextQuiz);

    return const QuizGameResult.loading();
  }

  /// This is a list of numbers, each of which represents the number of quizzes
  /// we would like to receive from the server.
  ///
  /// for 50: [25, 13, 7, 4, 2, 1]
  /// for 16: [ 8,  4, 2, 1]
  ListBiIterator<int> getReductionNumbers() =>
      ListBiIterator(getReductionsSequence(_maxAmountQuizzesPerRequest));

  /// Maximum number of quizzes per request.
  ///
  /// If the category is popular, we will make 6 requests,
  /// otherwise we will make only 4.
  int get _maxAmountQuizzesPerRequest =>
      _quizConfigNotifier.state.quizCategory.isAny ? 50 : 16;

  QuizConfig get _getQuizConfig => _quizConfigNotifier.state;

  /// Request for the next quiz. The state will be updated reactively.
  Future<void> nextQuiz() async {
    log('$this.nextQuiz-> Request for the next quiz');

    state = const QuizGameResult.loading();

    bool needSilentRequest = false;
    // looking for a quiz that matches the filters
    final cachedQuiz = _getCachedQuiz();
    if (cachedQuiz != null) {
      state = QuizGameData(cachedQuiz);
    } else {
      log('$this-> Cached quizzes were not found, add request to queue first, amount=1');
      needSilentRequest = true;

      final quizConfig = _getQuizConfig;
      final isPopularConfig = _quizConfigNotifier.isPopularConfig(quizConfig);
      _executionRequestQueue.addFirst(
        _QuizRequest(
          quizConfig: _getQuizConfig,
          execution: () async {
            // We don't need to think about it, since the queue handler will
            // re-create the request with a delay if an `TriviaException.rateLimit` occur.
            // Amount is 1 because we are guaranteed to want the quiz right now
            // subsequent calls will be delayed :(
            return await _fetchQuiz(
              amountQuizzes: isPopularConfig
                  ? _maxAmountQuizzesPerRequest
                  : 1,
              quizConfig: quizConfig,
              // todo(15.02.2024): In the future, this can be abandoned if you
              //  separate the request queue management into a separate class
              delay: Duration.zero,
            );
          },
          clearIfSuccess: isPopularConfig,
        ),
      );
    }

    // silently increase number of quizzes if their cached number is below allowed level
    if (!_isEnoughCachedQuizzes || needSilentRequest) {
      log('$this-> not enough cached quizzes');
      _fillQueueSilent();
    }

    if (_queueAtWork) {
      // requests will still be executed in previous `nextQuiz` call
      return;
    } else {
      _queueAtWork = true;
      while (_executionRequestQueue.isNotEmpty) {
        final currentRequest = _executionRequestQueue.removeFirst();

        await _updateStateWithResult(currentRequest);
      }
      _queueAtWork = false;
    }
  }

  Future<void> _updateStateWithResult(_QuizRequest request) async {
    final triviaResult = await request.execution.call();

    QuizGameResult? newState;
    if (triviaResult case TriviaData<List<QuizDTO>>(:final data)) {
      final quizzes = Quiz.quizzesFromDTO(data);
      log('$this-> result with data, l=${_quizzesNotifier.state.length}');
      await _quizzesNotifier.cacheQuizzes(quizzes);

      _cachedQuizzesIterator = null;
      // after this, the `QuizzesNotifier` state already contains current data
      final cachedQuiz = _getCachedQuiz();
      if (cachedQuiz != null) {
        newState = QuizGameData(cachedQuiz);
      }
      if (request.clearIfSuccess) _clearQueueByConfig(request);
    } else if (triviaResult case TriviaExceptionApi(exception: final exc)) {
      log('$this-> result is $exc');
      if (exc case TriviaException.rateLimit) {
        // we are sure that added query will be executed because `_updateStateWithResult` method
        // is always executed in a `while (_executionRequestQueue.isNotEmpty)` loop.
        _executionRequestQueue.addFirst(
          request.copyWith(
            execution: () async {
              await Future.delayed(const Duration(seconds: 5));
              return request.execution();
            },
          ),
        );
        // todo(15.02.2024): Another solution to the problem is to use threads
        //  that can listen and perform actions as long as there are elements in the queue
        //  - maybe `StreamQueue` ?..
      } else if (exc case TriviaException.tokenEmptySession) {
        _clearQueueByConfig(request);
        // todo: suggest resetting the session
        newState = const QuizGameResult.emptyData();
      } else if (exc case TriviaException.invalidParameter) {
        newState = QuizGameResult.error(exc.message);
      }
    } else if (triviaResult case TriviaError(:final error)) {
      log('$this-> result error: $error');
      newState = QuizGameResult.error(error.toString());
    }

    if (!request.onlyCache || state is QuizGameLoading) {
      if (newState != null) state = newState;
    }
  }

  resetSessionToken() {
    // todo(16.02.2024): implement
  }

  /// Removes requests from the queue if they have the same config as the current request.
  void _clearQueueByConfig(_QuizRequest request) {
    _executionRequestQueue
        .removeWhere((el) => el.quizConfig == request.quizConfig);
  }

  /// The function fills the queue with requests [TriviaRepository.getQuizzes].
  /// These requests will be completed later.
  ///
  /// Feature: the first request is always for the maximum number of quizzes,
  /// and then each subsequent request with a binary reduction of the requested
  /// number.
  void _fillQueueSilent() {
    final quizConfig = _getQuizConfig;

    _executionRequestQueue.add(
      _QuizRequest(
        execution: () async {
          log('$this-> Request for maximum amount=$_maxAmountQuizzesPerRequest');
          return await _fetchQuiz(
            amountQuizzes: _maxAmountQuizzesPerRequest,
            quizConfig: quizConfig,
          );
        },
        quizConfig: quizConfig,
        onlyCache: true,
        // clear the queue with this config if the request was successful
        clearIfSuccess: true,
      ),
    );

    // we fill the queue with binary reduction queries only to retrieve data if
    // the first query fails. If the request is successful, the queue will be
    // cleared (this is what the [_QuizRequest.clearIfSuccess] flag is for)
    final numbersReductionIterator = getReductionNumbers();
    while (numbersReductionIterator.moveNext()) {
      final amount = numbersReductionIterator.current;

      _executionRequestQueue.add(
        _QuizRequest(
          execution: () async {
            log('$this-> Request for amount=$amount');
            return await _fetchQuiz(
              amountQuizzes: amount,
              quizConfig: quizConfig,
            );
          },
          quizConfig: quizConfig,
          onlyCache: true,
        ),
      );
    }
  }

  /// Get quizzes from the Trivia server. Use delay if necessary.
  ///
  /// Pure method.
  Future<TriviaResult> _fetchQuiz({
    required int amountQuizzes,
    required QuizConfig quizConfig,
    // Update: At some point in the Trivia backend there is a limit on the number
    // of requests per second from one IP. To get around this, we will wait an
    // additional 5 seconds when this error occurs.
    //
    // therefore we wait 5 seconds as the backend dictates. Then we do a request.
    Duration delay = const Duration(seconds: 5),
  }) async {
    log('$this._fetchQuiz-> with $quizConfig, amount=$amountQuizzes, delay=${delay.inSeconds}sec');

    await Future.delayed(delay);
    final result = await _triviaRepository.getQuizzes(
      category: quizConfig.quizCategory,
      difficulty: quizConfig.quizDifficulty,
      type: quizConfig.quizType,
      amount: amountQuizzes,
      token: await _getToken(),
    );

    if (result case TriviaData()) await _tokenNotifier.extendValidityOfToken();

    return result;
  }

  Future<String?> _getToken() async {
    String? token;
    switch (_tokenNotifier.state) {
      case TokenActive(token: final triviaToken):
        token = triviaToken.token;
      case TokenExpired():
      case TokenEmptySession():
      // todo: сказать пользователю о том, что его токен теперь не валиден
      // пусть обновит (с удалением статистики)
        log('TokenExpired or TokenEmptySession');
      case TokenNone():
        final triviaToken = await _tokenNotifier.fetchNewToken();
        if (triviaToken == null) {
          continue errorLabel;
        } else {
          token = triviaToken.token;
        }
      errorLabel:
      case TokenError(:final message):
      // todo: произошла ошибка. Предложить повторить запрос
        log('TokenError');
    }
    return token;
  }

  /// Limited so as to make the least number of requests to the server,
  /// if the number of available quizzes on the selected parameters is minimal.
  static const _minCountCachedQuizzes = 10;

  bool get _isEnoughCachedQuizzes =>
      _quizzesNotifier.state.length > _minCountCachedQuizzes;

  Iterator<Quiz> get _getNewCachedQuizzesIterator {
    final quizzes = List.of(_quizzesNotifier.state)..shuffle();
    return quizzes.iterator;
  }

  Quiz? _getCachedQuiz() {
    log('$this-> $_quizzesNotifier state: l=${_quizzesNotifier.state.length}');

    _cachedQuizzesIterator ??= _getNewCachedQuizzesIterator;
    while (_cachedQuizzesIterator!.moveNext()) {
      final quiz = _cachedQuizzesIterator!.current;

      if (_quizConfigNotifier.matchQuizByFilter(quiz)) {
        log('$this-> Quiz found in cache, hash:${quiz.hashCode}');
        return quiz;
      }
    }

    return null;
  }

  Future<void> checkMyAnswer(String answer) async {
    if (state is! QuizGameData) return;

    var quiz = (state as QuizGameData).quiz;
    quiz = quiz.copyWith(yourAnswer: answer);

    unawaited(_quizStatsNotifier.savePoints(quiz.correctlySolved!));
    unawaited(_quizzesNotifier.moveQuizAsPlayed(quiz));
    state = QuizGameResult.data(quiz);
  }

  @override
  @protected
  String toString() =>
      super.toString().replaceFirst('Instance of ', '').replaceAll("'", '');
}
