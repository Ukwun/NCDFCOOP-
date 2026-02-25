import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import 'app_states.dart';

/// Standard app screen wrapper with navigation, app bar, and safe area
class AppScreen extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final PreferredSizeWidget? appBar;
  final VoidCallback? onBack;
  final bool showBackButton;
  final bool showBottomNav;
  final FloatingActionButton? floatingActionButton;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final Widget? bottom;

  const AppScreen({
    required this.title,
    required this.child,
    this.actions,
    this.appBar,
    this.onBack,
    this.showBackButton = true,
    this.showBottomNav = true,
    this.floatingActionButton,
    this.backgroundColor,
    this.padding,
    this.bottom,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAppBar = appBar ??
        AppBar(
          title: Text(title),
          centerTitle: true,
          leading: showBackButton
              ? BackButton(onPressed: onBack ?? () => Navigator.pop(context))
              : null,
          actions: actions,
          bottom: bottom as PreferredSizeWidget?,
          elevation: 0,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.text,
        );

    return Scaffold(
      appBar: effectiveAppBar,
      body: SingleChildScrollView(
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor ?? AppColors.background,
    );
  }
}

/// Wrapper for screens with async data loading (uses Riverpod)
class AppAsyncScreen<T> extends ConsumerWidget {
  final String title;
  final AsyncValue<T> asyncValue;
  final Widget Function(T data) builder;
  final Widget? emptyWidget;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;
  final bool showBackButton;
  final List<Widget>? actions;
  final FloatingActionButton? floatingActionButton;

  const AppAsyncScreen({
    required this.title,
    required this.asyncValue,
    required this.builder,
    this.emptyWidget,
    this.onRetry,
    this.onBack,
    this.showBackButton = true,
    this.actions,
    this.floatingActionButton,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScreen(
      title: title,
      showBackButton: showBackButton,
      onBack: onBack,
      actions: actions,
      floatingActionButton: floatingActionButton,
      child: asyncValue.when(
        data: (data) {
          // Check if data is empty
          if (data == null || (data is List && (data).isEmpty)) {
            return emptyWidget ??
                AppEmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'No Data',
                  message: 'No items available',
                );
          }
          return builder(data);
        },
        loading: () => AppLoadingState(
          message: 'Loading $title...',
        ),
        error: (error, stack) => AppErrorState(
          title: 'Error Loading $title',
          message: error.toString(),
          onRetry: onRetry ?? () => ref.refresh(asyncValue as dynamic),
        ),
      ),
    );
  }
}

/// Tab view with consistent styling
class AppTabView extends StatefulWidget {
  final List<String> tabs;
  final List<Widget> views;
  final VoidCallback? onTabChanged;

  const AppTabView({
    required this.tabs,
    required this.views,
    this.onTabChanged,
    super.key,
  });

  @override
  State<AppTabView> createState() => _AppTabViewState();
}

class _AppTabViewState extends State<AppTabView> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.tabs.length,
      vsync: this,
    );
    _tabController.addListener(() {
      widget.onTabChanged?.call();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: widget.tabs.map((tab) => Tab(text: tab)).toList(),
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: widget.views,
          ),
        ),
      ],
    );
  }
}

/// List screen with pull-to-refresh and pagination
class AppListScreen<T> extends ConsumerWidget {
  final String title;
  final AsyncValue<List<T>> asyncValue;
  final Widget Function(T item, int index) itemBuilder;
  final VoidCallback? onRefresh;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;
  final ScrollController? scrollController;
  final bool showBackButton;

  const AppListScreen({
    required this.title,
    required this.asyncValue,
    required this.itemBuilder,
    this.onRefresh,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.scrollController,
    this.showBackButton = true,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScreen(
      title: title,
      showBackButton: showBackButton,
      child: asyncValue.when(
        data: (items) {
          if (items.isEmpty) {
            return AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'No Items',
              message: 'No items to display',
              onRetry: onRefresh,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => onRefresh?.call(),
            child: ListView.builder(
              controller: scrollController,
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Loading indicator at bottom
                if (index == items.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: AppLoadingState(
                      message: 'Loading more...',
                    ),
                  );
                }

                return itemBuilder(items[index], index);
              },
            ),
          );
        },
        loading: () => AppLoadingState(
          message: 'Loading $title...',
        ),
        error: (error, stack) => AppErrorState(
          title: 'Error Loading $title',
          message: error.toString(),
          onRetry: onRefresh ?? () {},
        ),
      ),
    );
  }
}

/// Form screen with validation
class AppFormScreen extends StatefulWidget {
  final String title;
  final List<FormFieldConfig> fields;
  final String submitLabel;
  final VoidCallback onSubmit;
  final bool isLoading;
  final bool showBackButton;

  const AppFormScreen({
    required this.title,
    required this.fields,
    required this.submitLabel,
    required this.onSubmit,
    this.isLoading = false,
    this.showBackButton = true,
    super.key,
  });

  @override
  State<AppFormScreen> createState() => _AppFormScreenState();
}

class _AppFormScreenState extends State<AppFormScreen> {
  late final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: widget.title,
      showBackButton: widget.showBackButton,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            ...widget.fields.map((field) => _buildFormField(field)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.isLoading
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        widget.onSubmit();
                      }
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.submitLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(FormFieldConfig field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: field.label,
          hintText: field.hint,
          helperText: field.helper,
          prefixIcon: field.prefixIcon != null ? Icon(field.prefixIcon) : null,
          suffixIcon: field.suffixIcon != null ? Icon(field.suffixIcon) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        validator: field.validator,
        obscureText: field.obscureText,
        keyboardType: field.keyboardType,
      ),
    );
  }
}

/// Configuration for form fields
class FormFieldConfig {
  final String label;
  final String? hint;
  final String? helper;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;

  FormFieldConfig({
    required this.label,
    this.hint,
    this.helper,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });
}

/// Expandable section widget
class AppExpandableSection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final IconData? icon;

  const AppExpandableSection({
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
    this.icon,
    super.key,
  });

  @override
  State<AppExpandableSection> createState() => _AppExpandableSectionState();
}

class _AppExpandableSectionState extends State<AppExpandableSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Row(
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: AppColors.primary),
                const SizedBox(width: 8),
              ],
              Text(
                widget.title,
                style: AppTextStyles.h3,
              ),
            ],
          ),
          trailing: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            color: AppColors.primary,
          ),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
        ),
        if (_isExpanded) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: widget.child,
          ),
        ],
      ],
    );
  }
}
