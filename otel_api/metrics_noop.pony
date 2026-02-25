actor NoopMeterProvider is MeterProvider
  """
  A no-op `MeterProvider` that always returns `NoopMeter`. Used as the default
  when no SDK is configured.
  """
  be get_meter(
    name: String,
    callback: {(Meter val)} val,
    version: String = "",
    schema_url: String = "")
  =>
    callback(NoopMeter)

  be shutdown(callback: {(Bool)} val) =>
    callback(true)


class val NoopMeter is Meter
  """
  A no-op `Meter` that returns no-op instrument instances. Discards all
  measurements.
  """
  fun val counter(name: String, description: String = "",
    unit: String = ""): Counter val
  =>
    NoopCounter

  fun val up_down_counter(name: String, description: String = "",
    unit: String = ""): UpDownCounter val
  =>
    NoopUpDownCounter

  fun val histogram(name: String, description: String = "",
    unit: String = ""): Histogram val
  =>
    NoopHistogram

  fun val gauge(name: String, description: String = "",
    unit: String = ""): Gauge val
  =>
    NoopGauge


class val NoopCounter is Counter
  """
  A no-op `Counter` that silently discards all values.
  """
  fun val add(value: MetricValue,
    attributes: Attributes =
      recover val Array[(String, AttributeValue)] end)
  =>
    None

class val NoopUpDownCounter is UpDownCounter
  """
  A no-op `UpDownCounter` that silently discards all values.
  """
  fun val add(value: MetricValue,
    attributes: Attributes =
      recover val Array[(String, AttributeValue)] end)
  =>
    None

class val NoopHistogram is Histogram
  """
  A no-op `Histogram` that silently discards all values.
  """
  fun val record(value: MetricValue,
    attributes: Attributes =
      recover val Array[(String, AttributeValue)] end)
  =>
    None

class val NoopGauge is Gauge
  """
  A no-op `Gauge` that silently discards all values.
  """
  fun val record(value: MetricValue,
    attributes: Attributes =
      recover val Array[(String, AttributeValue)] end)
  =>
    None
