// Copyright (c) 2026 Piergiorgio Vagnozzi.
// Licensed under the MIT License.

// ignore_for_file: avoid_dynamic_calls

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:platform_serial/platform_serial.dart';

/// A hand-rolled stub that always throws [SerialErrorType.platformUnavailable].
/// This mimics the internal `_UnsupportedSerialPlatformInterface` without
/// relying on access to the private class in the library.
class _UnsupportedStub implements SerialPlatformInterface {
  SerialError _err() => SerialError(
        type: SerialErrorType.platformUnavailable,
        message: 'Serial platform is not available in this runtime.',
      );

  @override
  Future<int> bytesAvailable(String portName) async => throw _err();
  @override
  Future<void> closePort(String portName) async => throw _err();
  @override
  Future<void> flush(String portName) async => throw _err();
  @override
  Stream<dynamic> getEventStream(String portName) => Stream.error(_err());
  @override
  Future<List<SerialPortInfo>> getAvailablePorts() async => throw _err();
  @override
  Future<SerialControlSignals> getControlSignals(String portName) async =>
      throw _err();
  @override
  Future<void> openPort(SerialConfig config) async => throw _err();
  @override
  Future<Uint8List> readData(String portName, int length) async => throw _err();
  @override
  Future<void> resetBuffers(String portName) async => throw _err();
  @override
  Future<void> setDtr(String portName, bool enabled) async => throw _err();
  @override
  Future<void> setRts(String portName, bool enabled) async => throw _err();
  @override
  Future<int> writeData(String portName, Uint8List data) async => throw _err();
}

class _MockPlatform extends Mock implements SerialPlatformInterface {}

void main() {
  setUpAll(() {
    registerFallbackValue(const SerialConfig(portName: 'COM1'));
    registerFallbackValue(Uint8List(0));
  });

  group('WebSerialImpl — non-browser unit tests', () {
    test('SerialErrorType.platformUnavailable has correct string', () {
      final error = SerialError(
        type: SerialErrorType.platformUnavailable,
        message: 'Web Serial API is not available in this browser.',
      );
      expect(error.type, SerialErrorType.platformUnavailable);
      expect(error.message, contains('Web Serial API'));
    });

    test('SerialError toString includes type and message', () {
      final error = SerialError(
        type: SerialErrorType.ioError,
        message: 'write failed',
      );
      expect(error.toString(), contains('ioError'));
      expect(error.toString(), contains('write failed'));
    });

    test('SerialError can carry an optional stack trace', () {
      final st = StackTrace.current;
      final error = SerialError(
        type: SerialErrorType.timeout,
        message: 'timed out',
        stackTrace: st,
      );
      expect(error.stackTrace, same(st));
    });
  });

  group('PlatformSerialWeb registrar (conceptual)', () {
    test('SerialPlatformInterface factory constructs without throwing', () {
      expect(() => SerialPlatformInterface(), returnsNormally);
    });

    test('factory result implements SerialPlatformInterface', () {
      final platform = SerialPlatformInterface();
      expect(platform, isA<SerialPlatformInterface>());
    });
  });

  group('_UnsupportedStub — stub throws platformUnavailable on all methods',
      () {
    late _UnsupportedStub stub;

    setUp(() {
      stub = _UnsupportedStub();
    });

    test('getAvailablePorts throws platformUnavailable', () async {
      await expectLater(
        stub.getAvailablePorts(),
        throwsA(
          isA<SerialError>().having(
            (SerialError e) => e.type,
            'type',
            SerialErrorType.platformUnavailable,
          ),
        ),
      );
    });

    test('openPort throws platformUnavailable', () async {
      await expectLater(
        stub.openPort(const SerialConfig(portName: 'COM1')),
        throwsA(isA<SerialError>()),
      );
    });

    test('getEventStream emits platformUnavailable error', () async {
      await expectLater(
        stub.getEventStream('COM1'),
        emitsError(
          isA<SerialError>().having(
            (SerialError e) => e.type,
            'type',
            SerialErrorType.platformUnavailable,
          ),
        ),
      );
    });

    test('bytesAvailable throws platformUnavailable', () async {
      await expectLater(
        stub.bytesAvailable('COM1'),
        throwsA(isA<SerialError>()),
      );
    });

    test('writeData throws platformUnavailable', () async {
      await expectLater(
        stub.writeData('COM1', Uint8List.fromList([0x41])),
        throwsA(isA<SerialError>()),
      );
    });
  });

  group('SerialManager with mock platform', () {
    test('uses injected platform when provided', () async {
      final mock = _MockPlatform();
      when(() => mock.getAvailablePorts()).thenAnswer((_) async => []);
      final manager = SerialManager(platform: mock);
      final ports = await manager.getAvailablePorts();
      expect(ports, isEmpty);
      verify(() => mock.getAvailablePorts()).called(1);
    });
  });
}
