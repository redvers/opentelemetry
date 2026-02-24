use otel_api = "../otel_api"

class val ReadOnlySpan
  """
  Immutable snapshot of a completed span, safe to send across actors.
  Created by SdkSpan.finish() via the ref->val freeze pattern.
  """
  let name: String
  let span_context: otel_api.SpanContext
  let parent_span_id: otel_api.SpanId
  let kind: otel_api.SpanKind
  let start_time: U64
  let end_time: U64
  let status: otel_api.SpanStatus
  let attributes: otel_api.Attributes
  let events: Array[otel_api.SpanEvent] val
  let resource: otel_api.Resource
  let instrumentation_scope_name: String
  let instrumentation_scope_version: String

  new val create(
    name': String,
    span_context': otel_api.SpanContext,
    parent_span_id': otel_api.SpanId,
    kind': otel_api.SpanKind,
    start_time': U64,
    end_time': U64,
    status': otel_api.SpanStatus,
    attributes': otel_api.Attributes,
    events': Array[otel_api.SpanEvent] val,
    resource': otel_api.Resource,
    instrumentation_scope_name': String,
    instrumentation_scope_version': String)
  =>
    name = name'
    span_context = span_context'
    parent_span_id = parent_span_id'
    kind = kind'
    start_time = start_time'
    end_time = end_time'
    status = status'
    attributes = attributes'
    events = events'
    resource = resource'
    instrumentation_scope_name = instrumentation_scope_name'
    instrumentation_scope_version = instrumentation_scope_version'
