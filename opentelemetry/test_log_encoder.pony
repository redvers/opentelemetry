use "pony_test"
use json = "../_corral/github_com_ponylang_json/json"
use otel_api = "otel_api"
use otel_sdk = "otel_sdk"
use otel_otlp = "otel_otlp"


class iso _TestOtlpLogEncoderBasic is UnitTest
  fun name(): String => "OtlpLogEncoder/basic"

  fun apply(h: TestHelper) ? =>
    let log = otel_sdk.LogRecordData(
      1000, 2000,
      otel_api.SeverityNumber.info(), "INFO",
      "test message",
      recover val Array[(String, otel_api.AttributeValue)] end,
      otel_api.TraceId.invalid(),
      otel_api.SpanId.invalid(),
      0,
      otel_api.Resource,
      "test-logger", "")

    let logs: Array[otel_sdk.LogRecordData val] val = recover val [log] end
    let json_str = otel_otlp.OtlpLogEncoder.encode_logs(logs)

    let doc = json.JsonDoc
    doc.parse(json_str)?

    match doc.data
    | let root: json.JsonObject =>
      match try root.data("resourceLogs")? end
      | let rl_arr: json.JsonArray =>
        h.assert_eq[USize](1, rl_arr.data.size())

        match try rl_arr.data(0)? end
        | let rl_obj: json.JsonObject =>
          match try rl_obj.data("scopeLogs")? end
          | let sl_arr: json.JsonArray =>
            match try sl_arr.data(0)? end
            | let sl_obj: json.JsonObject =>
              match try sl_obj.data("logRecords")? end
              | let lr_arr: json.JsonArray =>
                h.assert_eq[USize](1, lr_arr.data.size())

                match try lr_arr.data(0)? end
                | let lr_obj: json.JsonObject =>
                  match try lr_obj.data("timeUnixNano")? end
                  | let t: String =>
                    h.assert_eq[String]("1000", t)
                  else h.fail("timeUnixNano should be string")
                  end

                  match try lr_obj.data("observedTimeUnixNano")? end
                  | let t: String =>
                    h.assert_eq[String]("2000", t)
                  else h.fail("observedTimeUnixNano should be string")
                  end

                  match try lr_obj.data("severityNumber")? end
                  | let sn: I64 =>
                    h.assert_eq[I64](9, sn, "severityNumber should be 9 (INFO)")
                  else h.fail("severityNumber should be I64")
                  end

                  match try lr_obj.data("severityText")? end
                  | let st: String =>
                    h.assert_eq[String]("INFO", st)
                  else h.fail("severityText should be string")
                  end

                  match try lr_obj.data("body")? end
                  | let body_obj: json.JsonObject =>
                    match try body_obj.data("stringValue")? end
                    | let sv: String =>
                      h.assert_eq[String]("test message", sv)
                    else h.fail("body stringValue should be string")
                    end
                  else h.fail("Expected body object")
                  end
                else h.fail("Expected log record object")
                end
              else h.fail("Expected logRecords array")
              end
            else h.fail("Expected scopeLogs object")
            end
          else h.fail("Expected scopeLogs array")
          end
        else h.fail("Expected resourceLogs object")
        end
      else h.fail("Expected resourceLogs array")
      end
    else h.fail("Expected top-level JSON object")
    end


class iso _TestOtlpLogEncoderScope is UnitTest
  fun name(): String => "OtlpLogEncoder/scope"

  fun apply(h: TestHelper) ? =>
    let log = otel_sdk.LogRecordData(
      1000, 2000,
      0, "",
      "scoped message",
      recover val Array[(String, otel_api.AttributeValue)] end,
      otel_api.TraceId.invalid(),
      otel_api.SpanId.invalid(),
      0,
      otel_api.Resource,
      "my-library", "1.2.3")

    let logs: Array[otel_sdk.LogRecordData val] val = recover val [log] end
    let json_str = otel_otlp.OtlpLogEncoder.encode_logs(logs)

    let doc = json.JsonDoc
    doc.parse(json_str)?

    match doc.data
    | let root: json.JsonObject =>
      match try root.data("resourceLogs")? end
      | let rl_arr: json.JsonArray =>
        match try rl_arr.data(0)? end
        | let rl_obj: json.JsonObject =>
          match try rl_obj.data("scopeLogs")? end
          | let sl_arr: json.JsonArray =>
            match try sl_arr.data(0)? end
            | let sl_obj: json.JsonObject =>
              match try sl_obj.data("scope")? end
              | let scope_obj: json.JsonObject =>
                match try scope_obj.data("name")? end
                | let n: String =>
                  h.assert_eq[String]("my-library", n,
                    "Scope name should match")
                else h.fail("scope name should be a string")
                end
                match try scope_obj.data("version")? end
                | let v: String =>
                  h.assert_eq[String]("1.2.3", v,
                    "Scope version should match")
                else h.fail("scope version should be a string")
                end
              else h.fail("Expected scope object")
              end
            else h.fail("Expected scopeLogs object")
            end
          else h.fail("Expected scopeLogs array")
          end
        else h.fail("Expected resourceLogs object")
        end
      else h.fail("Expected resourceLogs array")
      end
    else h.fail("Expected top-level JSON object")
    end


class iso _TestOtlpLogEncoderTraceContext is UnitTest
  fun name(): String => "OtlpLogEncoder/trace_context"

  fun apply(h: TestHelper) ? =>
    let trace_id = otel_api.TraceId.generate()
    let span_id = otel_api.SpanId.generate()

    let log = otel_sdk.LogRecordData(
      1000, 2000,
      otel_api.SeverityNumber.warn(), "WARN",
      "trace correlated",
      recover val Array[(String, otel_api.AttributeValue)] end,
      trace_id,
      span_id,
      otel_api.TraceFlags.sampled(),
      otel_api.Resource,
      "test-logger", "")

    let logs: Array[otel_sdk.LogRecordData val] val = recover val [log] end
    let json_str = otel_otlp.OtlpLogEncoder.encode_logs(logs)

    let doc = json.JsonDoc
    doc.parse(json_str)?

    match doc.data
    | let root: json.JsonObject =>
      match try root.data("resourceLogs")? end
      | let rl_arr: json.JsonArray =>
        match try rl_arr.data(0)? end
        | let rl_obj: json.JsonObject =>
          match try rl_obj.data("scopeLogs")? end
          | let sl_arr: json.JsonArray =>
            match try sl_arr.data(0)? end
            | let sl_obj: json.JsonObject =>
              match try sl_obj.data("logRecords")? end
              | let lr_arr: json.JsonArray =>
                match try lr_arr.data(0)? end
                | let lr_obj: json.JsonObject =>
                  match try lr_obj.data("traceId")? end
                  | let tid: String =>
                    h.assert_eq[USize](32, tid.size(),
                      "traceId should be 32 hex chars")
                    h.assert_eq[String](trace_id.hex(), tid,
                      "traceId should match")
                  else h.fail("traceId should be string")
                  end

                  match try lr_obj.data("spanId")? end
                  | let sid: String =>
                    h.assert_eq[USize](16, sid.size(),
                      "spanId should be 16 hex chars")
                    h.assert_eq[String](span_id.hex(), sid,
                      "spanId should match")
                  else h.fail("spanId should be string")
                  end

                  match try lr_obj.data("flags")? end
                  | let f: I64 =>
                    h.assert_eq[I64](1, f, "flags should be 1 (sampled)")
                  else h.fail("flags should be I64")
                  end
                else h.fail("Expected log record object")
                end
              else h.fail("Expected logRecords array")
              end
            else h.fail("Expected scopeLogs object")
            end
          else h.fail("Expected scopeLogs array")
          end
        else h.fail("Expected resourceLogs object")
        end
      else h.fail("Expected resourceLogs array")
      end
    else h.fail("Expected top-level JSON object")
    end
