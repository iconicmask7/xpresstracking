// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userCheckpointsHash() => r'bca6f772228db6255bf519228c6f0f91474b3d3c';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [userCheckpoints].
@ProviderFor(userCheckpoints)
const userCheckpointsProvider = UserCheckpointsFamily();

/// See also [userCheckpoints].
class UserCheckpointsFamily extends Family<AsyncValue<List<CheckpointModel>>> {
  /// See also [userCheckpoints].
  const UserCheckpointsFamily();

  /// See also [userCheckpoints].
  UserCheckpointsProvider call(
    String deliveryManId,
  ) {
    return UserCheckpointsProvider(
      deliveryManId,
    );
  }

  @override
  UserCheckpointsProvider getProviderOverride(
    covariant UserCheckpointsProvider provider,
  ) {
    return call(
      provider.deliveryManId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userCheckpointsProvider';
}

/// See also [userCheckpoints].
class UserCheckpointsProvider
    extends AutoDisposeStreamProvider<List<CheckpointModel>> {
  /// See also [userCheckpoints].
  UserCheckpointsProvider(
    String deliveryManId,
  ) : this._internal(
          (ref) => userCheckpoints(
            ref as UserCheckpointsRef,
            deliveryManId,
          ),
          from: userCheckpointsProvider,
          name: r'userCheckpointsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userCheckpointsHash,
          dependencies: UserCheckpointsFamily._dependencies,
          allTransitiveDependencies:
              UserCheckpointsFamily._allTransitiveDependencies,
          deliveryManId: deliveryManId,
        );

  UserCheckpointsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.deliveryManId,
  }) : super.internal();

  final String deliveryManId;

  @override
  Override overrideWith(
    Stream<List<CheckpointModel>> Function(UserCheckpointsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserCheckpointsProvider._internal(
        (ref) => create(ref as UserCheckpointsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        deliveryManId: deliveryManId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<CheckpointModel>> createElement() {
    return _UserCheckpointsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserCheckpointsProvider &&
        other.deliveryManId == deliveryManId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, deliveryManId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UserCheckpointsRef
    on AutoDisposeStreamProviderRef<List<CheckpointModel>> {
  /// The parameter `deliveryManId` of this provider.
  String get deliveryManId;
}

class _UserCheckpointsProviderElement
    extends AutoDisposeStreamProviderElement<List<CheckpointModel>>
    with UserCheckpointsRef {
  _UserCheckpointsProviderElement(super.provider);

  @override
  String get deliveryManId => (origin as UserCheckpointsProvider).deliveryManId;
}

String _$adminViewModelHash() => r'f125efe9aa1561762b658880ea29a3dd7f6611e9';

/// See also [AdminViewModel].
@ProviderFor(AdminViewModel)
final adminViewModelProvider =
    AutoDisposeStreamNotifierProvider<AdminViewModel, List<UserModel>>.internal(
  AdminViewModel.new,
  name: r'adminViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adminViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AdminViewModel = AutoDisposeStreamNotifier<List<UserModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
