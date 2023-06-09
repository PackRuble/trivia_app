import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trivia_app/src/data/trivia/models.dart';
import 'package:trivia_app/src/domain/bloc/trivia_quiz/trivia_quiz_bloc.dart';
import 'package:trivia_app/src/ui/shared/app_bar_custom.dart';

import '../const/app_colors.dart';
import 'stats_page_ctrl.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  static const path = 'stats';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBarCustom(
        children: [
          const BackButton(),
          const SizedBox(width: 8),
          Text('Statistics', style: textTheme.headlineSmall),
        ],
      ),
      body: const CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: GeneralStatsBlock()),
          DifficultyBlockSliver(),
          CategoriesBlockSliver(),
          SliverToBoxAdapter(child: Divider(indent: 8, endIndent: 8)),
          PlayedQuizzesSliver(),
          SliverToBoxAdapter(child: SizedBox(height: 64)),
        ],
      ),
    );
  }
}

class GeneralStatsBlock extends ConsumerWidget {
  const GeneralStatsBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final pageController = ref.watch(StatsPageCtrl.instance);

    final totalCount =
        ref.watch(pageController.triviaStatsBloc.quizzesPlayed).length;
    final solvedCount = ref.watch(pageController.triviaStatsBloc.winning);
    final unsolvedCount = ref.watch(pageController.triviaStatsBloc.losing);

    return CardPad(
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Total score: ',
                style: textTheme.labelLarge,
                children: <InlineSpan>[
                  TextSpan(
                    text: '$totalCount ',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.orange[900],
                    ),
                  ),
                  TextSpan(
                    text: '[',
                    style: textTheme.titleMedium,
                  ),
                  TextSpan(
                    text: '⬇$unsolvedCount ',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.unCorrectCounterText,
                    ),
                  ),
                  TextSpan(
                    text: '⬆$solvedCount',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.correctCounterText,
                    ),
                  ),
                  TextSpan(
                    text: ']',
                    style: textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          FilledButton.tonal(
            onPressed: () {},
            child: const Text('Reset stats'),
          ),
        ],
      ),
    );
  }
}

class DifficultyBlockSliver extends ConsumerWidget {
  const DifficultyBlockSliver({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    final statsBloc = ref.watch(TriviaStatsBloc.instance);
    final Map<TriviaQuizDifficulty, (int correctly, int uncorrectly)>
        statsOnDifficulty = ref.watch(statsBloc.statsOnDifficulty);

    return SliverToBoxAdapter(
      child: CardPad(
        child: Column(
          children: [
            for (final entry in statsOnDifficulty.entries)
              Row(
                children: [
                  Expanded(child: Text(entry.key.name)),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '⬇${entry.value.$2}',
                      style: textTheme.labelLarge?.copyWith(
                        color: Colors.red.shade900,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '⬆${entry.value.$1}',
                      textAlign: TextAlign.right,
                      style: textTheme.labelLarge?.copyWith(
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }
}

class CategoriesBlockSliver extends ConsumerWidget {
  const CategoriesBlockSliver({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    final statsBloc = ref.watch(TriviaStatsBloc.instance);
    final Map<String, (int correctly, int uncorrectly)> statsOnCategory =
        ref.watch(statsBloc.statsOnCategory);

    return SliverToBoxAdapter(
      child: CardPad(
        child: Column(
          children: [
            for (final entry in statsOnCategory.entries)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(entry.key)),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '⬇${entry.value.$2}',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.unCorrectCounterText,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '⬆${entry.value.$1}',
                      textAlign: TextAlign.right,
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.correctCounterText,
                      ),
                    ),
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }
}

class CardPad extends StatelessWidget {
  const CardPad({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: child,
      ),
    );
  }
}

class PlayedQuizzesSliver extends ConsumerWidget {
  const PlayedQuizzesSliver({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final statsBloc = ref.watch(TriviaStatsBloc.instance);
    final quizzesPlayed = ref.watch(statsBloc.quizzesPlayed);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: quizzesPlayed.length,
        (context, index) {
          final quiz = quizzesPlayed[index];

          return CardPad(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.question,
                  style: textTheme.labelLarge,
                ),
                ...[
                  for (var answer in quiz.answers)
                    Text(
                      '→ $answer',
                      style: switch (quiz.correctlySolved) {
                        true when answer == quiz.yourAnswer =>
                          TextStyle(backgroundColor: AppColors.correctAnswer),
                        false when answer == quiz.yourAnswer =>
                          TextStyle(backgroundColor: AppColors.correctAnswer),
                        false when answer == quiz.correctAnswer =>
                          TextStyle(backgroundColor: AppColors.myAnswer),
                        _ => null
                      },
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
