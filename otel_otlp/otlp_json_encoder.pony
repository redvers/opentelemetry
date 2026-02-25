use json = "../_corral/github_com_ponylang_json/json"
use "collections"
use otel_api = "../otel_api"
use otel_sdk = "../otel_sdk"

primitive OtlpJsonEncoder
  """
  Stateless encoder: converts ReadOnlySpan vals into OTLP JSON format.
  Produces the ExportTraceServiceRequest JSON structure.
  """
  fun encode_spans(spans: Array[otel_sdk.ReadOnlySpan val] val): String =>
    // Group spans by (resource, scope) for OTLP structure
    let root = json.JsonObject

    // Build resourceSpans array
    let resource_spans_arr = json.JsonArray
    let grouped = _group_by_resource_and_scope(spans)

    for (resource_key, scope_map) in grouped.pairs() do
      let rs_obj = json.JsonObject

      // Find the resource from first span in any scope
      try
        for (_, scope_spans) in scope_map.pairs() do
          let first_span = scope_spans(0)?
          rs_obj.data("resource") = _encode_resource(first_span.resource)
          break
        end
      end

      // Build scopeSpans array
      let scope_spans_arr = json.JsonArray
      for (scope_key, scope_span_list) in scope_map.pairs() do
        let ss_obj = json.JsonObject

        // Encode scope from first span
        try
          let first = scope_span_list(0)?
          let scope_obj = json.JsonObject
          scope_obj.data("name") = first.instrumentation_scope_name
          if first.instrumentation_scope_version.size() > 0 then
            scope_obj.data("version") = first.instrumentation_scope_version
          end
          ss_obj.data("scope") = scope_obj
        end

        // Encode spans array
        let spans_arr = json.JsonArray
        for span in scope_span_list.values() do
          spans_arr.data.push(_encode_span(span))
        end
        ss_obj.data("spans") = spans_arr
        scope_spans_arr.data.push(ss_obj)
      end

      rs_obj.data("scopeSpans") = scope_spans_arr
      resource_spans_arr.data.push(rs_obj)
    end

    root.data("resourceSpans") = resource_spans_arr
    root.string()

  fun _group_by_resource_and_scope(
    spans: Array[otel_sdk.ReadOnlySpan val] val)
    : Map[String, Map[String, Array[otel_sdk.ReadOnlySpan val]]]
  =>
    """
    Group spans by resource identity and scope key for OTLP structure.
    Resource identity includes both schema_url and all attributes.
    """
    let grouped = Map[String, Map[String, Array[otel_sdk.ReadOnlySpan val]]]
    for span in spans.values() do
      let resource_key: String val = _resource_key(span.resource)
      let scope_key: String val =
        recover val
          let s = String
          s.append(span.instrumentation_scope_name)
          s.append(":")
          s.append(span.instrumentation_scope_version)
          s
        end

      let scope_map = try
        grouped(resource_key)?
      else
        let m = Map[String, Array[otel_sdk.ReadOnlySpan val]]
        grouped(resource_key) = m
        m
      end

      let span_list = try
        scope_map(scope_key)?
      else
        let a = Array[otel_sdk.ReadOnlySpan val]
        scope_map(scope_key) = a
        a
      end

      span_list.push(span)
    end
    grouped

  fun _resource_key(resource: otel_api.Resource): String val =>
    recover val
      let s = String
      s.append(resource.schema_url)
      s.append("|")
      for (k, v) in resource.attributes().values() do
        s.append(k)
        s.append("=")
        match v
        | let sv: String => s.append(sv)
        | let bv: Bool => s.append(bv.string())
        | let iv: I64 => s.append(iv.string())
        | let fv: F64 => s.append(fv.string())
        else
          s.append("?")
        end
        s.append(",")
      end
      s
    end

  fun _encode_resource(resource: otel_api.Resource): json.JsonObject =>
    let obj = json.JsonObject
    obj.data("attributes") = _encode_attributes(resource.attributes())
    obj

  fun _encode_span(span: otel_sdk.ReadOnlySpan val): json.JsonObject =>
    let obj = json.JsonObject
    obj.data("traceId") = span.span_context.trace_id.hex()
    obj.data("spanId") = span.span_context.span_id.hex()

    if span.parent_span_id.is_valid() then
      obj.data("parentSpanId") = span.parent_span_id.hex()
    end

    obj.data("name") = span.name
    obj.data("kind") = _span_kind_value(span.kind).i64()
    obj.data("startTimeUnixNano") = span.start_time.i64()
    obj.data("endTimeUnixNano") = span.end_time.i64()

    if span.attributes.size() > 0 then
      obj.data("attributes") = _encode_attributes(span.attributes)
    end

    if span.events.size() > 0 then
      let events_arr = json.JsonArray
      for event in span.events.values() do
        events_arr.data.push(_encode_event(event))
      end
      obj.data("events") = events_arr
    end

    let status_obj = json.JsonObject
    status_obj.data("code") = span.status.code.code().i64()
    if span.status.description.size() > 0 then
      status_obj.data("message") = span.status.description
    end
    obj.data("status") = status_obj

    obj

  fun _encode_event(event: otel_api.SpanEvent): json.JsonObject =>
    let obj = json.JsonObject
    obj.data("name") = event.name
    obj.data("timeUnixNano") = event.timestamp.i64()
    if event.attributes.size() > 0 then
      obj.data("attributes") = _encode_attributes(event.attributes)
    end
    obj

  fun _encode_attributes(
    attrs: Array[(String, otel_api.AttributeValue)] val)
    : json.JsonArray
  =>
    let arr = json.JsonArray
    for (key, value) in attrs.values() do
      let attr_obj = json.JsonObject
      attr_obj.data("key") = key
      attr_obj.data("value") = _encode_attribute_value(value)
      arr.data.push(attr_obj)
    end
    arr

  fun _encode_attribute_value(value: otel_api.AttributeValue): json.JsonObject =>
    let obj = json.JsonObject
    match value
    | let s: String => obj.data("stringValue") = s
    | let b: Bool => obj.data("boolValue") = b
    | let i: I64 => obj.data("intValue") = i
    | let f: F64 => obj.data("doubleValue") = f
    | let arr: Array[String] val =>
      let values = json.JsonObject
      let jarr = json.JsonArray
      for v in arr.values() do
        let inner = json.JsonObject
        inner.data("stringValue") = v
        jarr.data.push(inner)
      end
      values.data("values") = jarr
      obj.data("arrayValue") = values
    | let arr: Array[Bool] val =>
      let values = json.JsonObject
      let jarr = json.JsonArray
      for v in arr.values() do
        let inner = json.JsonObject
        inner.data("boolValue") = v
        jarr.data.push(inner)
      end
      values.data("values") = jarr
      obj.data("arrayValue") = values
    | let arr: Array[I64] val =>
      let values = json.JsonObject
      let jarr = json.JsonArray
      for v in arr.values() do
        let inner = json.JsonObject
        inner.data("intValue") = v
        jarr.data.push(inner)
      end
      values.data("values") = jarr
      obj.data("arrayValue") = values
    | let arr: Array[F64] val =>
      let values = json.JsonObject
      let jarr = json.JsonArray
      for v in arr.values() do
        let inner = json.JsonObject
        inner.data("doubleValue") = v
        jarr.data.push(inner)
      end
      values.data("values") = jarr
      obj.data("arrayValue") = values
    end
    obj

  fun _span_kind_value(kind: otel_api.SpanKind): U32 =>
    """
    OTLP uses 1-indexed span kind values (INTERNAL=1, SERVER=2, etc).
    """
    kind.value() + 1
