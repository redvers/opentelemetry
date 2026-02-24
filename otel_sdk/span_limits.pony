class val SpanLimits
  """
  Configurable limits on span data to prevent unbounded memory growth.
  """
  let max_attributes: USize
  let max_events: USize
  let max_links: USize
  let max_attribute_value_length: USize

  new val create(
    max_attributes': USize = 128,
    max_events': USize = 128,
    max_links': USize = 128,
    max_attribute_value_length': USize = 0)
  =>
    max_attributes = max_attributes'
    max_events = max_events'
    max_links = max_links'
    max_attribute_value_length = max_attribute_value_length'
