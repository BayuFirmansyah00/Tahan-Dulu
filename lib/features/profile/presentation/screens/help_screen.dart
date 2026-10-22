import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_states.dart';
import '../../data/help_articles.dart';
import '../providers/profile_providers.dart';

/// Bantuan & Dukungan: ilustrasi, pencarian lokal, FAQ expandable.
class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  final Set<String> _expanded = {};
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (!_expanded.remove(id)) _expanded.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final query = ref.watch(helpQueryProvider);
    final articles = ref.watch(filteredHelpArticlesProvider);
    final reduceMotion = ref.watch(appPreferencesProvider).reduceMotion;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.helpTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Image.asset(
                            AppAssets.incomeSetupIllustration,
                            height: 148,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.support_agent_outlined,
                              size: 96,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.helpHeadline,
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.helpSubtitle,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: AppStrings.helpSearchHint,
                            prefixIcon: Icon(Icons.search_outlined),
                          ),
                          onChanged: (v) => ref
                              .read(helpQueryProvider.notifier)
                              .setQuery(v),
                        ),
                        const SizedBox(height: 16),
                        if (query.trim().isEmpty)
                          Text(
                            AppStrings.helpCategoryTitle,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (query.trim().isEmpty) ...[
                  for (final category in helpCategories) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 12, 20, 6),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8EFFE),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                category.icon,
                                color: AppColors.secondary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                category.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final items = articles
                              .where((a) =>
                                  a.categoryId == category.id)
                              .toList();
                          if (index >= items.length) return null;
                          final article = items[index];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(
                              20,
                              0,
                              20,
                              8,
                            ),
                            child: _ArticleTile(
                              article: article,
                              expanded:
                                  _expanded.contains(article.id),
                              reduceMotion: reduceMotion,
                              onTap: () => _toggle(article.id),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ] else ...[
                  if (articles.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: const AppEmptyState(
                        title: AppStrings.helpEmptyTitle,
                        subtitle: AppStrings.helpEmptySubtitle,
                        icon: Icons.search_off_outlined,
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= articles.length) return null;
                          final article = articles[index];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(
                              20,
                              0,
                              20,
                              8,
                            ),
                            child: _ArticleTile(
                              article: article,
                              expanded:
                                  _expanded.contains(article.id),
                              reduceMotion: reduceMotion,
                              onTap: () => _toggle(article.id),
                            ),
                          );
                        },
                      ),
                    ),
                ],
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            AppStrings.helpStillNeed,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.helpStillNeedDesc,
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () =>
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  AppStrings.helpContactSoon,
                                ),
                              ),
                            ),
                            child: const Text(
                              AppStrings.helpContactAction,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArticleTile extends StatelessWidget {
  const _ArticleTile({
    required this.article,
    required this.expanded,
    required this.reduceMotion,
    required this.onTap,
  });

  final HelpArticle article;
  final bool expanded;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      article.question,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: Duration(
                      milliseconds: reduceMotion ? 0 : 200,
                    ),
                    child: const Icon(
                      Icons.expand_more_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              AnimatedOpacity(
                opacity: expanded ? 1 : 0,
                duration: Duration(
                  milliseconds: reduceMotion ? 0 : 200,
                ),
                child: Visibility(
                  visible: expanded,
                  maintainState: true,
                  maintainAnimation: true,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      article.answer,
                      style: textTheme.bodyMedium
                          ?.copyWith(fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
