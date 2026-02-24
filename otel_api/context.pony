class val Context
  """
  Immutable context carrier. Stores the current span context and arbitrary
  key-value entries. Creating a child context returns a new Context with
  updated values, leaving the parent unchanged.
  """
  let _span_context: SpanContext
  let _entries: Array[(String, String)] val

  new val create(
    span_context': SpanContext = SpanContext.invalid(),
    entries': Array[(String, String)] val = recover val Array[(String, String)] end)
  =>
    _span_context = span_context'
    _entries = entries'

  fun val span_context(): SpanContext => _span_context

  fun val with_span_context(sc: SpanContext): Context =>
    Context(sc, _entries)

  fun val with_entry(key: String, value: String): Context =>
    let new_entries = recover iso Array[(String, String)](_entries.size() + 1) end
    for (k, v) in _entries.values() do
      if k != key then
        new_entries.push((k, v))
      end
    end
    new_entries.push((key, value))
    Context(_span_context, consume new_entries)

  fun val get_entry(key: String): (String | None) =>
    for (k, v) in _entries.values() do
      if k == key then return v end
    end
    None
