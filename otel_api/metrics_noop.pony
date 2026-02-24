actor NoopMeterProvider is MeterProvider
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
  fun val add(value: MetricValue,
    attributes: Attributes =
      recover val Array[(String, AttributeValue)] end)
  =>
    None

class val NoopUpDownCounter is UpDownCounter
  fun val add(value: MetricValue,
    attributes: Attributes =
      recover val Array[(String, AttributeValue)] end)
  =>
    None

class val NoopHistogram is Histogram
  fun val record(value: MetricValue,
    attributes: Attributes =
      recover val Array[(String, AttributeValue)] end)
  =>
    None

class val NoopGauge is Gauge
  fun val record(value: MetricValue,
    attributes: Attributes =
      recover val Array[(String, AttributeValue)] end)
  =>
    None
