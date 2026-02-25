use otel_api = "../otel_api"

trait val IdGenerator
  """
  Generates trace and span identifiers. Stateless (val) for safe sharing
  across actors.
  """
  fun val generate_trace_id(): otel_api.TraceId
    """
    Returns a new 128-bit trace identifier.
    """
  fun val generate_span_id(): otel_api.SpanId
    """
    Returns a new 64-bit span identifier.
    """


class val RandomIdGenerator is IdGenerator
  """
  Generates random IDs using the stdlib Rand PRNG seeded by wall-clock time.
  Stateless (val) — safe to share across actors.
  """
  fun val generate_trace_id(): otel_api.TraceId =>
    otel_api.TraceId.generate()

  fun val generate_span_id(): otel_api.SpanId =>
    otel_api.SpanId.generate()
