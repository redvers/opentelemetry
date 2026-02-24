use "pony_test"
use otel_api = "../otel_api"

class iso _TestSpanStatusDescription is UnitTest
  fun name(): String => "SpanStatus/description"

  fun apply(h: TestHelper) =>
    // Description is only preserved for Error status
    let error_status = otel_api.SpanStatus(otel_api.SpanStatusError, "something broke")
    h.assert_eq[String]("something broke", error_status.description)

    // Description is dropped for Ok status per OTel spec
    let ok_status = otel_api.SpanStatus(otel_api.SpanStatusOk, "this should be ignored")
    h.assert_eq[String]("", ok_status.description)

    // Description is dropped for Unset status
    let unset_status = otel_api.SpanStatus(otel_api.SpanStatusUnset, "this too")
    h.assert_eq[String]("", unset_status.description)
