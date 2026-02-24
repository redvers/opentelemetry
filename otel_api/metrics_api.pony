type MetricValue is (I64 | F64)

primitive InstrumentKindCounter
primitive InstrumentKindUpDownCounter
primitive InstrumentKindHistogram
primitive InstrumentKindGauge

type InstrumentKind is
  ( InstrumentKindCounter
  | InstrumentKindUpDownCounter
  | InstrumentKindHistogram
  | InstrumentKindGauge )


trait tag MeterProvider
  be get_meter(
    name: String,
    callback: {(Meter val)} val,
    version: String = "",
    schema_url: String = "")

  be shutdown(callback: {(Bool)} val)


trait val Meter
  fun val counter(name: String, description: String = "",
    unit: String = ""): Counter val

  fun val up_down_counter(name: String, description: String = "",
    unit: String = ""): UpDownCounter val

  fun val histogram(name: String, description: String = "",
    unit: String = ""): Histogram val

  fun val gauge(name: String, description: String = "",
    unit: String = ""): Gauge val


trait val Counter
  fun val add(value: MetricValue,
    attributes: Attributes =
      recover val Array[(String, AttributeValue)] end)

trait val UpDownCounter
  fun val add(value: MetricValue,
    attributes: Attributes =
      recover val Array[(String, AttributeValue)] end)

trait val Histogram
  fun val record(value: MetricValue,
    attributes: Attributes =
      recover val Array[(String, AttributeValue)] end)

trait val Gauge
  fun val record(value: MetricValue,
    attributes: Attributes =
      recover val Array[(String, AttributeValue)] end)
