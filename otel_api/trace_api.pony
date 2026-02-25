trait tag TracerProvider
  """
  Entry point for creating Tracers. Implemented as an actor to allow
  shared access across actors.
  """
  be get_tracer(
    name: String,
    callback: {(Tracer val)} val,
    version: String = "",
    schema_url: String = "")
    """
    Asynchronously provides a `Tracer` for the named instrumentation scope.
    The callback receives the tracer once it is ready.
    """

  be shutdown(callback: {(Bool)} val)
    """
    Shuts down the provider, flushing any pending spans. The callback
    receives `true` if shutdown completed successfully.
    """


trait val Tracer
  """
  Creates spans. Stateless (val) so it can be shared across actors.
  Returns both a mutable Span ref and a new Context val containing
  the child span's context.
  """
  fun val start_span(
    name: String,
    parent_ctx: Context = Context,
    kind: SpanKind = SpanKindInternal,
    attributes: Array[(String, AttributeValue)] val =
      recover val Array[(String, AttributeValue)] end)
    : (Span ref, Context val)
    """
    Creates a new span with the given name. Returns the mutable `Span` and a
    child `Context` containing the new span's `SpanContext`. Pass the parent
    context to establish parent-child relationships.
    """


trait ref Span
  """
  Mutable span bound to a single actor. Add attributes, events, set status,
  then call finish() to freeze and export.
  """
  fun ref set_attribute(key: String, value: AttributeValue)
    """
    Sets a single attribute on this span. If the key already exists, its value
    is replaced.
    """

  fun ref add_event(
    name: String,
    attributes: Array[(String, AttributeValue)] val =
      recover val Array[(String, AttributeValue)] end)
    """
    Adds a timestamped event to this span with optional attributes.
    """

  fun ref set_status(code: SpanStatusCode, description: String = "")
    """
    Sets the span status. Per the OpenTelemetry spec, `SpanStatusOk` cannot be
    overridden once set. The description is only recorded for `SpanStatusError`.
    """

  fun ref update_name(name: String)
    """
    Changes the span name. Useful when the final operation name is not known
    at span creation time.
    """

  fun ref finish()
    """
    Marks the span as finished, records the end timestamp, and triggers
    export. No further modifications are allowed after this call.
    """

  fun val span_context(): SpanContext
    """
    Returns the `SpanContext` for this span.
    """

  fun ref is_recording(): Bool
    """
    Returns `true` if this span is still accepting modifications.
    """


class val SpanEvent
  """
  An immutable timestamped annotation on a span with optional attributes.
  """
  let name: String
  let timestamp: U64
  let attributes: Array[(String, AttributeValue)] val

  new val create(
    name': String,
    timestamp': U64,
    attributes': Array[(String, AttributeValue)] val =
      recover val Array[(String, AttributeValue)] end)
  =>
    name = name'
    timestamp = timestamp'
    attributes = attributes'
