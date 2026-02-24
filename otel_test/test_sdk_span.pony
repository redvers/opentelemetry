use "pony_test"
use otel_api = "../otel_api"
use otel_sdk = "../otel_sdk"

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
      match ro.status.code
      | otel_api.SpanStatusOk =>
        hh.assert_true(true)
      else
        hh.fail("Status should remain Ok after attempted Error override")
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

    span.set_status(otel_api.SpanStatusOk)
    span.set_status(otel_api.SpanStatusError, "should be ignored")
    span.finish()
