use otel_api = "../otel_api"

primitive _MetricValueConvert
  """
  Converts a `MetricValue` union to `F64` for internal accumulation.
  """
  fun to_f64(value: otel_api.MetricValue): F64 =>
    match value
    | let i: I64 => i.f64()
    | let f: F64 => f
    end

class val SdkCounter is otel_api.Counter
  """
  SDK implementation of `Counter`. Rejects negative values per the OpenTelemetry
  spec and routes measurements to `SdkMeterProvider` for accumulation.
  """
  let _provider: SdkMeterProvider tag
  let _name: String
  let _description: String
  let _unit: String
  let _scope_name: String
  let _scope_version: String

  new val create(
    provider: SdkMeterProvider tag,
    name': String,
    description': String = "",
    unit': String = "",
    scope_name': String = "",
    scope_version': String = "")
  =>
    _provider = provider
    _name = name'
    _description = description'
    _unit = unit'
    _scope_name = scope_name'
    _scope_version = scope_version'

  fun val add(value: otel_api.MetricValue,
    attributes: otel_api.Attributes =
      recover val Array[(String, otel_api.AttributeValue)] end)
  =>
    // Per OTel spec: Counter rejects negative values
    let v = _MetricValueConvert.to_f64(value)
    if v < 0 then return end
    _provider._record_measurement(
      _name, otel_api.InstrumentKindCounter, v,
      attributes, _description, _unit, _scope_name, _scope_version)


class val SdkUpDownCounter is otel_api.UpDownCounter
  """
  SDK implementation of `UpDownCounter`. Accepts positive and negative values
  and routes measurements to `SdkMeterProvider` for accumulation.
  """
  let _provider: SdkMeterProvider tag
  let _name: String
  let _description: String
  let _unit: String
  let _scope_name: String
  let _scope_version: String

  new val create(
    provider: SdkMeterProvider tag,
    name': String,
    description': String = "",
    unit': String = "",
    scope_name': String = "",
    scope_version': String = "")
  =>
    _provider = provider
    _name = name'
    _description = description'
    _unit = unit'
    _scope_name = scope_name'
    _scope_version = scope_version'

  fun val add(value: otel_api.MetricValue,
    attributes: otel_api.Attributes =
      recover val Array[(String, otel_api.AttributeValue)] end)
  =>
    _provider._record_measurement(
      _name, otel_api.InstrumentKindUpDownCounter,
      _MetricValueConvert.to_f64(value),
      attributes, _description, _unit, _scope_name, _scope_version)


class val SdkHistogram is otel_api.Histogram
  """
  SDK implementation of `Histogram`. Routes recorded values to
  `SdkMeterProvider` for bucket aggregation.
  """
  let _provider: SdkMeterProvider tag
  let _name: String
  let _description: String
  let _unit: String
  let _scope_name: String
  let _scope_version: String

  new val create(
    provider: SdkMeterProvider tag,
    name': String,
    description': String = "",
    unit': String = "",
    scope_name': String = "",
    scope_version': String = "")
  =>
    _provider = provider
    _name = name'
    _description = description'
    _unit = unit'
    _scope_name = scope_name'
    _scope_version = scope_version'

  fun val record(value: otel_api.MetricValue,
    attributes: otel_api.Attributes =
      recover val Array[(String, otel_api.AttributeValue)] end)
  =>
    _provider._record_measurement(
      _name, otel_api.InstrumentKindHistogram,
      _MetricValueConvert.to_f64(value),
      attributes, _description, _unit, _scope_name, _scope_version)


class val SdkGauge is otel_api.Gauge
  """
  SDK implementation of `Gauge`. Routes the latest recorded value to
  `SdkMeterProvider`.
  """
  let _provider: SdkMeterProvider tag
  let _name: String
  let _description: String
  let _unit: String
  let _scope_name: String
  let _scope_version: String

  new val create(
    provider: SdkMeterProvider tag,
    name': String,
    description': String = "",
    unit': String = "",
    scope_name': String = "",
    scope_version': String = "")
  =>
    _provider = provider
    _name = name'
    _description = description'
    _unit = unit'
    _scope_name = scope_name'
    _scope_version = scope_version'

  fun val record(value: otel_api.MetricValue,
    attributes: otel_api.Attributes =
      recover val Array[(String, otel_api.AttributeValue)] end)
  =>
    _provider._record_measurement(
      _name, otel_api.InstrumentKindGauge,
      _MetricValueConvert.to_f64(value),
      attributes, _description, _unit, _scope_name, _scope_version)
