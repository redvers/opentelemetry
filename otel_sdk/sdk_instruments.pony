use otel_api = "../otel_api"

class val SdkCounter is otel_api.Counter
  let _provider: SdkMeterProvider tag
  let _name: String
  let _description: String
  let _unit: String

  new val create(
    provider: SdkMeterProvider tag,
    name': String,
    description': String = "",
    unit': String = "")
  =>
    _provider = provider
    _name = name'
    _description = description'
    _unit = unit'

  fun val add(value: otel_api.MetricValue,
    attributes: otel_api.Attributes =
      recover val Array[(String, otel_api.AttributeValue)] end)
  =>
    // Per OTel spec: Counter rejects negative values
    let v = _to_f64(value)
    if v < 0 then return end
    _provider._record_measurement(
      _name, otel_api.InstrumentKindCounter, v,
      attributes, _description, _unit)

  fun tag _to_f64(value: otel_api.MetricValue): F64 =>
    match value
    | let i: I64 => i.f64()
    | let f: F64 => f
    end


class val SdkUpDownCounter is otel_api.UpDownCounter
  let _provider: SdkMeterProvider tag
  let _name: String
  let _description: String
  let _unit: String

  new val create(
    provider: SdkMeterProvider tag,
    name': String,
    description': String = "",
    unit': String = "")
  =>
    _provider = provider
    _name = name'
    _description = description'
    _unit = unit'

  fun val add(value: otel_api.MetricValue,
    attributes: otel_api.Attributes =
      recover val Array[(String, otel_api.AttributeValue)] end)
  =>
    _provider._record_measurement(
      _name, otel_api.InstrumentKindUpDownCounter, _to_f64(value),
      attributes, _description, _unit)

  fun tag _to_f64(value: otel_api.MetricValue): F64 =>
    match value
    | let i: I64 => i.f64()
    | let f: F64 => f
    end


class val SdkHistogram is otel_api.Histogram
  let _provider: SdkMeterProvider tag
  let _name: String
  let _description: String
  let _unit: String

  new val create(
    provider: SdkMeterProvider tag,
    name': String,
    description': String = "",
    unit': String = "")
  =>
    _provider = provider
    _name = name'
    _description = description'
    _unit = unit'

  fun val record(value: otel_api.MetricValue,
    attributes: otel_api.Attributes =
      recover val Array[(String, otel_api.AttributeValue)] end)
  =>
    _provider._record_measurement(
      _name, otel_api.InstrumentKindHistogram, _to_f64(value),
      attributes, _description, _unit)

  fun tag _to_f64(value: otel_api.MetricValue): F64 =>
    match value
    | let i: I64 => i.f64()
    | let f: F64 => f
    end


class val SdkGauge is otel_api.Gauge
  let _provider: SdkMeterProvider tag
  let _name: String
  let _description: String
  let _unit: String

  new val create(
    provider: SdkMeterProvider tag,
    name': String,
    description': String = "",
    unit': String = "")
  =>
    _provider = provider
    _name = name'
    _description = description'
    _unit = unit'

  fun val record(value: otel_api.MetricValue,
    attributes: otel_api.Attributes =
      recover val Array[(String, otel_api.AttributeValue)] end)
  =>
    _provider._record_measurement(
      _name, otel_api.InstrumentKindGauge, _to_f64(value),
      attributes, _description, _unit)

  fun tag _to_f64(value: otel_api.MetricValue): F64 =>
    match value
    | let i: I64 => i.f64()
    | let f: F64 => f
    end
