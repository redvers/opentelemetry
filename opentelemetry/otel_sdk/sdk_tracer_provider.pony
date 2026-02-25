use otel_api = "../otel_api"

actor SdkTracerProvider is otel_api.TracerProvider
  """
  Concrete TracerProvider that manages processors and coordinates shutdown.
  """
  let _config: TracerProviderConfig
  let _processors: Array[SpanProcessor tag]
  var _is_shutdown: Bool = false

  new create(
    config: TracerProviderConfig = TracerProviderConfig,
    processors: Array[SpanProcessor tag] val =
      recover val Array[SpanProcessor tag] end)
  =>
    _config = config
    _processors = Array[SpanProcessor tag]
    for p in processors.values() do
      _processors.push(p)
    end

  be add_processor(processor: SpanProcessor tag) =>
    """
    Registers a `SpanProcessor` to receive span lifecycle events. Ignored
    after shutdown.
    """
    if not _is_shutdown then
      _processors.push(processor)
    end

  be get_tracer(
    name: String,
    callback: {(otel_api.Tracer val)} val,
    version: String = "",
    schema_url: String = "")
  =>
    """
    Creates a new `SdkTracer` for the named instrumentation scope and passes
    it to the callback. Returns a `NoopTracer` if the provider has been shut
    down.
    """
    if _is_shutdown then
      callback(otel_api.NoopTracer)
      return
    end

    let tracer = SdkTracer(
      this,
      name,
      version,
      _config.resource,
      _config.sampler,
      _config.id_generator,
      _config.span_limits)

    callback(tracer)

  be _span_started(span: ReadOnlySpan val) =>
    if _is_shutdown then return end
    for processor in _processors.values() do
      processor.on_start(span)
    end

  be _span_ended(span: ReadOnlySpan val) =>
    if _is_shutdown then return end
    for processor in _processors.values() do
      processor.on_end(span)
    end

  be shutdown(callback: {(Bool)} val) =>
    """
    Shuts down all registered processors. The callback receives `true` if
    every processor shut down successfully.
    """
    if _is_shutdown then
      callback(true)
      return
    end
    _is_shutdown = true

    let count = _processors.size()
    if count == 0 then
      callback(true)
      return
    end

    // Track how many processors have completed shutdown
    let tracker = object tag
      var _remaining: USize = count
      var _all_ok: Bool = true
      let _callback: {(Bool)} val = callback

      be completed(ok: Bool) =>
        if not ok then _all_ok = false end
        _remaining = _remaining - 1
        if _remaining == 0 then
          _callback(_all_ok)
        end
    end

    for processor in _processors.values() do
      processor.shutdown({(ok: Bool)(tracker) => tracker.completed(ok) } val)
    end

  be force_flush(callback: {(Bool)} val) =>
    """
    Forces all registered processors to flush pending spans immediately.
    Returns `false` via the callback if the provider has been shut down.
    """
    if _is_shutdown then
      callback(false)
      return
    end
    let count = _processors.size()
    if count == 0 then
      callback(true)
      return
    end

    let tracker = object tag
      var _remaining: USize = count
      var _all_ok: Bool = true
      let _callback: {(Bool)} val = callback

      be completed(ok: Bool) =>
        if not ok then _all_ok = false end
        _remaining = _remaining - 1
        if _remaining == 0 then
          _callback(_all_ok)
        end
    end

    for processor in _processors.values() do
      processor.force_flush({(ok: Bool)(tracker) => tracker.completed(ok) } val)
    end
