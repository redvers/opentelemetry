primitive SpanKindInternal
  fun string(): String iso^ => "Internal".clone()
  fun value(): U32 => 0

primitive SpanKindServer
  fun string(): String iso^ => "Server".clone()
  fun value(): U32 => 1

primitive SpanKindClient
  fun string(): String iso^ => "Client".clone()
  fun value(): U32 => 2

primitive SpanKindProducer
  fun string(): String iso^ => "Producer".clone()
  fun value(): U32 => 3

primitive SpanKindConsumer
  fun string(): String iso^ => "Consumer".clone()
  fun value(): U32 => 4

type SpanKind is
  ( SpanKindInternal
  | SpanKindServer
  | SpanKindClient
  | SpanKindProducer
  | SpanKindConsumer )
