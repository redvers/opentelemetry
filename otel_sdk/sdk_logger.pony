use otel_api = "../otel_api"

class val SdkLogger is otel_api.Logger
  let _provider: SdkLoggerProvider tag
  let _name: String
  let _version: String
  let _resource: otel_api.Resource

  new val create(
    provider: SdkLoggerProvider tag,
    name': String,
    version': String,
    resource': otel_api.Resource)
  =>
    _provider = provider
    _name = name'
    _version = version'
    _resource = resource'

  fun val emit(
    body: otel_api.LogBody = None,
    severity_number: U8 = 0,
    severity_text: String = "",
    attributes: otel_api.Attributes =
      recover val Array[(String, otel_api.AttributeValue)] end,
    timestamp: U64 = 0,
    observed_timestamp: U64 = 0,
    context: otel_api.Context = otel_api.Context)
  =>
    let now = _WallClock.nanos()
    let ts = if timestamp != 0 then timestamp else now end
    let obs_ts = if observed_timestamp != 0 then observed_timestamp else now end

    let sc = context.span_context()
    let trace_id = sc.trace_id
    let span_id = sc.span_id
    let trace_flags = sc.trace_flags

    let log = LogRecordData(
      ts,
      obs_ts,
      severity_number,
      severity_text,
      body,
      attributes,
      trace_id,
      span_id,
      trace_flags,
      _resource,
      _name,
      _version)

    _provider._log_emitted(log)
