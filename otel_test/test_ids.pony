use "pony_test"
use otel_api = "../otel_api"

class iso _TestTraceIdGenerate is UnitTest
  fun name(): String => "TraceId/generate"

  fun apply(h: TestHelper) =>
    let id = otel_api.TraceId.generate()
    h.assert_true(id.is_valid(), "Generated TraceId should be valid")
    h.assert_eq[USize](32, id.hex().size(), "TraceId hex should be 32 chars")
    h.assert_eq[USize](16, id.bytes().size(), "TraceId bytes should be 16")

    // Two generated IDs should differ (astronomically unlikely to collide)
    let id2 = otel_api.TraceId.generate()
    h.assert_true(id.ne(id2), "Two generated TraceIds should differ")


class iso _TestTraceIdHex is UnitTest
  fun name(): String => "TraceId/hex"

  fun apply(h: TestHelper) =>
    let bytes: Array[U8] val = recover val
      [0x01; 0x23; 0x45; 0x67; 0x89; 0xab; 0xcd; 0xef
       0xfe; 0xdc; 0xba; 0x98; 0x76; 0x54; 0x32; 0x10]
    end
    let id = otel_api.TraceId(bytes)
    h.assert_eq[String]("0123456789abcdeffedcba9876543210", id.hex())


class iso _TestTraceIdInvalid is UnitTest
  fun name(): String => "TraceId/invalid"

  fun apply(h: TestHelper) =>
    let id = otel_api.TraceId.invalid()
    h.assert_false(id.is_valid(), "Invalid TraceId should not be valid")
    h.assert_eq[String]("00000000000000000000000000000000", id.hex())


class iso _TestSpanIdGenerate is UnitTest
  fun name(): String => "SpanId/generate"

  fun apply(h: TestHelper) =>
    let id = otel_api.SpanId.generate()
    h.assert_true(id.is_valid(), "Generated SpanId should be valid")
    h.assert_eq[USize](16, id.hex().size(), "SpanId hex should be 16 chars")
    h.assert_eq[USize](8, id.bytes().size(), "SpanId bytes should be 8")


class iso _TestSpanIdHex is UnitTest
  fun name(): String => "SpanId/hex"

  fun apply(h: TestHelper) =>
    let bytes: Array[U8] val = recover val
      [0x01; 0x23; 0x45; 0x67; 0x89; 0xab; 0xcd; 0xef]
    end
    let id = otel_api.SpanId(bytes)
    h.assert_eq[String]("0123456789abcdef", id.hex())


class iso _TestSpanIdInvalid is UnitTest
  fun name(): String => "SpanId/invalid"

  fun apply(h: TestHelper) =>
    let id = otel_api.SpanId.invalid()
    h.assert_false(id.is_valid(), "Invalid SpanId should not be valid")
    h.assert_eq[String]("0000000000000000", id.hex())
