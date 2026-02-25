use otel_api = "../otel_api"

class val SdkTracer is otel_api.Tracer
  """
  Creates SdkSpan instances. Stateless (val) — holds a tag reference to the
  provider actor for span reporting, plus immutable config.
  """
  let _provider: SdkTracerProvider tag
  let _name: String
  let _version: String
  let _resource: otel_api.Resource
  let _sampler: Sampler
  let _id_generator: IdGenerator
  let _span_limits: SpanLimits

  new val create(
    provider: SdkTracerProvider tag,
    name': String,
    version': String,
    resource': otel_api.Resource,
    sampler': Sampler,
    id_generator': IdGenerator,
    span_limits': SpanLimits)
  =>
    _provider = provider
    _name = name'
    _version = version'
    _resource = resource'
    _sampler = sampler'
    _id_generator = id_generator'
    _span_limits = span_limits'

  fun val start_span(
    name: String,
    parent_ctx: otel_api.Context = otel_api.Context,
    kind: otel_api.SpanKind = otel_api.SpanKindInternal,
    attributes: Array[(String, otel_api.AttributeValue)] val =
      recover val Array[(String, otel_api.AttributeValue)] end)
    : (otel_api.Span ref, otel_api.Context val)
  =>
    let parent_sc = parent_ctx.span_context()

    // Determine trace ID: reuse parent's if valid, otherwise generate new
    let trace_id = if parent_sc.is_valid() then
      parent_sc.trace_id
    else
      _id_generator.generate_trace_id()
    end

    let span_id = _id_generator.generate_span_id()

    // Sample decision
    let sampling = _sampler.should_sample(parent_ctx, trace_id, name, kind)

    match sampling.decision
    | SamplingDecisionDrop =>
      // Return a noop span with invalid context
      let noop = otel_api.NoopSpan
      (noop, parent_ctx)
    else
      // Record (and possibly sample)
      let trace_flags: U8 = match sampling.decision
      | SamplingDecisionRecordAndSample => otel_api.TraceFlags.sampled()
      else 0
      end

      let sc = otel_api.SpanContext(trace_id, span_id, trace_flags,
        sampling.trace_state)
      let child_ctx = parent_ctx.with_span_context(sc)

      let parent_span_id = if parent_sc.is_valid() then
        parent_sc.span_id
      else
        otel_api.SpanId.invalid()
      end

      let provider: SdkTracerProvider tag = _provider
      let on_finish = {(ro: ReadOnlySpan val) =>
        provider._span_ended(ro)
      } val

      let span = SdkSpan(
        name,
        sc,
        parent_span_id,
        kind,
        _resource,
        _name,
        _version,
        _span_limits,
        on_finish,
        attributes)

      (span, child_ctx)
    end
