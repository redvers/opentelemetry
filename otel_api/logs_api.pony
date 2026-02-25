type LogBody is (String | None)

primitive SeverityNumber
  fun unspecified(): U8 => 0
  fun trace():  U8 => 1
  fun trace2(): U8 => 2
  fun trace3(): U8 => 3
  fun trace4(): U8 => 4
  fun debug():  U8 => 5
  fun debug2(): U8 => 6
  fun debug3(): U8 => 7
  fun debug4(): U8 => 8
  fun info():   U8 => 9
  fun info2():  U8 => 10
  fun info3():  U8 => 11
  fun info4():  U8 => 12
  fun warn():   U8 => 13
  fun warn2():  U8 => 14
  fun warn3():  U8 => 15
  fun warn4():  U8 => 16
  fun err():   U8 => 17
  fun err2():  U8 => 18
  fun err3():  U8 => 19
  fun err4():  U8 => 20
  fun fatal():  U8 => 21
  fun fatal2(): U8 => 22
  fun fatal3(): U8 => 23
  fun fatal4(): U8 => 24


trait tag LoggerProvider
  be get_logger(name: String, callback: {(Logger val)} val,
    version: String = "", schema_url: String = "")
  be shutdown(callback: {(Bool)} val)


trait val Logger
  fun val emit(
    body: LogBody = None,
    severity_number: U8 = 0,
    severity_text: String = "",
    attributes: Attributes =
      recover val Array[(String, AttributeValue)] end,
    timestamp: U64 = 0,
    observed_timestamp: U64 = 0,
    context: Context = Context)
