use otel_api = "../otel_api"

primitive CumulativeTemporality
  """
  Indicates metrics are reported as cumulative sums from a fixed start time.
  """

class val NumberDataPoint
  """
  An immutable data point for sum and gauge metrics: a single numeric value
  with attributes and a time window.
  """
  let attributes: otel_api.Attributes
  let start_time_unix_nano: U64
  let time_unix_nano: U64
  let value: F64

  new val create(
    attributes': otel_api.Attributes =
      recover val Array[(String, otel_api.AttributeValue)] end,
    start_time_unix_nano': U64 = 0,
    time_unix_nano': U64 = 0,
    value': F64 = 0)
  =>
    attributes = attributes'
    start_time_unix_nano = start_time_unix_nano'
    time_unix_nano = time_unix_nano'
    value = value'


class val HistogramDataPoint
  """
  An immutable data point for histogram metrics: bucket counts, sum, count,
  min, max, and explicit bounds with attributes and a time window.
  """
  let attributes: otel_api.Attributes
  let start_time_unix_nano: U64
  let time_unix_nano: U64
  let count: U64
  let sum: F64
  let bucket_counts: Array[U64] val
  let explicit_bounds: Array[F64] val
  let min_val: F64
  let max_val: F64

  new val create(
    attributes': otel_api.Attributes =
      recover val Array[(String, otel_api.AttributeValue)] end,
    start_time_unix_nano': U64 = 0,
    time_unix_nano': U64 = 0,
    count': U64 = 0,
    sum': F64 = 0,
    bucket_counts': Array[U64] val = recover val Array[U64] end,
    explicit_bounds': Array[F64] val = recover val Array[F64] end,
    min_val': F64 = 0,
    max_val': F64 = 0)
  =>
    attributes = attributes'
    start_time_unix_nano = start_time_unix_nano'
    time_unix_nano = time_unix_nano'
    count = count'
    sum = sum'
    bucket_counts = bucket_counts'
    explicit_bounds = explicit_bounds'
    min_val = min_val'
    max_val = max_val'


// The data payload of a metric: either number data points (for sum/gauge) or
// histogram data points.
type MetricDataKind is
  ( Array[NumberDataPoint val] val
  | Array[HistogramDataPoint val] val )


class val MetricData
  """
  An immutable metric snapshot containing the instrument name, description,
  unit, kind, and collected data points. Produced by `SdkMeterProvider.collect()`
  and consumed by `MetricExporter`.
  """
  let name: String
  let description: String
  let unit: String
  let kind: otel_api.InstrumentKind
  let data: MetricDataKind
  let scope_name: String
  let scope_version: String

  new val create(
    name': String,
    description': String = "",
    unit': String = "",
    kind': otel_api.InstrumentKind = otel_api.InstrumentKindCounter,
    data': MetricDataKind =
      recover val Array[NumberDataPoint val] end,
    scope_name': String = "",
    scope_version': String = "")
  =>
    name = name'
    description = description'
    unit = unit'
    kind = kind'
    data = data'
    scope_name = scope_name'
    scope_version = scope_version'
