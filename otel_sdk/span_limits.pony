class val SpanLimits
  """
  Configurable limits on span data to prevent unbounded memory growth. Defaults
  to 128 attributes, 128 events, and no value length limit. Set
  `max_attribute_value_length` to a positive value to truncate string attribute
  values.
  """
  let max_attributes: USize
  let max_events: USize
  let max_attribute_value_length: USize

  new val create(
    max_attributes': USize = 128,
    max_events': USize = 128,
    max_attribute_value_length': USize = 0)
  =>
    max_attributes = max_attributes'
    max_events = max_events'
    max_attribute_value_length = max_attribute_value_length'
