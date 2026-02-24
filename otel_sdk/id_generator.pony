use otel_api = "../otel_api"

use @getrandom[ISize](buf: Pointer[U8] tag, buflen: USize, flags: U32)

trait val IdGenerator
  fun val generate_trace_id(): otel_api.TraceId
  fun val generate_span_id(): otel_api.SpanId


class val RandomIdGenerator is IdGenerator
  """
  Generates random IDs using OS cryptographic random via getrandom(2).
  Stateless (val) — safe to share across actors.
  """
  fun val generate_trace_id(): otel_api.TraceId =>
    otel_api.TraceId.generate()

  fun val generate_span_id(): otel_api.SpanId =>
    otel_api.SpanId.generate()
