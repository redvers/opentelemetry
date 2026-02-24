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

  be shutdown(callback: {(Bool)} val)


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


trait ref Span
  """
  Mutable span bound to a single actor. Add attributes, events, set status,
  then call finish() to freeze and export.
  """
  fun ref set_attribute(key: String, value: AttributeValue)

  fun ref add_event(
    name: String,
    attributes: Array[(String, AttributeValue)] val =
      recover val Array[(String, AttributeValue)] end)

  fun ref set_status(code: SpanStatusCode, description: String = "")

  fun ref update_name(name: String)

  fun ref finish()

  fun val span_context(): SpanContext

  fun ref is_recording(): Bool


class val SpanEvent
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
