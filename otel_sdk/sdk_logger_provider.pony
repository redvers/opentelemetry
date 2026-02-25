use otel_api = "../otel_api"

class val LoggerProviderConfig
  let resource: otel_api.Resource

  new val create(
    resource': otel_api.Resource = otel_api.Resource)
  =>
    resource = resource'


actor SdkLoggerProvider is otel_api.LoggerProvider
  let _config: LoggerProviderConfig
  let _processors: Array[LogRecordProcessor tag]
  var _is_shutdown: Bool = false

  new create(
    config: LoggerProviderConfig = LoggerProviderConfig,
    processors: Array[LogRecordProcessor tag] val =
      recover val Array[LogRecordProcessor tag] end)
  =>
    _config = config
    _processors = Array[LogRecordProcessor tag]
    for p in processors.values() do
      _processors.push(p)
    end

  be add_processor(processor: LogRecordProcessor tag) =>
    if not _is_shutdown then
      _processors.push(processor)
    end

  be get_logger(
    name: String,
    callback: {(otel_api.Logger val)} val,
    version: String = "",
    schema_url: String = "")
  =>
    if _is_shutdown then
      callback(otel_api.NoopLogger)
      return
    end

    let logger = SdkLogger(
      this,
      name,
      version,
      _config.resource)

    callback(logger)

  be _log_emitted(log: LogRecordData val) =>
    if _is_shutdown then return end
    for processor in _processors.values() do
      processor.on_emit(log)
    end

  be shutdown(callback: {(Bool)} val) =>
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
