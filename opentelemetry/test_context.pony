use "pony_test"
use otel_api = "otel_api"

class iso _TestSpanContextValid is UnitTest
  fun name(): String => "SpanContext/valid"

  fun apply(h: TestHelper) =>
    let trace_id = otel_api.TraceId.generate()
    let span_id = otel_api.SpanId.generate()
    let sc = otel_api.SpanContext(trace_id, span_id)
    h.assert_true(sc.is_valid(), "SpanContext with valid IDs should be valid")


class iso _TestSpanContextInvalid is UnitTest
  fun name(): String => "SpanContext/invalid"

  fun apply(h: TestHelper) =>
    let sc = otel_api.SpanContext.invalid()
    h.assert_false(sc.is_valid(), "Invalid SpanContext should not be valid")


class iso _TestSpanContextSampled is UnitTest
  fun name(): String => "SpanContext/sampled"

  fun apply(h: TestHelper) =>
    let trace_id = otel_api.TraceId.generate()
    let span_id = otel_api.SpanId.generate()

    let sampled = otel_api.SpanContext(trace_id, span_id, 0x01)
    h.assert_true(sampled.is_sampled(), "Flag 0x01 should be sampled")

    let not_sampled = otel_api.SpanContext(trace_id, span_id, 0x00)
    h.assert_false(not_sampled.is_sampled(), "Flag 0x00 should not be sampled")


class iso _TestContextImmutability is UnitTest
  fun name(): String => "Context/immutability"

  fun apply(h: TestHelper) =>
    let ctx = otel_api.Context
    let trace_id = otel_api.TraceId.generate()
    let span_id = otel_api.SpanId.generate()
    let sc = otel_api.SpanContext(trace_id, span_id)

    // Creating a child context should not modify the parent
    let child = ctx.with_span_context(sc)
    h.assert_false(ctx.span_context().is_valid(),
      "Parent context should remain unchanged")
    h.assert_true(child.span_context().is_valid(),
      "Child context should have valid span context")


class iso _TestContextWithEntry is UnitTest
  fun name(): String => "Context/with_entry"

  fun apply(h: TestHelper) =>
    let ctx = otel_api.Context
    let ctx2 = ctx.with_entry("key1", "value1")
    let ctx3 = ctx2.with_entry("key2", "value2")

    // Original context should not have entries
    match ctx.get_entry("key1")
    | None => h.assert_true(true)
    else h.fail("Parent context should not have key1")
    end

    // ctx2 should have key1 but not key2
    match ctx2.get_entry("key1")
    | let v: String => h.assert_eq[String]("value1", v)
    else h.fail("ctx2 should have key1")
    end

    match ctx2.get_entry("key2")
    | None => h.assert_true(true)
    else h.fail("ctx2 should not have key2")
    end

    // ctx3 should have both
    match ctx3.get_entry("key1")
    | let v: String => h.assert_eq[String]("value1", v)
    else h.fail("ctx3 should have key1")
    end

    match ctx3.get_entry("key2")
    | let v: String => h.assert_eq[String]("value2", v)
    else h.fail("ctx3 should have key2")
    end
