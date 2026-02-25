use otel_api = "../otel_api"

trait val IdGenerator
  fun val generate_trace_id(): otel_api.TraceId
  fun val generate_span_id(): otel_api.SpanId


class val RandomIdGenerator is IdGenerator
  """
  Generates random IDs using the stdlib Rand PRNG seeded by wall-clock time.
  Stateless (val) — safe to share across actors.
  """
  fun val generate_trace_id(): otel_api.TraceId =>
    otel_api.TraceId.generate()

  fun val generate_span_id(): otel_api.SpanId =>
    otel_api.SpanId.generate()
