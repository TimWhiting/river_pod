part of '../change_notifier_provider.dart';

typedef ChangeNotifierProviderRef<Notifier> = ProviderRefBase;

/// {@macro riverpod.changenotifierprovider}
@sealed
class ChangeNotifierProvider<Notifier extends ChangeNotifier>
    extends AlwaysAliveProviderBase<Notifier>
    implements ProviderOverridesMixin<Notifier> {
  /// {@macro riverpod.changenotifierprovider}
  ChangeNotifierProvider(this._create, {String? name}) : super(name);

  /// {@macro riverpod.family}
  static const family = ChangeNotifierProviderFamilyBuilder();

  /// {@macro riverpod.autoDispose}
  static const autoDispose = AutoDisposeChangeNotifierProviderBuilder();

  final Create<Notifier, ProviderRefBase> _create;

  /// {@template flutter_riverpod.changenotifierprovider.notifier}
  /// Obtains the [ChangeNotifier] associated with this provider, but without
  /// listening to it.
  ///
  /// Listening to this provider may cause providers/widgets to rebuild in the
  /// event that the [ChangeNotifier] it recreated.
  ///
  ///
  /// It is preferrable to do:
  /// ```dart
  /// ref.watch(changeNotifierProvider.notifier)
  /// ```
  ///
  /// instead of:
  /// ```dart
  /// ref.read(changeNotifierProvider)
  /// ```
  ///
  /// The reasoning is, using `read` could cause hard to catch bugs, such as
  /// not rebuilding dependent providers/widgets after using `context.refresh` on this provider.
  /// {@endtemplate}
  late final AlwaysAliveProviderBase<Notifier> notifier = Provider((ref) {
    final notifier = _create(ref);
    ref.onDispose(notifier.dispose);

    return notifier;
  });

  @override
  Notifier create(ProviderElementBase<Notifier> ref) {
    final notifier = ref.watch<Notifier>(this.notifier);
    _listenNotifier(notifier, ref);
    return notifier;
  }

  @override
  Override overrideWithValue(Notifier value) {
    return ProviderOverride(
      ValueProvider<Notifier>((_) => value, value),
      notifier,
    );
  }

  @override
  Override overrideWithProvider(
    AlwaysAliveProviderBase<Notifier> provider,
  ) {
    return ProviderOverride(provider, notifier);
  }

  @override
  ProviderElement<Notifier> createElement() => ProviderElement(this);

  @override
  bool recreateShouldNotify(Notifier previousState, Notifier newState) => true;
}

/// {@template riverpod.changenotifierprovider.family}
/// A class that allows building a [ChangeNotifierProvider] from an external parameter.
/// {@endtemplate}
@sealed
class ChangeNotifierProviderFamily<Notifier extends ChangeNotifier, Arg>
    extends Family<Notifier, Arg, ChangeNotifierProvider<Notifier>> {
  /// {@macro riverpod.changenotifierprovider.family}
  ChangeNotifierProviderFamily(this._create, {String? name}) : super(name);

  final FamilyCreate<Notifier, ChangeNotifierProviderRef<Notifier>, Arg>
      _create;

  @override
  ChangeNotifierProvider<Notifier> create(Arg argument) {
    return ChangeNotifierProvider((ref) => _create(ref, argument), name: name);
  }
}

/// An extension that adds [overrideWithProvider] to [Family].
extension XChangeNotifierFamily<Notifier extends ChangeNotifier, Arg,
        FamilyProvider extends AlwaysAliveProviderBase<Notifier>>
    on Family<Notifier, Arg, FamilyProvider> {
  /// Overrides the behavior of a family for a part of the application.
  ///
  /// {@macro riverpod.overideWith}
  Override overrideWithProvider(
    AlwaysAliveProviderBase<Notifier> Function(Arg argument) override,
  ) {
    return FamilyOverride(
      this,
      (arg, provider) {
        if (provider is! ChangeNotifierProvider<Notifier>) {
          // .notifier isn't ChangeNotifierProvider
          return override(arg as Arg);
        }
        return provider;
      },
    );
  }
}
