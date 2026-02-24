primitive SpanStatusUnset
  fun string(): String iso^ => "Unset".clone()
  fun code(): U32 => 0

primitive SpanStatusOk
  fun string(): String iso^ => "Ok".clone()
  fun code(): U32 => 1

primitive SpanStatusError
  fun string(): String iso^ => "Error".clone()
  fun code(): U32 => 2

type SpanStatusCode is (SpanStatusUnset | SpanStatusOk | SpanStatusError)


class val SpanStatus
  let code: SpanStatusCode
  let description: String

  new val create(
    code': SpanStatusCode = SpanStatusUnset,
    description': String = "")
  =>
    code = code'
    // Per OTel spec: description is only used with Error status
    description = match code'
    | SpanStatusError => description'
    else ""
    end
