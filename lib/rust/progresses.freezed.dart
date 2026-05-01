// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'progresses.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Phase {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Phase);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Phase()';
}


}

/// @nodoc
class $PhaseCopyWith<$Res>  {
$PhaseCopyWith(Phase _, $Res Function(Phase) __);
}


/// Adds pattern-matching-related methods to [Phase].
extension PhasePatterns on Phase {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Phase_Importing value)?  importing,TResult Function( Phase_Uploading value)?  uploading,TResult Function( Phase_Pending value)?  pending,TResult Function( Phase_Connecting value)?  connecting,TResult Function( Phase_Validating value)?  validating,TResult Function( Phase_Downloading value)?  downloading,TResult Function( Phase_Exporting value)?  exporting,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Phase_Importing() when importing != null:
return importing(_that);case Phase_Uploading() when uploading != null:
return uploading(_that);case Phase_Pending() when pending != null:
return pending(_that);case Phase_Connecting() when connecting != null:
return connecting(_that);case Phase_Validating() when validating != null:
return validating(_that);case Phase_Downloading() when downloading != null:
return downloading(_that);case Phase_Exporting() when exporting != null:
return exporting(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Phase_Importing value)  importing,required TResult Function( Phase_Uploading value)  uploading,required TResult Function( Phase_Pending value)  pending,required TResult Function( Phase_Connecting value)  connecting,required TResult Function( Phase_Validating value)  validating,required TResult Function( Phase_Downloading value)  downloading,required TResult Function( Phase_Exporting value)  exporting,}){
final _that = this;
switch (_that) {
case Phase_Importing():
return importing(_that);case Phase_Uploading():
return uploading(_that);case Phase_Pending():
return pending(_that);case Phase_Connecting():
return connecting(_that);case Phase_Validating():
return validating(_that);case Phase_Downloading():
return downloading(_that);case Phase_Exporting():
return exporting(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Phase_Importing value)?  importing,TResult? Function( Phase_Uploading value)?  uploading,TResult? Function( Phase_Pending value)?  pending,TResult? Function( Phase_Connecting value)?  connecting,TResult? Function( Phase_Validating value)?  validating,TResult? Function( Phase_Downloading value)?  downloading,TResult? Function( Phase_Exporting value)?  exporting,}){
final _that = this;
switch (_that) {
case Phase_Importing() when importing != null:
return importing(_that);case Phase_Uploading() when uploading != null:
return uploading(_that);case Phase_Pending() when pending != null:
return pending(_that);case Phase_Connecting() when connecting != null:
return connecting(_that);case Phase_Validating() when validating != null:
return validating(_that);case Phase_Downloading() when downloading != null:
return downloading(_that);case Phase_Exporting() when exporting != null:
return exporting(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String name)?  importing,TResult Function( String endpoint,  bool isCompleted,  bool isFailed)?  uploading,TResult Function()?  pending,TResult Function()?  connecting,TResult Function()?  validating,TResult Function()?  downloading,TResult Function( String name)?  exporting,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Phase_Importing() when importing != null:
return importing(_that.name);case Phase_Uploading() when uploading != null:
return uploading(_that.endpoint,_that.isCompleted,_that.isFailed);case Phase_Pending() when pending != null:
return pending();case Phase_Connecting() when connecting != null:
return connecting();case Phase_Validating() when validating != null:
return validating();case Phase_Downloading() when downloading != null:
return downloading();case Phase_Exporting() when exporting != null:
return exporting(_that.name);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String name)  importing,required TResult Function( String endpoint,  bool isCompleted,  bool isFailed)  uploading,required TResult Function()  pending,required TResult Function()  connecting,required TResult Function()  validating,required TResult Function()  downloading,required TResult Function( String name)  exporting,}) {final _that = this;
switch (_that) {
case Phase_Importing():
return importing(_that.name);case Phase_Uploading():
return uploading(_that.endpoint,_that.isCompleted,_that.isFailed);case Phase_Pending():
return pending();case Phase_Connecting():
return connecting();case Phase_Validating():
return validating();case Phase_Downloading():
return downloading();case Phase_Exporting():
return exporting(_that.name);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String name)?  importing,TResult? Function( String endpoint,  bool isCompleted,  bool isFailed)?  uploading,TResult? Function()?  pending,TResult? Function()?  connecting,TResult? Function()?  validating,TResult? Function()?  downloading,TResult? Function( String name)?  exporting,}) {final _that = this;
switch (_that) {
case Phase_Importing() when importing != null:
return importing(_that.name);case Phase_Uploading() when uploading != null:
return uploading(_that.endpoint,_that.isCompleted,_that.isFailed);case Phase_Pending() when pending != null:
return pending();case Phase_Connecting() when connecting != null:
return connecting();case Phase_Validating() when validating != null:
return validating();case Phase_Downloading() when downloading != null:
return downloading();case Phase_Exporting() when exporting != null:
return exporting(_that.name);case _:
  return null;

}
}

}

/// @nodoc


class Phase_Importing extends Phase {
  const Phase_Importing({required this.name}): super._();
  

 final  String name;

/// Create a copy of Phase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Phase_ImportingCopyWith<Phase_Importing> get copyWith => _$Phase_ImportingCopyWithImpl<Phase_Importing>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Phase_Importing&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'Phase.importing(name: $name)';
}


}

/// @nodoc
abstract mixin class $Phase_ImportingCopyWith<$Res> implements $PhaseCopyWith<$Res> {
  factory $Phase_ImportingCopyWith(Phase_Importing value, $Res Function(Phase_Importing) _then) = _$Phase_ImportingCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class _$Phase_ImportingCopyWithImpl<$Res>
    implements $Phase_ImportingCopyWith<$Res> {
  _$Phase_ImportingCopyWithImpl(this._self, this._then);

  final Phase_Importing _self;
  final $Res Function(Phase_Importing) _then;

/// Create a copy of Phase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(Phase_Importing(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class Phase_Uploading extends Phase {
  const Phase_Uploading({required this.endpoint, required this.isCompleted, required this.isFailed}): super._();
  

 final  String endpoint;
 final  bool isCompleted;
 final  bool isFailed;

/// Create a copy of Phase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Phase_UploadingCopyWith<Phase_Uploading> get copyWith => _$Phase_UploadingCopyWithImpl<Phase_Uploading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Phase_Uploading&&(identical(other.endpoint, endpoint) || other.endpoint == endpoint)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.isFailed, isFailed) || other.isFailed == isFailed));
}


@override
int get hashCode => Object.hash(runtimeType,endpoint,isCompleted,isFailed);

@override
String toString() {
  return 'Phase.uploading(endpoint: $endpoint, isCompleted: $isCompleted, isFailed: $isFailed)';
}


}

/// @nodoc
abstract mixin class $Phase_UploadingCopyWith<$Res> implements $PhaseCopyWith<$Res> {
  factory $Phase_UploadingCopyWith(Phase_Uploading value, $Res Function(Phase_Uploading) _then) = _$Phase_UploadingCopyWithImpl;
@useResult
$Res call({
 String endpoint, bool isCompleted, bool isFailed
});




}
/// @nodoc
class _$Phase_UploadingCopyWithImpl<$Res>
    implements $Phase_UploadingCopyWith<$Res> {
  _$Phase_UploadingCopyWithImpl(this._self, this._then);

  final Phase_Uploading _self;
  final $Res Function(Phase_Uploading) _then;

/// Create a copy of Phase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? endpoint = null,Object? isCompleted = null,Object? isFailed = null,}) {
  return _then(Phase_Uploading(
endpoint: null == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,isFailed: null == isFailed ? _self.isFailed : isFailed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class Phase_Pending extends Phase {
  const Phase_Pending(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Phase_Pending);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Phase.pending()';
}


}




/// @nodoc


class Phase_Connecting extends Phase {
  const Phase_Connecting(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Phase_Connecting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Phase.connecting()';
}


}




/// @nodoc


class Phase_Validating extends Phase {
  const Phase_Validating(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Phase_Validating);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Phase.validating()';
}


}




/// @nodoc


class Phase_Downloading extends Phase {
  const Phase_Downloading(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Phase_Downloading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Phase.downloading()';
}


}




/// @nodoc


class Phase_Exporting extends Phase {
  const Phase_Exporting({required this.name}): super._();
  

 final  String name;

/// Create a copy of Phase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Phase_ExportingCopyWith<Phase_Exporting> get copyWith => _$Phase_ExportingCopyWithImpl<Phase_Exporting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Phase_Exporting&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'Phase.exporting(name: $name)';
}


}

/// @nodoc
abstract mixin class $Phase_ExportingCopyWith<$Res> implements $PhaseCopyWith<$Res> {
  factory $Phase_ExportingCopyWith(Phase_Exporting value, $Res Function(Phase_Exporting) _then) = _$Phase_ExportingCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class _$Phase_ExportingCopyWithImpl<$Res>
    implements $Phase_ExportingCopyWith<$Res> {
  _$Phase_ExportingCopyWithImpl(this._self, this._then);

  final Phase_Exporting _self;
  final $Res Function(Phase_Exporting) _then;

/// Create a copy of Phase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(Phase_Exporting(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
