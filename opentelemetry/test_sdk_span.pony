use "pony_test"
use otel_api = "otel_api"
use otel_sdk = "otel_sdk"

class iso _TestSdkSpanFinish is UnitTest
  fun name(): String => "SdkSpan/finish"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let trace_id = otel_api.TraceId.generate()
    let span_id = otel_api.SpanId.generate()
    let sc = otel_api.SpanContext(trace_id, span_id)

    let hh: TestHelper = h

    let on_finish = {(ro: otel_sdk.ReadOnlySpan val)(hh) =>
      hh.assert_eq[String]("test-op", ro.name)
      hh.assert_true(ro.end_time >= ro.start_time,
        "end_time should be >= start_time")
      hh.assert_true(ro.span_context.is_valid(),
        "ReadOnlySpan should have valid span context")
      hh.complete(true)
    } val

    let span = otel_sdk.SdkSpan(
      "test-op",
      sc,
      otel_api.SpanId.invalid(),
      otel_api.SpanKindInternal,
      otel_api.Resource,
      "test-lib",
      "1.0.0",
      otel_sdk.SpanLimits,
      on_finish)

    h.assert_true(span.is_recording(), "Span should be recording before finish")
    span.finish()
    h.assert_false(span.is_recording(), "Span should not be recording after finish")


class iso _TestSdkSpanDoubleFinish is UnitTest
  fun name(): String => "SdkSpan/double_finish"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let trace_id = otel_api.TraceId.generate()
    let span_id = otel_api.SpanId.generate()
    let sc = otel_api.SpanContext(trace_id, span_id)

    var finish_count: USize = 0
    let hh: TestHelper = h

    let counter = object tag
      var _count: USize = 0
      let _h: TestHelper = hh

      be increment() =>
        _count = _count + 1
        if _count == 1 then
          _h.complete(true)
        elseif _count > 1 then
          _h.fail("on_finish called more than once")
          _h.complete(false)
        end
    end

    let on_finish = {(ro: otel_sdk.ReadOnlySpan val)(counter) =>
      counter.increment()
    } val

    let span = otel_sdk.SdkSpan(
      "test-op",
      sc,
      otel_api.SpanId.invalid(),
      otel_api.SpanKindInternal,
      otel_api.Resource,
      "test-lib",
      "1.0.0",
      otel_sdk.SpanLimits,
      on_finish)

    span.finish()
    span.finish()  // Second call should be ignored


class iso _TestSdkSpanAttributes is UnitTest
  fun name(): String => "SdkSpan/attributes"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let trace_id = otel_api.TraceId.generate()
    let span_id = otel_api.SpanId.generate()
    let sc = otel_api.SpanContext(trace_id, span_id)

    let hh: TestHelper = h

    let on_finish = {(ro: otel_sdk.ReadOnlySpan val)(hh) =>
      hh.assert_eq[USize](2, ro.attributes.size(),
        "Should have 2 attributes")
      hh.complete(true)
    } val

    let span = otel_sdk.SdkSpan(
      "test-op",
      sc,
      otel_api.SpanId.invalid(),
      otel_api.SpanKindInternal,
      otel_api.Resource,
      "test-lib",
      "1.0.0",
      otel_sdk.SpanLimits,
      on_finish)

    span.set_attribute("key1", "value1")
    span.set_attribute("key2", I64(42))
    span.finish()


class iso _TestSdkSpanEvents is UnitTest
  fun name(): String => "SdkSpan/events"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let trace_id = otel_api.TraceId.generate()
    let span_id = otel_api.SpanId.generate()
    let sc = otel_api.SpanContext(trace_id, span_id)

    let hh: TestHelper = h

    let on_finish = {(ro: otel_sdk.ReadOnlySpan val)(hh) =>
      hh.assert_eq[USize](1, ro.events.size(),
        "Should have 1 event")
      try
        hh.assert_eq[String]("something happened", ro.events(0)?.name)
      else
        hh.fail("Could not read event")
      end
      hh.complete(true)
    } val

    let span = otel_sdk.SdkSpan(
      "test-op",
      sc,
      otel_api.SpanId.invalid(),
      otel_api.SpanKindInternal,
      otel_api.Resource,
      "test-lib",
      "1.0.0",
      otel_sdk.SpanLimits,
      on_finish)

    span.add_event("something happened")
    span.finish()


class iso _TestSdkSpanStatusPrecedence is UnitTest
  fun name(): String => "SdkSpan/status_precedence"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let trace_id = otel_api.TraceId.generate()
    let span_id = otel_api.SpanId.generate()
    let sc = otel_api.SpanContext(trace_id, span_id)

    let hh: TestHelper = h

    let on_finish = {(ro: otel_sdk.ReadOnlySpan val)(hh) =>
      // Ok status should not be overridden by Error
      hh.assert_is[otel_api.SpanStatusCode](
        ro.status.code, otel_api.SpanStatusOk,
        "Status should remain Ok after attempted Error override")
      hh.complete(true)
    } val

    let span = otel_sdk.SdkSpan(
      "test-op",
      sc,
      otel_api.SpanId.invalid(),
      otel_api.SpanKindInternal,
      otel_api.Resource,
      "test-lib",
      "1.0.0",
      otel_sdk.SpanLimits,
      on_finish)

    span.set_status(otel_api.SpanStatusOk)
    span.set_status(otel_api.SpanStatusError, "should be ignored")
    span.finish()


actor _MockSpanProcessor is otel_sdk.SpanProcessor
  let _h: TestHelper
  let _expected_name: String

  new create(h: TestHelper, expected_name: String) =>
    _h = h
    _expected_name = expected_name

  be on_start(span: otel_sdk.ReadOnlySpan val) => None

  be on_end(span: otel_sdk.ReadOnlySpan val) =>
    _h.assert_eq[String](_expected_name, span.name)
    _h.assert_true(span.span_context.is_valid(),
      "Finished span should have valid context")
    _h.assert_true(span.end_time >= span.start_time,
      "end_time should be >= start_time")
    _h.assert_eq[String]("test-scope", span.instrumentation_scope_name)
    _h.assert_eq[String]("0.1.0", span.instrumentation_scope_version)
    _h.complete(true)

  be shutdown(callback: {(Bool)} val) =>
    callback(true)

  be force_flush(callback: {(Bool)} val) =>
    callback(true)


class iso _TestFullSpanPipeline is UnitTest
  fun name(): String => "SdkSpan/full_pipeline"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let processor = _MockSpanProcessor(h, "pipeline-span")
    let processors: Array[otel_sdk.SpanProcessor tag] val =
      recover val [as otel_sdk.SpanProcessor tag: processor] end
    let config = otel_sdk.TracerProviderConfig
    let provider = otel_sdk.SdkTracerProvider(config, processors)

    let cb = {(tracer: otel_api.Tracer val)(h) =>
      (let span, let ctx) = tracer.start_span("pipeline-span",
        otel_api.Context, otel_api.SpanKindServer)
      span.set_attribute("http.method", "GET")
      span.finish()
    } val

    provider.get_tracer("test-scope", cb, "0.1.0")


class iso _TestSdkSpanAttributeTruncation is UnitTest
  fun name(): String => "SdkSpan/attribute_truncation"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let trace_id = otel_api.TraceId.generate()
    let span_id = otel_api.SpanId.generate()
    let sc = otel_api.SpanContext(trace_id, span_id)

    let hh: TestHelper = h

    let on_finish = {(ro: otel_sdk.ReadOnlySpan val)(hh) =>
      try
        // String attribute should be truncated to 5 bytes
        (let k1, let v1) = ro.attributes(0)?
        match v1
        | let s: String =>
          hh.assert_eq[USize](5, s.size(),
            "String should be truncated to max_attribute_value_length")
          hh.assert_eq[String]("hello", s)
        else
          hh.fail("Expected String attribute")
        end

        // I64 attribute should not be truncated
        (let k2, let v2) = ro.attributes(1)?
        match v2
        | let i: I64 =>
          hh.assert_eq[I64](999, i, "I64 should not be truncated")
        else
          hh.fail("Expected I64 attribute")
        end

        // String array attribute should have each item truncated
        (let k3, let v3) = ro.attributes(2)?
        match v3
        | let arr: Array[String] val =>
          hh.assert_eq[USize](2, arr.size())
          try
            hh.assert_eq[String]("abcde", arr(0)?,
              "Array items should be truncated")
            hh.assert_eq[String]("xy", arr(1)?,
              "Short array items should be unchanged")
          else
            hh.fail("Could not read array items")
          end
        else
          hh.fail("Expected Array[String] attribute")
        end
      else
        hh.fail("Could not read attributes")
      end
      hh.complete(true)
    } val

    let limits = otel_sdk.SpanLimits(128, 128, 5)
    let span = otel_sdk.SdkSpan(
      "test-op",
      sc,
      otel_api.SpanId.invalid(),
      otel_api.SpanKindInternal,
      otel_api.Resource,
      "test-lib",
      "1.0.0",
      limits,
      on_finish)

    span.set_attribute("str", "hello world")
    span.set_attribute("num", I64(999))
    let arr: Array[String] val = recover val ["abcdefgh"; "xy"] end
    span.set_attribute("tags", arr)
    span.finish()


class iso _TestTracerProviderForceFlushAfterShutdown is UnitTest
  fun name(): String => "SdkTracerProvider/force_flush_after_shutdown"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let provider = otel_sdk.SdkTracerProvider
    let hh: TestHelper = h

    provider.shutdown({(ok: Bool)(provider, hh) =>
      hh.assert_true(ok, "Shutdown should succeed")
      provider.force_flush({(ok: Bool)(hh) =>
        hh.assert_false(ok,
          "force_flush after shutdown should return false")
        hh.complete(true)
      } val)
    } val)
