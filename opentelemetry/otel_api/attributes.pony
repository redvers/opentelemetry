// A single attribute value. Supports the OpenTelemetry attribute value types:
// scalar String, Bool, I64, F64, and homogeneous arrays of each.
type AttributeValue is
  ( String
  | Bool
  | I64
  | F64
  | Array[String] val
  | Array[Bool] val
  | Array[I64] val
  | Array[F64] val )

// An immutable sequence of key-value attribute pairs. Keys are strings; values
// are AttributeValue unions. Used throughout the API for span attributes,
// resource attributes, metric data point labels, and log record attributes.
type Attributes is Array[(String, AttributeValue)] val
