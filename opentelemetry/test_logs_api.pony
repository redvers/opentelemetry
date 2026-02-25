use "pony_test"
use otel_api = "otel_api"
use otel_sdk = "otel_sdk"


actor _MockLogProcessor is otel_sdk.LogRecordProcessor
  let _h: TestHelper
  let _expected_body: (String | None)
  let _expected_severity: U8
  let _check_trace: Bool
  let _check_attrs: Bool
  let _check_timestamp: U64

  new create(h: TestHelper,
    expected_body: (String | None) = None,
    expected_severity: U8 = 0,
    check_trace: Bool = false,
    check_attrs: Bool = false,
    check_timestamp: U64 = 0)
  =>
    _h = h
    _expected_body = expected_body
    _expected_severity = expected_severity
    _check_trace = check_trace
    _check_attrs = check_attrs
    _check_timestamp = check_timestamp

  be on_emit(log: otel_sdk.LogRecordData val) =>
    match _expected_body
    | let expected: String =>
      match log.body
      | let actual: String =>
        _h.assert_eq[String](expected, actual, "Log body should match")
      else
        _h.fail("Expected string body")
      end
    | None =>
      if _expected_severity > 0 then
        _h.assert_eq[U8](_expected_severity, log.severity_number,
          "Severity number should match")
      end
    end

    if _check_trace then
      _h.assert_true(log.trace_id.is_valid(),
        "trace_id should be valid when context has active span")
      _h.assert_true(log.span_id.is_valid(),
        "span_id should be valid when context has active span")
    end

    if _check_attrs then
      _h.assert_true(log.attributes.size() > 0,
        "Should have attributes")
    end

    if _check_timestamp > 0 then
      _h.assert_eq[U64](_check_timestamp, log.timestamp,
        "Explicit timestamp should be preserved")
    end

    _h.complete(true)

  be shutdown(callback: {(Bool)} val) =>
    callback(true)

  be force_flush(callback: {(Bool)} val) =>
    callback(true)


class iso _TestLogEmit is UnitTest
  fun name(): String => "Logs/emit"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let processor = _MockLogProcessor(h, "hello world")
    let processors: Array[otel_sdk.LogRecordProcessor tag] val =
      recover val [processor] end
    let provider = otel_sdk.SdkLoggerProvider(
      otel_sdk.LoggerProviderConfig, processors)
    let hh: TestHelper = h

    provider.get_logger("test-logger", {(logger: otel_api.Logger val)(hh) =>
      logger.emit("hello world")
    } val)


class iso _TestLogSeverity is UnitTest
  fun name(): String => "Logs/severity"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let processor = _MockLogProcessor(h where expected_severity = otel_api.SeverityNumber.warn())
    let processors: Array[otel_sdk.LogRecordProcessor tag] val =
      recover val [processor] end
    let provider = otel_sdk.SdkLoggerProvider(
      otel_sdk.LoggerProviderConfig, processors)
    let hh: TestHelper = h

    provider.get_logger("test-logger", {(logger: otel_api.Logger val)(hh) =>
      logger.emit(where severity_number = otel_api.SeverityNumber.warn(),
        severity_text = "WARN")
    } val)


class iso _TestLogTraceCorrelation is UnitTest
  fun name(): String => "Logs/trace_correlation"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let processor = _MockLogProcessor(h where check_trace = true)
    let processors: Array[otel_sdk.LogRecordProcessor tag] val =
      recover val [processor] end
    let provider = otel_sdk.SdkLoggerProvider(
      otel_sdk.LoggerProviderConfig, processors)
    let hh: TestHelper = h

    provider.get_logger("test-logger", {(logger: otel_api.Logger val)(hh) =>
      let sc = otel_api.SpanContext(
        otel_api.TraceId.generate(),
        otel_api.SpanId.generate(),
        otel_api.TraceFlags.sampled())
      let ctx = otel_api.Context(sc)
      logger.emit("with trace" where context = ctx)
    } val)


class iso _TestLogAttributes is UnitTest
  fun name(): String => "Logs/attributes"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let processor = _MockLogProcessor(h where check_attrs = true)
    let processors: Array[otel_sdk.LogRecordProcessor tag] val =
      recover val [processor] end
    let provider = otel_sdk.SdkLoggerProvider(
      otel_sdk.LoggerProviderConfig, processors)
    let hh: TestHelper = h

    provider.get_logger("test-logger", {(logger: otel_api.Logger val)(hh) =>
      let attrs: otel_api.Attributes = recover val
        let a = Array[(String, otel_api.AttributeValue)]
        a.push(("key", "value"))
        a
      end
      logger.emit("with attrs" where attributes = attrs)
    } val)


class iso _TestLogTimestamps is UnitTest
  fun name(): String => "Logs/timestamps"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let explicit_ts: U64 = 1234567890_000000000
    let processor = _MockLogProcessor(h where check_timestamp = explicit_ts)
    let processors: Array[otel_sdk.LogRecordProcessor tag] val =
      recover val [processor] end
    let provider = otel_sdk.SdkLoggerProvider(
      otel_sdk.LoggerProviderConfig, processors)
    let hh: TestHelper = h

    provider.get_logger("test-logger", {(logger: otel_api.Logger val)(hh) =>
      logger.emit("timed" where timestamp = 1234567890_000000000)
    } val)


class iso _TestNoopLogger is UnitTest
  fun name(): String => "Logs/noop_logger"

  fun apply(h: TestHelper) =>
    let logger: otel_api.Logger val = otel_api.NoopLogger
    // Should not crash
    logger.emit("hello")
    logger.emit(where severity_number = otel_api.SeverityNumber.err())
    let attrs: otel_api.Attributes = recover val
      let a = Array[(String, otel_api.AttributeValue)]
      a.push(("key", "value"))
      a
    end
    logger.emit("with attrs" where attributes = attrs)


class iso _TestLoggerProviderShutdown is UnitTest
  fun name(): String => "Logs/logger_provider_shutdown"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let provider = otel_sdk.SdkLoggerProvider
    let hh: TestHelper = h

    provider.shutdown({(ok: Bool)(hh) =>
      hh.assert_true(ok, "Shutdown should succeed")
      hh.complete(true)
    } val)
