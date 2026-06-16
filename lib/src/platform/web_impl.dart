// coverage:ignore-file

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../models/serial_config.dart';
import '../models/serial_control_signals.dart';
import '../models/serial_error.dart';
import '../models/serial_port_info.dart';
import 'serial_platform_interface.dart';

/// Web implementation based on Web Serial API via `package:web` wrappers.
class WebSerialImpl implements SerialPlatformInterface {
  final Map<String, _WebPortContext> _ports = {};

  JSObject get _navigator => web.window.navigator as JSObject;

  JSObject get _serialApi {
    if (!_navigator.hasProperty('serial'.toJS).toDart) {
      throw SerialError(
        type: SerialErrorType.platformUnavailable,
        message: 'Web Serial API is not available in this browser.',
      );
    }
    return _navigator.getProperty<JSObject>('serial'.toJS);
  }

  @override
  Future<List<SerialPortInfo>> getAvailablePorts() async {
    try {
      final portsPromise =
          _serialApi.callMethod<JSPromise<JSAny?>>('getPorts'.toJS);
      final portsAny = await portsPromise.toDart;
      if (portsAny == null || portsAny.isUndefinedOrNull) {
        return const [];
      }

      final ports = (portsAny as JSArray<JSAny?>).toDart;
      return List<SerialPortInfo>.generate(ports.length, (index) {
        final port = ports[index] as JSObject;
        final info = port.callMethod<JSAny?>('getInfo'.toJS);

        String? vendorId;
        String? productId;
        if (info != null && !info.isUndefinedOrNull) {
          final infoObject = info as JSObject;
          final vendorValue = infoObject['usbVendorId'];
          final productValue = infoObject['usbProductId'];
          vendorId = _jsAnyToInt(vendorValue)?.toString();
          productId = _jsAnyToInt(productValue)?.toString();
        }

        return SerialPortInfo(
          portName: 'web-port-$index',
          description: 'Web Serial device',
          vendorId: vendorId,
          productId: productId,
          serialNumber: null,
          isOpen: false,
          platform: 'web',
        );
      });
    } catch (e) {
      if (e is SerialError) {
        rethrow;
      }
      throw SerialError(
        type: SerialErrorType.ioError,
        message: 'Error retrieving web serial ports: $e',
      );
    }
  }

  @override
  Future<void> openPort(SerialConfig config) async {
    if (_ports.containsKey(config.portName)) {
      throw SerialError(
        type: SerialErrorType.portAlreadyOpen,
        message: 'Port ${config.portName} is already open.',
      );
    }

    try {
      final portPromise =
          _serialApi.callMethod<JSPromise<JSAny?>>('requestPort'.toJS);
      final portAny = await portPromise.toDart;
      if (portAny == null || portAny.isUndefinedOrNull) {
        throw SerialError(
          type: SerialErrorType.portNotFound,
          message: 'No web serial device selected.',
        );
      }

      final port = portAny as JSObject;
      final options = <String, Object>{
        'baudRate': config.baudRate,
        'dataBits': config.dataBits,
        'stopBits': _mapStopBits(config.stopBits),
        'parity': _mapParity(config.parity),
        'flowControl': _mapFlowControl(config.flowControl),
      }.jsify() as JSObject;

      final openPromise = port.callMethodVarArgs<JSPromise<JSAny?>>(
        'open'.toJS,
        <JSAny?>[options],
      );
      await openPromise.toDart;

      final context = _WebPortContext(port: port);
      context.startReadLoop();
      _ports[config.portName] = context;
    } catch (e) {
      if (e is SerialError) {
        rethrow;
      }
      throw SerialError(
        type: SerialErrorType.ioError,
        message: 'Error opening web serial port: $e',
      );
    }
  }

  @override
  Future<void> closePort(String portName) async {
    final context = _ports.remove(portName);
    if (context == null) {
      throw SerialError(
        type: SerialErrorType.portClosed,
        message: 'Port $portName is not open.',
      );
    }
    await context.close();
  }

  @override
  Future<Uint8List> readData(String portName, int length) async {
    return _requireContext(portName).read(length);
  }

  @override
  Future<int> writeData(String portName, Uint8List data) async {
    final context = _requireContext(portName);
    try {
      final writableAny = context.port['writable'];
      if (writableAny == null || writableAny.isUndefinedOrNull) {
        throw SerialError(
          type: SerialErrorType.ioError,
          message: 'Web serial writable stream not available.',
        );
      }

      final writable = writableAny as JSObject;
      final writer = writable.callMethod<JSObject>('getWriter'.toJS);
      try {
        final writePromise = writer.callMethodVarArgs<JSPromise<JSAny?>>(
          'write'.toJS,
          <JSAny?>[data.toJS],
        );
        await writePromise.toDart;
      } finally {
        writer.callMethod<JSAny?>('releaseLock'.toJS);
      }
      return data.length;
    } catch (e) {
      if (e is SerialError) {
        rethrow;
      }
      throw SerialError(
        type: SerialErrorType.ioError,
        message: 'Error writing to web serial port: $e',
      );
    }
  }

  @override
  Future<int> bytesAvailable(String portName) async {
    return _requireContext(portName).availableBytes;
  }

  @override
  Future<void> resetBuffers(String portName) async {
    _requireContext(portName).clearBuffer();
  }

  @override
  Future<void> flush(String portName) async {
    _requireContext(portName);
  }

  @override
  Future<SerialControlSignals> getControlSignals(String portName) async {
    _requireContext(portName);
    throw SerialError(
      type: SerialErrorType.platformUnavailable,
      message: 'Control signals are not supported on web.',
    );
  }

  @override
  Future<void> setDtr(String portName, bool enabled) async {
    _requireContext(portName);
    throw SerialError(
      type: SerialErrorType.platformUnavailable,
      message: 'DTR control is not supported on web.',
    );
  }

  @override
  Future<void> setRts(String portName, bool enabled) async {
    _requireContext(portName);
    throw SerialError(
      type: SerialErrorType.platformUnavailable,
      message: 'RTS control is not supported on web.',
    );
  }

  @override
  Stream<dynamic> getEventStream(String portName) {
    return _requireContext(portName).events;
  }

  _WebPortContext _requireContext(String portName) {
    final context = _ports[portName];
    if (context == null) {
      throw SerialError(
        type: SerialErrorType.portClosed,
        message: 'Port $portName is not open.',
      );
    }
    return context;
  }

  int _mapStopBits(SerialStopBits stopBits) {
    switch (stopBits) {
      case SerialStopBits.one:
      case SerialStopBits.onePointFive:
        return 1;
      case SerialStopBits.two:
        return 2;
    }
  }

  String _mapParity(SerialParity parity) {
    switch (parity) {
      case SerialParity.none:
        return 'none';
      case SerialParity.even:
        return 'even';
      case SerialParity.odd:
        return 'odd';
      case SerialParity.mark:
      case SerialParity.space:
        return 'none';
    }
  }

  String _mapFlowControl(SerialFlowControl flowControl) {
    switch (flowControl) {
      case SerialFlowControl.none:
        return 'none';
      case SerialFlowControl.rtscts:
      case SerialFlowControl.xonxoff:
        return 'hardware';
    }
  }

  int? _jsAnyToInt(JSAny? value) {
    if (value == null || value.isUndefinedOrNull) {
      return null;
    }
    return value.dartify() as int?;
  }
}

class _WebPortContext {
  _WebPortContext({required this.port});

  final JSObject port;
  final StreamController<dynamic> _eventController =
      StreamController<dynamic>.broadcast();
  final List<int> _buffer = <int>[];

  JSObject? _reader;
  Completer<void>? _readNotifier;
  bool _closing = false;
  Future<void>? _readTask;

  Stream<dynamic> get events => _eventController.stream;

  int get availableBytes => _buffer.length;

  void clearBuffer() => _buffer.clear();

  void startReadLoop() {
    _readTask ??= _runReadLoop();
  }

  Future<void> _runReadLoop() async {
    try {
      final readableAny = port['readable'];
      if (readableAny == null || readableAny.isUndefinedOrNull) {
        return;
      }

      final readable = readableAny as JSObject;
      _reader = readable.callMethod<JSObject>('getReader'.toJS);

      while (!_closing) {
        final readPromise =
            _reader!.callMethod<JSPromise<JSAny?>>('read'.toJS);
        final resultAny = await readPromise.toDart;
        if (resultAny == null || resultAny.isUndefinedOrNull) {
          break;
        }

        final result = resultAny as JSObject;
        final doneAny = result['done'];
        final done = doneAny != null && doneAny.isA<JSBoolean>()
            ? (doneAny as JSBoolean).toDart
            : false;
        if (done) {
          break;
        }

        final valueAny = result['value'];
        final chunk = _toUint8List(valueAny);
        if (chunk.isEmpty) {
          continue;
        }

        _buffer.addAll(chunk);
        _eventController.add({
          'type': 'data',
          'data': chunk.toList(growable: false),
        });

        _readNotifier?.complete();
        _readNotifier = null;
      }
    } catch (e) {
      if (!_closing) {
        _eventController.add({
          'type': 'error',
          'message': 'Web serial read error: $e',
        });
      }
    } finally {
      if (_reader != null) {
        _reader!.callMethod<JSAny?>('releaseLock'.toJS);
      }
    }
  }

  Future<Uint8List> read(int length) async {
    final normalizedLength = length <= 0 ? 0 : length;
    if (normalizedLength == 0) {
      return Uint8List(0);
    }

    while (_buffer.isEmpty && !_closing) {
      _readNotifier ??= Completer<void>();
      await _readNotifier!.future;
    }

    if (_buffer.isEmpty) {
      return Uint8List(0);
    }

    final readLength = normalizedLength < _buffer.length
        ? normalizedLength
        : _buffer.length;
    final data = Uint8List.fromList(_buffer.sublist(0, readLength));
    _buffer.removeRange(0, readLength);
    return data;
  }

  Future<void> close() async {
    _closing = true;
    _readNotifier?.complete();
    _readNotifier = null;

    SerialError? closeError;

    try {
      if (_reader != null) {
        final cancelPromise =
            _reader!.callMethod<JSPromise<JSAny?>>('cancel'.toJS);
        await cancelPromise.toDart;
      }
    } catch (e) {
      closeError ??= SerialError(
        type: SerialErrorType.ioError,
        message: 'Error cancelling web serial reader: $e',
      );
    }

    try {
      await _readTask;
    } catch (e) {
      closeError ??= SerialError(
        type: SerialErrorType.ioError,
        message: 'Error completing web serial read loop: $e',
      );
    }

    try {
      final closePromise = port.callMethod<JSPromise<JSAny?>>('close'.toJS);
      await closePromise.toDart;
    } catch (e) {
      closeError ??= SerialError(
        type: SerialErrorType.ioError,
        message: 'Error closing web serial port: $e',
      );
    }

    try {
      await _eventController.close();
    } catch (e) {
      closeError ??= SerialError(
        type: SerialErrorType.ioError,
        message: 'Error closing web serial event stream: $e',
      );
    }

    if (closeError != null) {
      throw closeError;
    }
  }
}

Uint8List _toUint8List(JSAny? value) {
  if (value == null || value.isUndefinedOrNull) {
    return Uint8List(0);
  }

  if (value.isA<JSUint8Array>()) {
    return (value as JSUint8Array).toDart;
  }

  final dartValue = value.dartify();
  if (dartValue is Uint8List) {
    return dartValue;
  }
  if (dartValue is List) {
    return Uint8List.fromList(
      dartValue
          .whereType<num>()
          .map((item) => item.toInt())
          .toList(growable: false),
    );
  }
  return Uint8List(0);
}
