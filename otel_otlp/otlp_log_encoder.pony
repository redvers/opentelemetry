use "collections"
use json = "../_corral/github_com_ponylang_json/json"
use otel_api = "../otel_api"
use otel_sdk = "../otel_sdk"

primitive OtlpLogEncoder
  fun encode_logs(
    logs: Array[otel_sdk.LogRecordData val] val,
    resource: otel_api.Resource = otel_api.Resource)
    : String
  =>
    let root = json.JsonObject

    let resource_logs_arr = json.JsonArray
    let rl_obj = json.JsonObject

    rl_obj.data("resource") = _encode_resource(resource)

    // Group logs by scope
    let scope_groups = Map[String val, Array[otel_sdk.LogRecordData val]]
    for log in logs.values() do
      let key: String val = recover val
        let s = String
        let sn = log.scope_name
        s.append(sn.size().string())
        s.append(":")
        s.append(sn)
        s.append(log.scope_version)
        s
      end
      let group = try
        scope_groups(key)?
      else
        let g = Array[otel_sdk.LogRecordData val]
        scope_groups(key) = g
        g
      end
      group.push(log)
    end

    let scope_logs_arr = json.JsonArray
    for (_, group) in scope_groups.pairs() do
      let sl_obj = json.JsonObject

      // Encode scope from first log in group
      try
        let first = group(0)?
        let scope_obj = json.JsonObject
        scope_obj.data("name") = first.scope_name
        if first.scope_version.size() > 0 then
          scope_obj.data("version") = first.scope_version
        end
        sl_obj.data("scope") = scope_obj
      end

      let log_records_arr = json.JsonArray
      for log in group.values() do
        log_records_arr.data.push(_encode_log_record(log))
      end

      sl_obj.data("logRecords") = log_records_arr
      scope_logs_arr.data.push(sl_obj)
    end

    rl_obj.data("scopeLogs") = scope_logs_arr
    resource_logs_arr.data.push(rl_obj)

    root.data("resourceLogs") = resource_logs_arr
    root.string()

  fun _encode_resource(resource: otel_api.Resource): json.JsonObject =>
    let obj = json.JsonObject
    obj.data("attributes") = OtlpJsonEncoder._encode_attributes(
      resource.attributes())
    obj

  fun _encode_log_record(log: otel_sdk.LogRecordData val): json.JsonObject =>
    let obj = json.JsonObject

    obj.data("timeUnixNano") = log.timestamp.string()
    obj.data("observedTimeUnixNano") = log.observed_timestamp.string()

    if log.severity_number > 0 then
      obj.data("severityNumber") = log.severity_number.i64()
    end

    if log.severity_text.size() > 0 then
      obj.data("severityText") = log.severity_text
    end

    match log.body
    | let s: String =>
      let body_obj = json.JsonObject
      body_obj.data("stringValue") = s
      obj.data("body") = body_obj
    end

    if log.attributes.size() > 0 then
      obj.data("attributes") = OtlpJsonEncoder._encode_attributes(
        log.attributes)
    end

    if log.trace_id.is_valid() then
      obj.data("traceId") = log.trace_id.hex()
    end

    if log.span_id.is_valid() then
      obj.data("spanId") = log.span_id.hex()
    end

    if log.trace_flags > 0 then
      obj.data("flags") = log.trace_flags.u64().i64()
    end

    obj
