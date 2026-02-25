use otel_api = "../otel_api"

class val LogRecordData
  let timestamp: U64
  let observed_timestamp: U64
  let severity_number: U8
  let severity_text: String
  let body: otel_api.LogBody
  let attributes: otel_api.Attributes
  let trace_id: otel_api.TraceId
  let span_id: otel_api.SpanId
  let trace_flags: U8
  let resource: otel_api.Resource
  let scope_name: String
  let scope_version: String

  new val create(
    timestamp': U64,
    observed_timestamp': U64,
    severity_number': U8,
    severity_text': String,
    body': otel_api.LogBody,
    attributes': otel_api.Attributes,
    trace_id': otel_api.TraceId,
    span_id': otel_api.SpanId,
    trace_flags': U8,
    resource': otel_api.Resource,
    scope_name': String,
    scope_version': String)
  =>
    timestamp = timestamp'
    observed_timestamp = observed_timestamp'
    severity_number = severity_number'
    severity_text = severity_text'
    body = body'
    attributes = attributes'
    trace_id = trace_id'
    span_id = span_id'
    trace_flags = trace_flags'
    resource = resource'
    scope_name = scope_name'
    scope_version = scope_version'
