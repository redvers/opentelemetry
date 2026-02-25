use otel_api = "../otel_api"

class ref SdkSpan is otel_api.Span
  """
  Mutable span bound to a single actor. Collects attributes and events,
  then freezes into a ReadOnlySpan val on finish().
  """
  var _name: String
  let _span_context: otel_api.SpanContext
  let _parent_span_id: otel_api.SpanId
  let _kind: otel_api.SpanKind
  let _start_time: U64
  var _status: otel_api.SpanStatus
  let _attributes: Array[(String, otel_api.AttributeValue)]
  let _events: Array[otel_api.SpanEvent]
  let _resource: otel_api.Resource
  let _scope_name: String
  let _scope_version: String
  let _limits: SpanLimits
  let _on_finish: {(ReadOnlySpan val)} val
  var _finished: Bool = false

  new ref create(
    name': String,
    span_context': otel_api.SpanContext,
    parent_span_id': otel_api.SpanId,
    kind': otel_api.SpanKind,
    resource': otel_api.Resource,
    scope_name': String,
    scope_version': String,
    limits': SpanLimits,
    on_finish': {(ReadOnlySpan val)} val,
    initial_attributes: Array[(String, otel_api.AttributeValue)] val =
      recover val Array[(String, otel_api.AttributeValue)] end,
    start_time': U64 = 0)
  =>
    _name = name'
    _span_context = span_context'
    _parent_span_id = parent_span_id'
    _kind = kind'
    _start_time = if start_time' > 0 then start_time' else _WallClock.nanos() end
    _status = otel_api.SpanStatus
    _attributes = Array[(String, otel_api.AttributeValue)]
    _events = Array[otel_api.SpanEvent]
    _resource = resource'
    _scope_name = scope_name'
    _scope_version = scope_version'
    _limits = limits'
    _on_finish = on_finish'
    for (k, v) in initial_attributes.values() do
      if _attributes.size() < _limits.max_attributes then
        _attributes.push((k, _truncate_value(v)))
      end
    end

  fun ref set_attribute(key: String, value: otel_api.AttributeValue) =>
    if _finished then return end
    let truncated = _truncate_value(value)
    // Replace existing key if found
    try
      var i: USize = 0
      while i < _attributes.size() do
        (let k, _) = _attributes(i)?
        if k == key then
          _attributes(i)? = (key, truncated)
          return
        end
        i = i + 1
      end
    end
    if _attributes.size() < _limits.max_attributes then
      _attributes.push((key, truncated))
    end

  fun _truncate_value(value: otel_api.AttributeValue)
    : otel_api.AttributeValue
  =>
    let max = _limits.max_attribute_value_length
    if max == 0 then return value end
    match value
    | let s: String =>
      if s.size() > max then s.trim(0, max) else s end
    | let arr: Array[String] val =>
      let truncated = recover iso Array[String] end
      for item in arr.values() do
        if item.size() > max then
          truncated.push(item.trim(0, max))
        else
          truncated.push(item)
        end
      end
      consume truncated
    else
      value
    end

  fun ref add_event(
    name: String,
    attributes: Array[(String, otel_api.AttributeValue)] val =
      recover val Array[(String, otel_api.AttributeValue)] end)
  =>
    if _finished then return end
    if _events.size() < _limits.max_events then
      _events.push(otel_api.SpanEvent(name, _WallClock.nanos(), attributes))
    end

  fun ref set_status(code: otel_api.SpanStatusCode, description: String = "") =>
    if _finished then return end
    // Per OTel spec: Ok status cannot be overridden; Error can be set to Ok
    match _status.code
    | otel_api.SpanStatusOk => None
    else
      _status = otel_api.SpanStatus(code, description)
    end

  fun ref update_name(name: String) =>
    if _finished then return end
    _name = name

  fun ref finish() =>
    """
    Records the end timestamp, freezes all collected data into a `ReadOnlySpan`
    val, and invokes the on-finish callback to notify the provider. Subsequent
    calls are ignored.
    """
    if _finished then return end
    _finished = true

    let end_time = _WallClock.nanos()

    // Copy ref data to iso arrays, then consume to val.
    // Can't access ref fields inside recover, so we build iso outside.
    let attr_iso = recover iso
      Array[(String, otel_api.AttributeValue)]
    end
    for (k, v) in _attributes.values() do
      attr_iso.push((k, v))
    end
    let frozen_attrs: otel_api.Attributes = consume attr_iso

    let events_iso = recover iso Array[otel_api.SpanEvent] end
    for ev in _events.values() do
      events_iso.push(ev)
    end
    let frozen_events: Array[otel_api.SpanEvent] val = consume events_iso

    let ro = ReadOnlySpan(
      _name,
      _span_context,
      _parent_span_id,
      _kind,
      _start_time,
      end_time,
      _status,
      frozen_attrs,
      frozen_events,
      _resource,
      _scope_name,
      _scope_version)

    _on_finish(ro)

  fun val span_context(): otel_api.SpanContext => _span_context

  fun ref is_recording(): Bool => not _finished
