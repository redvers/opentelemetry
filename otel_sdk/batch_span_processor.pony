use "time"
use "collections"

actor BatchSpanProcessor is SpanProcessor
  """
  Batches spans and exports them periodically or when the batch reaches
  a size threshold. Uses Pony's Timers for scheduling.
  """
  let _exporter: SpanExporter
  let _max_batch_size: USize
  let _schedule_delay_nanos: U64
  let _timers: Timers
  var _batch: Array[ReadOnlySpan val]
  var _is_shutdown: Bool = false
  var _timer: (Timer tag | None) = None

  new create(
    exporter: SpanExporter,
    max_batch_size: USize = 512,
    schedule_delay_millis: U64 = 5000)
  =>
    _exporter = exporter
    _max_batch_size = max_batch_size
    _schedule_delay_nanos = Nanos.from_millis(schedule_delay_millis)
    _timers = Timers
    _batch = Array[ReadOnlySpan val]
    _start_timer()

  be on_start(span: ReadOnlySpan val) =>
    None

  be on_end(span: ReadOnlySpan val) =>
    if _is_shutdown then return end
    _batch.push(span)
    if _batch.size() >= _max_batch_size then
      _flush()
    end

  be shutdown(callback: {(Bool)} val) =>
    _is_shutdown = true
    _flush()
    _timers.dispose()
    _exporter.shutdown(callback)

  be force_flush(callback: {(Bool)} val) =>
    _flush()
    callback(true)

  be _timer_fired() =>
    if _is_shutdown then return end
    _flush()
    _start_timer()

  fun ref _flush() =>
    if _batch.size() == 0 then return end
    let arr = recover iso Array[ReadOnlySpan val] end
    for span in _batch.values() do
      arr.push(span)
    end
    let to_export: Array[ReadOnlySpan val] val = consume arr
    _batch = Array[ReadOnlySpan val]
    _exporter.export_spans(to_export, {(result: ExportResult) => None })

  fun ref _start_timer() =>
    let self: BatchSpanProcessor tag = this
    let notify = object iso is TimerNotify
      let _proc: BatchSpanProcessor tag = self
      fun ref apply(timer: Timer, count: U64): Bool =>
        _proc._timer_fired()
        false
    end
    let t = Timer(consume notify, _schedule_delay_nanos)
    _timer = t
    _timers(consume t)
