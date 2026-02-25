use @getrandom[ISize](buf: Pointer[U8] tag, buflen: USize, flags: U32)

class val TraceId
  """
  128-bit trace identifier. All-zero is invalid (represents no trace).
  """
  let _bytes: Array[U8] val

  new val create(bytes': Array[U8] val) =>
    _bytes = if bytes'.size() == 16 then bytes' else
      recover val Array[U8].init(0, 16) end
    end

  new val generate() =>
    _bytes = recover val
      let buf = Array[U8].init(0, 16)
      var retries: U32 = 0
      while (@getrandom(buf.cpointer(), 16, 0) != 16) and (retries < 10) do
        retries = retries + 1
      end
      buf
    end

  new val invalid() =>
    _bytes = recover val Array[U8].init(0, 16) end

  fun val bytes(): Array[U8] val => _bytes

  fun val is_valid(): Bool =>
    try
      var i: USize = 0
      while i < 16 do
        if _bytes(i)? != 0 then return true end
        i = i + 1
      end
    end
    false

  fun val hex(): String =>
    let s = recover iso String(32) end
    try
      var i: USize = 0
      while i < 16 do
        let b = _bytes(i)?
        s.push(_hex_digit(b >> 4))
        s.push(_hex_digit(b and 0x0F))
        i = i + 1
      end
    end
    consume s

  fun val eq(other: TraceId): Bool =>
    try
      var i: USize = 0
      while i < 16 do
        if _bytes(i)? != other._bytes(i)? then return false end
        i = i + 1
      end
      true
    else
      false
    end

  fun val ne(other: TraceId): Bool => not eq(other)

  fun tag _hex_digit(v: U8): U8 =>
    if v < 10 then '0' + v else 'a' + (v - 10) end

  fun val string(): String iso^ => hex().clone()


class val SpanId
  """
  64-bit span identifier. All-zero is invalid (represents no span).
  """
  let _bytes: Array[U8] val

  new val create(bytes': Array[U8] val) =>
    _bytes = if bytes'.size() == 8 then bytes' else
      recover val Array[U8].init(0, 8) end
    end

  new val generate() =>
    _bytes = recover val
      let buf = Array[U8].init(0, 8)
      var retries: U32 = 0
      while (@getrandom(buf.cpointer(), 8, 0) != 8) and (retries < 10) do
        retries = retries + 1
      end
      buf
    end

  new val invalid() =>
    _bytes = recover val Array[U8].init(0, 8) end

  fun val bytes(): Array[U8] val => _bytes

  fun val is_valid(): Bool =>
    try
      var i: USize = 0
      while i < 8 do
        if _bytes(i)? != 0 then return true end
        i = i + 1
      end
    end
    false

  fun val hex(): String =>
    let s = recover iso String(16) end
    try
      var i: USize = 0
      while i < 8 do
        let b = _bytes(i)?
        s.push(_hex_digit(b >> 4))
        s.push(_hex_digit(b and 0x0F))
        i = i + 1
      end
    end
    consume s

  fun val eq(other: SpanId): Bool =>
    try
      var i: USize = 0
      while i < 8 do
        if _bytes(i)? != other._bytes(i)? then return false end
        i = i + 1
      end
      true
    else
      false
    end

  fun val ne(other: SpanId): Bool => not eq(other)

  fun tag _hex_digit(v: U8): U8 =>
    if v < 10 then '0' + v else 'a' + (v - 10) end

  fun val string(): String iso^ => hex().clone()


class val SpanContext
  """
  Immutable context for a span: trace ID, span ID, trace flags, and trace state.
  """
  let trace_id: TraceId
  let span_id: SpanId
  let trace_flags: U8
  let trace_state: String
  let is_remote: Bool

  new val create(
    trace_id': TraceId,
    span_id': SpanId,
    trace_flags': U8 = 0x01,
    trace_state': String = "",
    is_remote': Bool = false)
  =>
    trace_id = trace_id'
    span_id = span_id'
    trace_flags = trace_flags'
    trace_state = trace_state'
    is_remote = is_remote'

  new val invalid() =>
    trace_id = TraceId.invalid()
    span_id = SpanId.invalid()
    trace_flags = 0
    trace_state = ""
    is_remote = false

  fun val is_valid(): Bool =>
    trace_id.is_valid() and span_id.is_valid()

  fun val is_sampled(): Bool =>
    (trace_flags and 0x01) == 0x01


primitive TraceFlags
  fun sampled(): U8 => 0x01
