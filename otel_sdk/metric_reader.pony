use "time"

trait tag MetricReader
  be shutdown(callback: {(Bool)} val)


actor PeriodicMetricReader is MetricReader
  let _provider: SdkMeterProvider tag
  let _exporter: MetricExporter
  let _interval_nanos: U64
  let _timers: Timers
  var _is_shutdown: Bool = false
  var _timer: (Timer tag | None) = None

  new create(
    provider: SdkMeterProvider tag,
    exporter: MetricExporter,
    interval_millis: U64 = 60000)
  =>
    _provider = provider
    _exporter = exporter
    _interval_nanos = Nanos.from_millis(interval_millis)
    _timers = Timers
    _start_timer()

  be shutdown(callback: {(Bool)} val) =>
    if _is_shutdown then
      callback(true)
      return
    end
    _is_shutdown = true
    _timers.dispose()

    // Do a final collect and export before shutdown
    let exporter = _exporter
    let cb = callback
    _provider.collect({(metrics: Array[MetricData val] val)(exporter, cb) =>
      if metrics.size() > 0 then
        exporter.export_metrics(metrics, {(result: ExportResult)(cb) =>
          cb(true)
        } val)
      else
        cb(true)
      end
    } val)

  be _timer_fired() =>
    if _is_shutdown then return end
    let exporter = _exporter
    _provider.collect({(metrics: Array[MetricData val] val)(exporter) =>
      if metrics.size() > 0 then
        exporter.export_metrics(metrics, {(result: ExportResult) => None } val)
      end
    } val)
    _start_timer()

  fun ref _start_timer() =>
    let self: PeriodicMetricReader tag = this
    let notify = object iso is TimerNotify
      let _reader: PeriodicMetricReader tag = self
      fun ref apply(timer: Timer, count: U64): Bool =>
        _reader._timer_fired()
        false
    end
    let t = Timer(consume notify, _interval_nanos)
    _timer = t
    _timers(consume t)
