use "format"
use otel_api = "../otel_api"

primitive SamplingDecisionDrop
  fun string(): String iso^ => "Drop".clone()

primitive SamplingDecisionRecordOnly
  fun string(): String iso^ => "RecordOnly".clone()

primitive SamplingDecisionRecordAndSample
  fun string(): String iso^ => "RecordAndSample".clone()

type SamplingDecision is
  ( SamplingDecisionDrop
  | SamplingDecisionRecordOnly
  | SamplingDecisionRecordAndSample )


class val SamplingResult
  let decision: SamplingDecision
  let trace_state: String

  new val create(
    decision': SamplingDecision,
    trace_state': String = "")
  =>
    decision = decision'
    trace_state = trace_state'


trait val Sampler
  """
  Decides whether a span should be recorded and/or sampled.
  Stateless (val) for safe sharing.
  """
  fun val should_sample(
    parent_context: otel_api.Context,
    trace_id: otel_api.TraceId,
    name: String,
    kind: otel_api.SpanKind)
    : SamplingResult

  fun val description(): String


class val AlwaysOnSampler is Sampler
  fun val should_sample(
    parent_context: otel_api.Context,
    trace_id: otel_api.TraceId,
    name: String,
    kind: otel_api.SpanKind)
    : SamplingResult
  =>
    SamplingResult(SamplingDecisionRecordAndSample)

  fun val description(): String => "AlwaysOnSampler"


class val AlwaysOffSampler is Sampler
  fun val should_sample(
    parent_context: otel_api.Context,
    trace_id: otel_api.TraceId,
    name: String,
    kind: otel_api.SpanKind)
    : SamplingResult
  =>
    SamplingResult(SamplingDecisionDrop)

  fun val description(): String => "AlwaysOffSampler"


class val TraceIdRatioSampler is Sampler
  """
  Samples a configurable fraction of traces based on trace ID.
  Uses the lower 8 bytes of the trace ID as a deterministic hash.
  """
  let _ratio: F64
  let _upper_bound: U64

  new val create(ratio: F64 = 1.0) =>
    _ratio = ratio.max(0.0).min(1.0)
    _upper_bound = (_ratio * U64.max_value().f64()).u64()

  fun val should_sample(
    parent_context: otel_api.Context,
    trace_id: otel_api.TraceId,
    name: String,
    kind: otel_api.SpanKind)
    : SamplingResult
  =>
    if _ratio >= 1.0 then
      return SamplingResult(SamplingDecisionRecordAndSample)
    end
    if _ratio <= 0.0 then
      return SamplingResult(SamplingDecisionDrop)
    end
    let id_value = _trace_id_to_u64(trace_id)
    if id_value < _upper_bound then
      SamplingResult(SamplingDecisionRecordAndSample)
    else
      SamplingResult(SamplingDecisionDrop)
    end

  fun val description(): String => "TraceIdRatioSampler{" + Format.float[F64](_ratio where prec = 15) + "}"

  fun val _trace_id_to_u64(trace_id: otel_api.TraceId): U64 =>
    """
    Extract lower 8 bytes of trace ID as a U64 for ratio comparison.
    """
    try trace_id.bytes().read_u64(8)? else 0 end
