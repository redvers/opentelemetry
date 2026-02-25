use "time"

actor BatchLogRecordProcessor is LogRecordProcessor
  """
  Batches log records and exports them periodically or when the batch reaches
  a size threshold. Uses Pony's `Timers` for scheduling. Defaults to a batch
  size of 512 and a 5-second delay.
  """
  let _exporter: LogRecordExporter
  let _max_batch_size: USize
  let _schedule_delay_nanos: U64
  let _timers: Timers
  var _batch: Array[LogRecordData val]
  var _is_shutdown: Bool = false
  var _timer: (Timer tag | None) = None

  new create(
    exporter: LogRecordExporter,
    max_batch_size: USize = 512,
    schedule_delay_millis: U64 = 5000)
  =>
    _exporter = exporter
    _max_batch_size = max_batch_size
    _schedule_delay_nanos = Nanos.from_millis(schedule_delay_millis)
    _timers = Timers
    _batch = Array[LogRecordData val]
    _start_timer()

  be on_emit(log: LogRecordData val) =>
    if _is_shutdown then return end
    _batch.push(log)
    if _batch.size() >= _max_batch_size then
      _flush(None)
    end

  be shutdown(callback: {(Bool)} val) =>
    _is_shutdown = true
    _timers.dispose()
    let exporter = _exporter
    if _batch.size() == 0 then
      exporter.shutdown(callback)
    else
      _flush(
        {(result: ExportResult)(exporter, callback) =>
          exporter.shutdown(callback)
        } val)
    end

  be force_flush(callback: {(Bool)} val) =>
    if _batch.size() == 0 then
      callback(true)
    else
      _flush(
        {(result: ExportResult)(callback) =>
          match result
          | ExportSuccess => callback(true)
          | ExportFailure => callback(false)
          end
        } val)
    end

  be _timer_fired() =>
    if _is_shutdown then return end
    _flush(None)
    _start_timer()

  fun ref _flush(on_complete: ({(ExportResult)} val | None)) =>
    if _batch.size() == 0 then
      match on_complete
      | let cb: {(ExportResult)} val => cb(ExportSuccess)
      end
      return
    end
    let arr = recover iso Array[LogRecordData val] end
    for log in _batch.values() do
      arr.push(log)
    end
    let to_export: Array[LogRecordData val] val = consume arr
    _batch = Array[LogRecordData val]
    match on_complete
    | let cb: {(ExportResult)} val =>
      _exporter.export_logs(to_export, cb)
    | None =>
      _exporter.export_logs(to_export, {(result: ExportResult) => None})
    end

  fun ref _start_timer() =>
    let self: BatchLogRecordProcessor tag = this
    let notify = object iso is TimerNotify
      let _proc: BatchLogRecordProcessor tag = self
      fun ref apply(timer: Timer, count: U64): Bool =>
        _proc._timer_fired()
        false
    end
    let t = Timer(consume notify, _schedule_delay_nanos)
    _timer = t
    _timers(consume t)
