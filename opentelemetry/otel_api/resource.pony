class val Resource
  """
  Immutable set of attributes describing the entity producing telemetry.
  """
  let schema_url: String
  let _attributes: Array[(String, AttributeValue)] val

  new val create(
    attributes': Array[(String, AttributeValue)] val =
      recover val Array[(String, AttributeValue)] end,
    schema_url': String = "")
  =>
    _attributes = attributes'
    schema_url = schema_url'

  fun val attributes(): Array[(String, AttributeValue)] val =>
    """
    Returns the attribute key-value pairs for this resource.
    """
    _attributes

  fun val merge(other: Resource): Resource =>
    """
    Merge two resources. The other resource's attributes take precedence
    on key conflicts.
    """
    let merged = recover iso Array[(String, AttributeValue)] end
    // Add all from self that aren't overridden by other
    for (k, v) in _attributes.values() do
      var found = false
      for (ok, _) in other._attributes.values() do
        if k == ok then found = true; break end
      end
      if not found then merged.push((k, v)) end
    end
    // Add all from other
    for (k, v) in other._attributes.values() do
      merged.push((k, v))
    end
    let url = if other.schema_url != "" then other.schema_url else schema_url end
    Resource(consume merged, url)
