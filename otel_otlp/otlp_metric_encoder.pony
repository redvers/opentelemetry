use json = "../_corral/github_com_ponylang_json/json"
use otel_api = "../otel_api"
use otel_sdk = "../otel_sdk"

primitive OtlpMetricEncoder
  fun encode_metrics(
    metrics: Array[otel_sdk.MetricData val] val,
    resource: otel_api.Resource = otel_api.Resource)
    : String
  =>
    let root = json.JsonObject

    let resource_metrics_arr = json.JsonArray
    let rm_obj = json.JsonObject

    // Encode resource
    rm_obj.data("resource") = _encode_resource(resource)

    // Build scopeMetrics — all metrics go under a single scope for now
    let scope_metrics_arr = json.JsonArray
    let sm_obj = json.JsonObject
    sm_obj.data("scope") = json.JsonObject

    let metrics_arr = json.JsonArray
    for metric in metrics.values() do
      metrics_arr.data.push(_encode_metric(metric))
    end

    sm_obj.data("metrics") = metrics_arr
    scope_metrics_arr.data.push(sm_obj)
    rm_obj.data("scopeMetrics") = scope_metrics_arr
    resource_metrics_arr.data.push(rm_obj)

    root.data("resourceMetrics") = resource_metrics_arr
    root.string()

  fun _encode_resource(resource: otel_api.Resource): json.JsonObject =>
    let obj = json.JsonObject
    obj.data("attributes") = OtlpJsonEncoder._encode_attributes(
      resource.attributes())
    obj

  fun _encode_metric(metric: otel_sdk.MetricData val): json.JsonObject =>
    let obj = json.JsonObject
    obj.data("name") = metric.name
    if metric.description.size() > 0 then
      obj.data("description") = metric.description
    end
    if metric.unit.size() > 0 then
      obj.data("unit") = metric.unit
    end

    match metric.kind
    | otel_api.InstrumentKindCounter =>
      obj.data("sum") = _encode_sum(metric, true)
    | otel_api.InstrumentKindUpDownCounter =>
      obj.data("sum") = _encode_sum(metric, false)
    | otel_api.InstrumentKindHistogram =>
      obj.data("histogram") = _encode_histogram(metric)
    | otel_api.InstrumentKindGauge =>
      obj.data("gauge") = _encode_gauge(metric)
    end
    obj

  fun _encode_sum(metric: otel_sdk.MetricData val, is_monotonic: Bool)
    : json.JsonObject
  =>
    let obj = json.JsonObject
    obj.data("aggregationTemporality") = I64(2) // CUMULATIVE
    obj.data("isMonotonic") = is_monotonic

    let data_points = json.JsonArray
    match metric.data
    | let points: Array[otel_sdk.NumberDataPoint val] val =>
      for point in points.values() do
        data_points.data.push(_encode_number_data_point(point))
      end
    end
    obj.data("dataPoints") = data_points
    obj

  fun _encode_gauge(metric: otel_sdk.MetricData val): json.JsonObject =>
    let obj = json.JsonObject
    let data_points = json.JsonArray
    match metric.data
    | let points: Array[otel_sdk.NumberDataPoint val] val =>
      for point in points.values() do
        data_points.data.push(_encode_number_data_point(point))
      end
    end
    obj.data("dataPoints") = data_points
    obj

  fun _encode_histogram(metric: otel_sdk.MetricData val): json.JsonObject =>
    let obj = json.JsonObject
    obj.data("aggregationTemporality") = I64(2) // CUMULATIVE

    let data_points = json.JsonArray
    match metric.data
    | let points: Array[otel_sdk.HistogramDataPoint val] val =>
      for point in points.values() do
        data_points.data.push(_encode_histogram_data_point(point))
      end
    end
    obj.data("dataPoints") = data_points
    obj

  fun _encode_number_data_point(point: otel_sdk.NumberDataPoint val)
    : json.JsonObject
  =>
    let obj = json.JsonObject
    obj.data("startTimeUnixNano") = point.start_time_unix_nano.i64()
    obj.data("timeUnixNano") = point.time_unix_nano.i64()
    obj.data("asDouble") = point.value
    if point.attributes.size() > 0 then
      obj.data("attributes") = OtlpJsonEncoder._encode_attributes(
        point.attributes)
    end
    obj

  fun _encode_histogram_data_point(point: otel_sdk.HistogramDataPoint val)
    : json.JsonObject
  =>
    let obj = json.JsonObject
    obj.data("startTimeUnixNano") = point.start_time_unix_nano.i64()
    obj.data("timeUnixNano") = point.time_unix_nano.i64()
    obj.data("count") = point.count.i64()
    obj.data("sum") = point.sum
    obj.data("min") = point.min_val
    obj.data("max") = point.max_val

    let bucket_arr = json.JsonArray
    for c in point.bucket_counts.values() do
      bucket_arr.data.push(c.i64())
    end
    obj.data("bucketCounts") = bucket_arr

    let bounds_arr = json.JsonArray
    for b in point.explicit_bounds.values() do
      bounds_arr.data.push(b)
    end
    obj.data("explicitBounds") = bounds_arr

    if point.attributes.size() > 0 then
      obj.data("attributes") = OtlpJsonEncoder._encode_attributes(
        point.attributes)
    end
    obj
