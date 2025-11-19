import 'package:flutter/material.dart';

class ConstantAnimation<T> extends Animation<T> {
  final T _value;

  ConstantAnimation(this._value);

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  void addStatusListener(AnimationStatusListener listener) {}

  @override
  void removeStatusListener(AnimationStatusListener listener) {}

  @override
  AnimationStatus get status => AnimationStatus.forward;

  @override
  T get value => _value;
}
