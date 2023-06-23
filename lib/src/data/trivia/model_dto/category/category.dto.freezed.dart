// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category.dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

CategoryDTO _$CategoryDTOFromJson(Map<String, dynamic> json) {
  return _CategoryDTO.fromJson(json);
}

/// @nodoc
mixin _$CategoryDTO {
  /// The id of category.
  @JsonKey(name: 'id')
  int get id => throw _privateConstructorUsedError;

  /// The name of category
  /// For example: Film, Music, Books, etc...
  @JsonKey(name: 'name')
  String get name => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CategoryDTOCopyWith<CategoryDTO> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CategoryDTOCopyWith<$Res> {
  factory $CategoryDTOCopyWith(
          CategoryDTO value, $Res Function(CategoryDTO) then) =
      _$CategoryDTOCopyWithImpl<$Res, CategoryDTO>;
  @useResult
  $Res call({@JsonKey(name: 'id') int id, @JsonKey(name: 'name') String name});
}

/// @nodoc
class _$CategoryDTOCopyWithImpl<$Res, $Val extends CategoryDTO>
    implements $CategoryDTOCopyWith<$Res> {
  _$CategoryDTOCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_CategoryDTOCopyWith<$Res>
    implements $CategoryDTOCopyWith<$Res> {
  factory _$$_CategoryDTOCopyWith(
          _$_CategoryDTO value, $Res Function(_$_CategoryDTO) then) =
      __$$_CategoryDTOCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'id') int id, @JsonKey(name: 'name') String name});
}

/// @nodoc
class __$$_CategoryDTOCopyWithImpl<$Res>
    extends _$CategoryDTOCopyWithImpl<$Res, _$_CategoryDTO>
    implements _$$_CategoryDTOCopyWith<$Res> {
  __$$_CategoryDTOCopyWithImpl(
      _$_CategoryDTO _value, $Res Function(_$_CategoryDTO) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
  }) {
    return _then(_$_CategoryDTO(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_CategoryDTO extends _CategoryDTO {
  const _$_CategoryDTO(
      {@JsonKey(name: 'id') required this.id,
      @JsonKey(name: 'name') required this.name})
      : super._();

  factory _$_CategoryDTO.fromJson(Map<String, dynamic> json) =>
      _$$_CategoryDTOFromJson(json);

  /// The id of category.
  @override
  @JsonKey(name: 'id')
  final int id;

  /// The name of category
  /// For example: Film, Music, Books, etc...
  @override
  @JsonKey(name: 'name')
  final String name;

  @override
  String toString() {
    return 'CategoryDTO(id: $id, name: $name)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_CategoryDTO &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_CategoryDTOCopyWith<_$_CategoryDTO> get copyWith =>
      __$$_CategoryDTOCopyWithImpl<_$_CategoryDTO>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_CategoryDTOToJson(
      this,
    );
  }
}

abstract class _CategoryDTO extends CategoryDTO {
  const factory _CategoryDTO(
      {@JsonKey(name: 'id') required final int id,
      @JsonKey(name: 'name') required final String name}) = _$_CategoryDTO;
  const _CategoryDTO._() : super._();

  factory _CategoryDTO.fromJson(Map<String, dynamic> json) =
      _$_CategoryDTO.fromJson;

  @override

  /// The id of category.
  @JsonKey(name: 'id')
  int get id;
  @override

  /// The name of category
  /// For example: Film, Music, Books, etc...
  @JsonKey(name: 'name')
  String get name;
  @override
  @JsonKey(ignore: true)
  _$$_CategoryDTOCopyWith<_$_CategoryDTO> get copyWith =>
      throw _privateConstructorUsedError;
}