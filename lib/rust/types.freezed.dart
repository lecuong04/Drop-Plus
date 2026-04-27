// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'types.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReceiveResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiveResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReceiveResult()';
}


}

/// @nodoc
class $ReceiveResultCopyWith<$Res>  {
$ReceiveResultCopyWith(ReceiveResult _, $Res Function(ReceiveResult) __);
}


/// Adds pattern-matching-related methods to [ReceiveResult].
extension ReceiveResultPatterns on ReceiveResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReceiveResult_Pending value)?  pending,TResult Function( ReceiveResult_Ok value)?  ok,TResult Function( ReceiveResult_Err value)?  err,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReceiveResult_Pending() when pending != null:
return pending(_that);case ReceiveResult_Ok() when ok != null:
return ok(_that);case ReceiveResult_Err() when err != null:
return err(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReceiveResult_Pending value)  pending,required TResult Function( ReceiveResult_Ok value)  ok,required TResult Function( ReceiveResult_Err value)  err,}){
final _that = this;
switch (_that) {
case ReceiveResult_Pending():
return pending(_that);case ReceiveResult_Ok():
return ok(_that);case ReceiveResult_Err():
return err(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReceiveResult_Pending value)?  pending,TResult? Function( ReceiveResult_Ok value)?  ok,TResult? Function( ReceiveResult_Err value)?  err,}){
final _that = this;
switch (_that) {
case ReceiveResult_Pending() when pending != null:
return pending(_that);case ReceiveResult_Ok() when ok != null:
return ok(_that);case ReceiveResult_Err() when err != null:
return err(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<BlobInfo> files)?  pending,TResult Function( BigInt totalFiles,  BigInt payloadSize,  BigInt elapsedSecs)?  ok,TResult Function()?  err,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReceiveResult_Pending() when pending != null:
return pending(_that.files);case ReceiveResult_Ok() when ok != null:
return ok(_that.totalFiles,_that.payloadSize,_that.elapsedSecs);case ReceiveResult_Err() when err != null:
return err();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<BlobInfo> files)  pending,required TResult Function( BigInt totalFiles,  BigInt payloadSize,  BigInt elapsedSecs)  ok,required TResult Function()  err,}) {final _that = this;
switch (_that) {
case ReceiveResult_Pending():
return pending(_that.files);case ReceiveResult_Ok():
return ok(_that.totalFiles,_that.payloadSize,_that.elapsedSecs);case ReceiveResult_Err():
return err();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<BlobInfo> files)?  pending,TResult? Function( BigInt totalFiles,  BigInt payloadSize,  BigInt elapsedSecs)?  ok,TResult? Function()?  err,}) {final _that = this;
switch (_that) {
case ReceiveResult_Pending() when pending != null:
return pending(_that.files);case ReceiveResult_Ok() when ok != null:
return ok(_that.totalFiles,_that.payloadSize,_that.elapsedSecs);case ReceiveResult_Err() when err != null:
return err();case _:
  return null;

}
}

}

/// @nodoc


class ReceiveResult_Pending extends ReceiveResult {
  const ReceiveResult_Pending({required final  List<BlobInfo> files}): _files = files,super._();
  

 final  List<BlobInfo> _files;
 List<BlobInfo> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}


/// Create a copy of ReceiveResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiveResult_PendingCopyWith<ReceiveResult_Pending> get copyWith => _$ReceiveResult_PendingCopyWithImpl<ReceiveResult_Pending>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiveResult_Pending&&const DeepCollectionEquality().equals(other._files, _files));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_files));

@override
String toString() {
  return 'ReceiveResult.pending(files: $files)';
}


}

/// @nodoc
abstract mixin class $ReceiveResult_PendingCopyWith<$Res> implements $ReceiveResultCopyWith<$Res> {
  factory $ReceiveResult_PendingCopyWith(ReceiveResult_Pending value, $Res Function(ReceiveResult_Pending) _then) = _$ReceiveResult_PendingCopyWithImpl;
@useResult
$Res call({
 List<BlobInfo> files
});




}
/// @nodoc
class _$ReceiveResult_PendingCopyWithImpl<$Res>
    implements $ReceiveResult_PendingCopyWith<$Res> {
  _$ReceiveResult_PendingCopyWithImpl(this._self, this._then);

  final ReceiveResult_Pending _self;
  final $Res Function(ReceiveResult_Pending) _then;

/// Create a copy of ReceiveResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? files = null,}) {
  return _then(ReceiveResult_Pending(
files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<BlobInfo>,
  ));
}


}

/// @nodoc


class ReceiveResult_Ok extends ReceiveResult {
  const ReceiveResult_Ok({required this.totalFiles, required this.payloadSize, required this.elapsedSecs}): super._();
  

 final  BigInt totalFiles;
 final  BigInt payloadSize;
 final  BigInt elapsedSecs;

/// Create a copy of ReceiveResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiveResult_OkCopyWith<ReceiveResult_Ok> get copyWith => _$ReceiveResult_OkCopyWithImpl<ReceiveResult_Ok>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiveResult_Ok&&(identical(other.totalFiles, totalFiles) || other.totalFiles == totalFiles)&&(identical(other.payloadSize, payloadSize) || other.payloadSize == payloadSize)&&(identical(other.elapsedSecs, elapsedSecs) || other.elapsedSecs == elapsedSecs));
}


@override
int get hashCode => Object.hash(runtimeType,totalFiles,payloadSize,elapsedSecs);

@override
String toString() {
  return 'ReceiveResult.ok(totalFiles: $totalFiles, payloadSize: $payloadSize, elapsedSecs: $elapsedSecs)';
}


}

/// @nodoc
abstract mixin class $ReceiveResult_OkCopyWith<$Res> implements $ReceiveResultCopyWith<$Res> {
  factory $ReceiveResult_OkCopyWith(ReceiveResult_Ok value, $Res Function(ReceiveResult_Ok) _then) = _$ReceiveResult_OkCopyWithImpl;
@useResult
$Res call({
 BigInt totalFiles, BigInt payloadSize, BigInt elapsedSecs
});




}
/// @nodoc
class _$ReceiveResult_OkCopyWithImpl<$Res>
    implements $ReceiveResult_OkCopyWith<$Res> {
  _$ReceiveResult_OkCopyWithImpl(this._self, this._then);

  final ReceiveResult_Ok _self;
  final $Res Function(ReceiveResult_Ok) _then;

/// Create a copy of ReceiveResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? totalFiles = null,Object? payloadSize = null,Object? elapsedSecs = null,}) {
  return _then(ReceiveResult_Ok(
totalFiles: null == totalFiles ? _self.totalFiles : totalFiles // ignore: cast_nullable_to_non_nullable
as BigInt,payloadSize: null == payloadSize ? _self.payloadSize : payloadSize // ignore: cast_nullable_to_non_nullable
as BigInt,elapsedSecs: null == elapsedSecs ? _self.elapsedSecs : elapsedSecs // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class ReceiveResult_Err extends ReceiveResult {
  const ReceiveResult_Err(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiveResult_Err);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReceiveResult.err()';
}


}




/// @nodoc
mixin _$SendResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SendResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SendResult()';
}


}

/// @nodoc
class $SendResultCopyWith<$Res>  {
$SendResultCopyWith(SendResult _, $Res Function(SendResult) __);
}


/// Adds pattern-matching-related methods to [SendResult].
extension SendResultPatterns on SendResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SendResult_Ok value)?  ok,TResult Function( SendResult_Err value)?  err,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SendResult_Ok() when ok != null:
return ok(_that);case SendResult_Err() when err != null:
return err(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SendResult_Ok value)  ok,required TResult Function( SendResult_Err value)  err,}){
final _that = this;
switch (_that) {
case SendResult_Ok():
return ok(_that);case SendResult_Err():
return err(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SendResult_Ok value)?  ok,TResult? Function( SendResult_Err value)?  err,}){
final _that = this;
switch (_that) {
case SendResult_Ok() when ok != null:
return ok(_that);case SendResult_Err() when err != null:
return err(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Uint8List ticket,  BigInt size)?  ok,TResult Function()?  err,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SendResult_Ok() when ok != null:
return ok(_that.ticket,_that.size);case SendResult_Err() when err != null:
return err();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Uint8List ticket,  BigInt size)  ok,required TResult Function()  err,}) {final _that = this;
switch (_that) {
case SendResult_Ok():
return ok(_that.ticket,_that.size);case SendResult_Err():
return err();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Uint8List ticket,  BigInt size)?  ok,TResult? Function()?  err,}) {final _that = this;
switch (_that) {
case SendResult_Ok() when ok != null:
return ok(_that.ticket,_that.size);case SendResult_Err() when err != null:
return err();case _:
  return null;

}
}

}

/// @nodoc


class SendResult_Ok extends SendResult {
  const SendResult_Ok({required this.ticket, required this.size}): super._();
  

 final  Uint8List ticket;
 final  BigInt size;

/// Create a copy of SendResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SendResult_OkCopyWith<SendResult_Ok> get copyWith => _$SendResult_OkCopyWithImpl<SendResult_Ok>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SendResult_Ok&&const DeepCollectionEquality().equals(other.ticket, ticket)&&(identical(other.size, size) || other.size == size));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(ticket),size);

@override
String toString() {
  return 'SendResult.ok(ticket: $ticket, size: $size)';
}


}

/// @nodoc
abstract mixin class $SendResult_OkCopyWith<$Res> implements $SendResultCopyWith<$Res> {
  factory $SendResult_OkCopyWith(SendResult_Ok value, $Res Function(SendResult_Ok) _then) = _$SendResult_OkCopyWithImpl;
@useResult
$Res call({
 Uint8List ticket, BigInt size
});




}
/// @nodoc
class _$SendResult_OkCopyWithImpl<$Res>
    implements $SendResult_OkCopyWith<$Res> {
  _$SendResult_OkCopyWithImpl(this._self, this._then);

  final SendResult_Ok _self;
  final $Res Function(SendResult_Ok) _then;

/// Create a copy of SendResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? ticket = null,Object? size = null,}) {
  return _then(SendResult_Ok(
ticket: null == ticket ? _self.ticket : ticket // ignore: cast_nullable_to_non_nullable
as Uint8List,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class SendResult_Err extends SendResult {
  const SendResult_Err(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SendResult_Err);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SendResult.err()';
}


}




// dart format on
