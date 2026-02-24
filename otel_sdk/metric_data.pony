use otel_api = "../otel_api"

primitive CumulativeTemporality

class val NumberDataPoint
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


type MetricDataKind is
  ( Array[NumberDataPoint val] val
  | Array[HistogramDataPoint val] val )


class val MetricData
  let name: String
  let description: String
  let unit: String
  let kind: otel_api.InstrumentKind
  let data: MetricDataKind

  new val create(
    name': String,
    description': String = "",
    unit': String = "",
    kind': otel_api.InstrumentKind = otel_api.InstrumentKindCounter,
    data': MetricDataKind =
      recover val Array[NumberDataPoint val] end)
  =>
    name = name'
    description = description'
    unit = unit'
    kind = kind'
    data = data'
