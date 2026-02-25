primitive SpanStatusUnset
  """
  The default span status. Indicates the operation completed without explicit
  success or error reporting.
  """
  fun string(): String iso^ => "Unset".clone()
  fun code(): U32 => 0

primitive SpanStatusOk
  """
  Indicates the operation completed successfully. Once set, the status cannot
  be overridden.
  """
  fun string(): String iso^ => "Ok".clone()
  fun code(): U32 => 1

primitive SpanStatusError
  """
  Indicates the operation encountered an error. A description may be provided.
  """
  fun string(): String iso^ => "Error".clone()
  fun code(): U32 => 2

// Union of all span status primitives.
type SpanStatusCode is (SpanStatusUnset | SpanStatusOk | SpanStatusError)


class val SpanStatus
  """
  Immutable status of a span: a `SpanStatusCode` and an optional description.
  Per the OpenTelemetry spec, the description is only retained when the code
  is `SpanStatusError`.
  """
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
