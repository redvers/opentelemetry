actor NoopTracerProvider is TracerProvider
  """
  A no-op `TracerProvider` that always returns `NoopTracer`. Used as the
  default when no SDK is configured.
  """
  be get_tracer(
    name: String,
    callback: {(Tracer val)} val,
    version: String = "",
    schema_url: String = "")
  =>
    callback(NoopTracer)

  be shutdown(callback: {(Bool)} val) =>
    callback(true)


class val NoopTracer is Tracer
  """
  A no-op `Tracer` that returns `NoopSpan` instances. Discards all telemetry.
  """
  fun val start_span(
    name: String,
    parent_ctx: Context = Context,
    kind: SpanKind = SpanKindInternal,
    attributes: Array[(String, AttributeValue)] val =
      recover val Array[(String, AttributeValue)] end)
    : (Span ref, Context val)
  =>
    let span = NoopSpan
    (span, parent_ctx)


class ref NoopSpan is Span
  """
  A no-op `Span` that silently ignores all attribute, event, and status
  operations. Always reports `is_recording() == false`.
  """
  let _span_context: SpanContext

  new ref create() =>
    _span_context = SpanContext.invalid()

  fun ref set_attribute(key: String, value: AttributeValue) => None
  fun ref add_event(
    name: String,
    attributes: Array[(String, AttributeValue)] val =
      recover val Array[(String, AttributeValue)] end) => None
  fun ref set_status(code: SpanStatusCode, description: String = "") => None
  fun ref update_name(name: String) => None
  fun ref finish() => None
  fun val span_context(): SpanContext => _span_context
  fun ref is_recording(): Bool => false
