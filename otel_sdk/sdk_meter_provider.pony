use "collections"
use "time"
use otel_api = "../otel_api"


class ref _SumAccumulator
  var sum: F64 = 0
  let monotonic: Bool

  new ref create(monotonic': Bool) =>
    monotonic = monotonic'

  fun ref record(value: F64) =>
    sum = sum + value


class ref _HistogramAccumulator
  let bounds: Array[F64] val
  let bucket_counts: Array[U64]
  var count: U64 = 0
  var sum: F64 = 0
  var min_val: F64 = F64.max_value()
  var max_val: F64 = F64.min_value()

  new ref create(
    bounds': Array[F64] val =
      recover val [0; 5; 10; 25; 50; 75; 100; 250; 500; 750; 1000] end)
  =>
    bounds = bounds'
    bucket_counts = Array[U64].init(0, bounds.size() + 1)

  fun ref record(value: F64) =>
    count = count + 1
    sum = sum + value
    if value < min_val then min_val = value end
    if value > max_val then max_val = value end

    // Find the bucket for this value
    var i: USize = 0
    try
      while i < bounds.size() do
        if value <= bounds(i)? then
          bucket_counts(i)? = bucket_counts(i)? + 1
          return
        end
        i = i + 1
      end
      // Overflow bucket (last)
      bucket_counts(bounds.size())? = bucket_counts(bounds.size())? + 1
    end


class ref _GaugeAccumulator
  var value: F64 = 0

  new ref create() => None

  fun ref record(value': F64) =>
    value = value'


class ref _InstrumentState
  let description: String
  let unit: String
  let kind: otel_api.InstrumentKind

  // Keyed by serialized attributes
  let sum_accumulators: Map[String, _SumAccumulator]
  let histogram_accumulators: Map[String, _HistogramAccumulator]
  let gauge_accumulators: Map[String, _GaugeAccumulator]

  // Keep original attributes for each key so we can emit data points
  let attributes_by_key: Map[String, otel_api.Attributes]

  new ref create(
    description': String,
    unit': String,
    kind': otel_api.InstrumentKind)
  =>
    description = description'
    unit = unit'
    kind = kind'
    sum_accumulators = Map[String, _SumAccumulator]
    histogram_accumulators = Map[String, _HistogramAccumulator]
    gauge_accumulators = Map[String, _GaugeAccumulator]
    attributes_by_key = Map[String, otel_api.Attributes]


actor SdkMeterProvider is otel_api.MeterProvider
  let _instruments: Map[String, _InstrumentState]
  var _start_time_nanos: U64
  var _is_shutdown: Bool = false

  new create() =>
    _instruments = Map[String, _InstrumentState]
    _start_time_nanos = _wall_nanos()

  be get_meter(
    name: String,
    callback: {(otel_api.Meter val)} val,
    version: String = "",
    schema_url: String = "")
  =>
    if _is_shutdown then
      callback(otel_api.NoopMeter)
      return
    end
    let meter = SdkMeter(this, name, version)
    callback(meter)

  be _record_measurement(
    instrument_name: String,
    kind: otel_api.InstrumentKind,
    value: F64,
    attributes: otel_api.Attributes,
    description: String,
    unit: String)
  =>
    if _is_shutdown then return end

    let state = try
      _instruments(instrument_name)?
    else
      let s = _InstrumentState(description, unit, kind)
      _instruments(instrument_name) = s
      s
    end

    // Reject measurements whose kind doesn't match the registered instrument
    if not _same_kind(state.kind, kind) then return end

    let attr_key = _serialize_attributes(attributes)
    if not state.attributes_by_key.contains(attr_key) then
      state.attributes_by_key(attr_key) = attributes
    end

    match kind
    | otel_api.InstrumentKindCounter =>
      let acc = try
        state.sum_accumulators(attr_key)?
      else
        let a = _SumAccumulator(true)
        state.sum_accumulators(attr_key) = a
        a
      end
      acc.record(value)

    | otel_api.InstrumentKindUpDownCounter =>
      let acc = try
        state.sum_accumulators(attr_key)?
      else
        let a = _SumAccumulator(false)
        state.sum_accumulators(attr_key) = a
        a
      end
      acc.record(value)

    | otel_api.InstrumentKindHistogram =>
      let acc = try
        state.histogram_accumulators(attr_key)?
      else
        let a = _HistogramAccumulator
        state.histogram_accumulators(attr_key) = a
        a
      end
      acc.record(value)

    | otel_api.InstrumentKindGauge =>
      let acc = try
        state.gauge_accumulators(attr_key)?
      else
        let a = _GaugeAccumulator
        state.gauge_accumulators(attr_key) = a
        a
      end
      acc.record(value)
    end

  be collect(callback: {(Array[MetricData val] val)} val) =>
    let now = _wall_nanos()
    let results = recover iso Array[MetricData val] end

    for (name, state) in _instruments.pairs() do
      match state.kind
      | otel_api.InstrumentKindCounter =>
        let points = recover iso Array[NumberDataPoint val] end
        for (attr_key, acc) in state.sum_accumulators.pairs() do
          let attrs = try state.attributes_by_key(attr_key)? else
            recover val Array[(String, otel_api.AttributeValue)] end
          end
          points.push(NumberDataPoint(
            attrs, _start_time_nanos, now, acc.sum))
        end
        results.push(MetricData(
          name, state.description, state.unit,
          otel_api.InstrumentKindCounter, consume points))

      | otel_api.InstrumentKindUpDownCounter =>
        let points = recover iso Array[NumberDataPoint val] end
        for (attr_key, acc) in state.sum_accumulators.pairs() do
          let attrs = try state.attributes_by_key(attr_key)? else
            recover val Array[(String, otel_api.AttributeValue)] end
          end
          points.push(NumberDataPoint(
            attrs, _start_time_nanos, now, acc.sum))
        end
        results.push(MetricData(
          name, state.description, state.unit,
          otel_api.InstrumentKindUpDownCounter, consume points))

      | otel_api.InstrumentKindHistogram =>
        let points = recover iso Array[HistogramDataPoint val] end
        for (attr_key, acc) in state.histogram_accumulators.pairs() do
          let attrs = try state.attributes_by_key(attr_key)? else
            recover val Array[(String, otel_api.AttributeValue)] end
          end
          let frozen_counts = recover iso Array[U64] end
          for c in acc.bucket_counts.values() do
            frozen_counts.push(c)
          end
          points.push(HistogramDataPoint(
            attrs, _start_time_nanos, now,
            acc.count, acc.sum,
            consume frozen_counts, acc.bounds,
            acc.min_val, acc.max_val))
        end
        results.push(MetricData(
          name, state.description, state.unit,
          otel_api.InstrumentKindHistogram, consume points))

      | otel_api.InstrumentKindGauge =>
        let points = recover iso Array[NumberDataPoint val] end
        for (attr_key, acc) in state.gauge_accumulators.pairs() do
          let attrs = try state.attributes_by_key(attr_key)? else
            recover val Array[(String, otel_api.AttributeValue)] end
          end
          points.push(NumberDataPoint(
            attrs, _start_time_nanos, now, acc.value))
        end
        results.push(MetricData(
          name, state.description, state.unit,
          otel_api.InstrumentKindGauge, consume points))
      end
    end

    callback(consume results)

  be shutdown(callback: {(Bool)} val) =>
    if _is_shutdown then
      callback(true)
      return
    end
    _is_shutdown = true
    callback(true)

  fun tag _same_kind(a: otel_api.InstrumentKind, b: otel_api.InstrumentKind)
    : Bool
  =>
    match (a, b)
    | (otel_api.InstrumentKindCounter, otel_api.InstrumentKindCounter) => true
    | (otel_api.InstrumentKindUpDownCounter, otel_api.InstrumentKindUpDownCounter) => true
    | (otel_api.InstrumentKindHistogram, otel_api.InstrumentKindHistogram) => true
    | (otel_api.InstrumentKindGauge, otel_api.InstrumentKindGauge) => true
    else false
    end

  fun tag _serialize_attributes(attrs: otel_api.Attributes): String =>
    if attrs.size() == 0 then return "" end
    let parts = recover iso String end
    for (k, v) in attrs.values() do
      if parts.size() > 0 then parts.append(",") end
      parts.append(k)
      parts.append("=")
      match v
      | let s: String => parts.append(s)
      | let b: Bool => parts.append(b.string())
      | let i: I64 => parts.append(i.string())
      | let f: F64 => parts.append(f.string())
      | let arr: Array[String] val =>
        parts.append("[")
        var first = true
        for item in arr.values() do
          if not first then parts.append(";") end
          parts.append(item)
          first = false
        end
        parts.append("]")
      | let arr: Array[Bool] val =>
        parts.append("[")
        var first = true
        for item in arr.values() do
          if not first then parts.append(";") end
          parts.append(item.string())
          first = false
        end
        parts.append("]")
      | let arr: Array[I64] val =>
        parts.append("[")
        var first = true
        for item in arr.values() do
          if not first then parts.append(";") end
          parts.append(item.string())
          first = false
        end
        parts.append("]")
      | let arr: Array[F64] val =>
        parts.append("[")
        var first = true
        for item in arr.values() do
          if not first then parts.append(";") end
          parts.append(item.string())
          first = false
        end
        parts.append("]")
      end
    end
    consume parts

  fun tag _wall_nanos(): U64 =>
    (let sec, let nsec) = Time.now()
    ((sec.u64() * 1_000_000_000) + nsec.u64())
