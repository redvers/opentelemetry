use "pony_test"
use json = "../_corral/github_com_ponylang_json/json"
use otel_api = "otel_api"
use otel_sdk = "otel_sdk"
use otel_otlp = "otel_otlp"

class iso _TestOtlpJsonEncoderBasic is UnitTest
  fun name(): String => "OtlpJsonEncoder/basic"

  fun apply(h: TestHelper) ? =>
    let trace_id = otel_api.TraceId.generate()
    let span_id = otel_api.SpanId.generate()
    let sc = otel_api.SpanContext(trace_id, span_id)

    let attrs: otel_api.Attributes = recover val
      let a = Array[(String, otel_api.AttributeValue)]
      a.push(("http.method", "GET"))
      a.push(("http.status_code", I64(200)))
      a
    end

    let events: Array[otel_api.SpanEvent] val = recover val
      [otel_api.SpanEvent("event1", 12345)]
    end

    let resource = otel_api.Resource(
      recover val
        let a = Array[(String, otel_api.AttributeValue)]
        a.push(("service.name", "test-service"))
        a
      end)

    let ro = otel_sdk.ReadOnlySpan(
      "test-span",
      sc,
      otel_api.SpanId.invalid(),
      otel_api.SpanKindServer,
      1000000,
      2000000,
      otel_api.SpanStatus(otel_api.SpanStatusOk),
      attrs,
      events,
      resource,
      "test-lib",
      "1.0.0")

    let spans: Array[otel_sdk.ReadOnlySpan val] val = recover val [ro] end
    let json_str = otel_otlp.OtlpJsonEncoder.encode_spans(spans)

    // Parse the JSON to verify structure
    let doc = json.JsonDoc
    doc.parse(json_str)?

    // Verify basic structure exists
    match doc.data
    | let obj: json.JsonObject =>
      match try obj.data("resourceSpans")? end
      | let rs_arr: json.JsonArray =>
        h.assert_true(rs_arr.data.size() > 0,
          "Should have at least one resourceSpans entry")

        match try rs_arr.data(0)? end
        | let rs_obj: json.JsonObject =>
          match try rs_obj.data("scopeSpans")? end
          | let ss_arr: json.JsonArray =>
            h.assert_true(ss_arr.data.size() > 0,
              "Should have at least one scopeSpans entry")

            match try ss_arr.data(0)? end
            | let ss_obj: json.JsonObject =>
              match try ss_obj.data("spans")? end
              | let spans_arr: json.JsonArray =>
                h.assert_eq[USize](1, spans_arr.data.size(),
                  "Should have exactly one span")

                match try spans_arr.data(0)? end
                | let span_obj: json.JsonObject =>
                  match try span_obj.data("name")? end
                  | let n: String =>
                    h.assert_eq[String]("test-span", n)
                  else h.fail("name should be a string")
                  end

                  match try span_obj.data("traceId")? end
                  | let tid: String =>
                    h.assert_eq[String](trace_id.hex(), tid)
                  else h.fail("traceId should be a string")
                  end

                  // Verify OTLP kind is 1-indexed (Server = 2)
                  match try span_obj.data("kind")? end
                  | let k: I64 =>
                    h.assert_eq[I64](2, k, "Server kind should be 2 in OTLP")
                  else h.fail("kind should be an integer")
                  end
                else h.fail("Expected span object")
                end
              else h.fail("Expected spans array")
              end
            else h.fail("Expected scopeSpans object")
            end
          else h.fail("Expected scopeSpans array")
          end
        else h.fail("Expected resourceSpans object")
        end
      else h.fail("Expected resourceSpans array")
      end
    else h.fail("Expected top-level JSON object")
    end


class iso _TestOtlpJsonEncoderTraceState is UnitTest
  fun name(): String => "OtlpJsonEncoder/trace_state"

  fun apply(h: TestHelper) ? =>
    let trace_id = otel_api.TraceId.generate()
    let span_id = otel_api.SpanId.generate()
    let sc = otel_api.SpanContext(trace_id, span_id where
      trace_state' = "vendorname=opaqueValue")

    let ro = otel_sdk.ReadOnlySpan(
      "stateful-span",
      sc,
      otel_api.SpanId.invalid(),
      otel_api.SpanKindInternal,
      1000000,
      2000000,
      otel_api.SpanStatus,
      recover val Array[(String, otel_api.AttributeValue)] end,
      recover val Array[otel_api.SpanEvent] end,
      otel_api.Resource,
      "test-lib",
      "1.0.0")

    let spans: Array[otel_sdk.ReadOnlySpan val] val = recover val [ro] end
    let json_str = otel_otlp.OtlpJsonEncoder.encode_spans(spans)

    let doc = json.JsonDoc
    doc.parse(json_str)?

    // Navigate to the span object and verify traceState is present
    match doc.data
    | let root: json.JsonObject =>
      match try root.data("resourceSpans")? end
      | let rs_arr: json.JsonArray =>
        match try rs_arr.data(0)? end
        | let rs_obj: json.JsonObject =>
          match try rs_obj.data("scopeSpans")? end
          | let ss_arr: json.JsonArray =>
            match try ss_arr.data(0)? end
            | let ss_obj: json.JsonObject =>
              match try ss_obj.data("spans")? end
              | let spans_arr: json.JsonArray =>
                match try spans_arr.data(0)? end
                | let span_obj: json.JsonObject =>
                  match try span_obj.data("traceState")? end
                  | let ts: String =>
                    h.assert_eq[String]("vendorname=opaqueValue", ts,
                      "traceState should be preserved in OTLP encoding")
                  else h.fail("traceState should be a string")
                  end
                else h.fail("Expected span object")
                end
              else h.fail("Expected spans array")
              end
            else h.fail("Expected scopeSpans object")
            end
          else h.fail("Expected scopeSpans array")
          end
        else h.fail("Expected resourceSpans object")
        end
      else h.fail("Expected resourceSpans array")
      end
    else h.fail("Expected top-level JSON object")
    end
