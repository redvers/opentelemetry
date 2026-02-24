type AttributeValue is
  ( String
  | Bool
  | I64
  | F64
  | Array[String] val
  | Array[Bool] val
  | Array[I64] val
  | Array[F64] val )

type Attributes is Array[(String, AttributeValue)] val
