// A metric measurement value: either a 64-bit integer or a 64-bit float.
type MetricValue is (I64 | F64)

primitive InstrumentKindCounter
  """
  Identifies a monotonic sum instrument.
  """
primitive InstrumentKindUpDownCounter
  """
  Identifies a non-monotonic sum instrument that can increase or decrease.
  """
primitive InstrumentKindHistogram
  """
  Identifies a histogram instrument that records value distributions.
  """
primitive InstrumentKindGauge
  """
  Identifies a gauge instrument that records the latest value.
  """

// Union of all instrument kind primitives.
type InstrumentKind is
  ( InstrumentKindCounter
  | InstrumentKindUpDownCounter
  | InstrumentKindHistogram
  | InstrumentKindGauge )


trait tag MeterProvider
  """
  Entry point for creating `Meter` instances. Implemented as an actor to allow
  shared access across actors.
  """
  be get_meter(
    name: String,
    callback: {(Meter val)} val,
    version: String = "",
    schema_url: String = "")

  be shutdown(callback: {(Bool)} val)


trait val Meter
  """
  Creates metric instruments. Stateless (val) so it can be shared across actors.
  """
  fun val counter(name: String, description: String = "",
    unit: String = ""): Counter val
    """
    Creates a monotonic `Counter` instrument.
    """

  fun val up_down_counter(name: String, description: String = "",
    unit: String = ""): UpDownCounter val
    """
    Creates an `UpDownCounter` instrument that supports both positive and
    negative deltas.
    """

  fun val histogram(name: String, description: String = "",
    unit: String = ""): Histogram val
    """
    Creates a `Histogram` instrument for recording value distributions.
    """

  fun val gauge(name: String, description: String = "",
    unit: String = ""): Gauge val
    """
    Creates a `Gauge` instrument for recording the latest value.
    """


trait val Counter
  """
  A monotonic sum instrument. Accepts only non-negative values via `add()`.
  """
  fun val add(value: MetricValue,
    attributes: Attributes =
      recover val Array[(String, AttributeValue)] end)

trait val UpDownCounter
  """
  A non-monotonic sum instrument. Accepts positive and negative values via
  `add()`.
  """
  fun val add(value: MetricValue,
    attributes: Attributes =
      recover val Array[(String, AttributeValue)] end)

trait val Histogram
  """
  Records value distributions. Each `record()` call contributes to bucket
  counts, sum, min, and max aggregations.
  """
  fun val record(value: MetricValue,
    attributes: Attributes =
      recover val Array[(String, AttributeValue)] end)

trait val Gauge
  """
  Records the latest value of a measurement. Each `record()` call replaces
  the previous value for the same attribute set.
  """
  fun val record(value: MetricValue,
    attributes: Attributes =
      recover val Array[(String, AttributeValue)] end)
