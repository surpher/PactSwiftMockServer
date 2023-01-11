//
//  Created by Oliver Jones on 10/1/2023.
//  Copyright © 2023 Oliver Jones. All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any
//  purpose with or without fee is hereby granted, provided that the above
//  copyright notice and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
//  SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
//  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

import Foundation

public extension Pact {

	struct LogSinkConfig {
		var sink: LogSink
		var filter: LogLevelFilter

		public init(_ sink: LogSink, filter: LogLevelFilter) {
			self.sink = sink
			self.filter = filter
		}
	}

	enum LogLevelFilter {
		case off, error, warn, info, debug, trace
	}

	/// The different types of log sinks that can be attached.
	enum LogSink {
		case standardOut
		case standardError
		case file(String)
		case buffer
	}

	/// Apply the previously configured sinks and levels to the program. If no sinks have been setup will set the log level to ``LogLevel/info`` and the target to ``LogSink/standardOut``.
	///
	/// This function will install a global tracing subscriber. Any attempts to modify the logger after the call to `loggerApply()` will fail.
	static func loggerApply() throws {
		let result = pactffi_logger_apply()
		guard result == 0 else {
			throw Error.loggerApplyFailed(result)
		}
	}

	/// Initialize the logger with no sinks.
	///
	/// This initialized logger does nothing until ``loggerApply()`` has been called.
	///
	static func loggerInitialize() {
		pactffi_logger_init()
	}

	/// Attach an additional sink to the thread-local logger.
	///
	/// - Note: This logger does nothing until ``Pact/loggerApply`` has been called.
	///
	static func attachLogSink(_ sink: LogSink, filter: LogLevelFilter) throws {
		let result = pactffi_logger_attach_sink(sink.specifier.cString(using: .utf8), LevelFilter(filter))
		guard result == 0 else {
			throw Error.loggerSinkFailed(result)
		}
	}

	/// Fetch the in-memory logger buffer contents. This will only have any contents if the ``LogSink/buffer`` sink has been configured to log to.
	static var logBuffer: String {
		// Fetches the logs associated with the provided identifier, or uses the "global" one if the identifier is not specified (i.e. NULL).
		guard let buffer = pactffi_fetch_log_buffer(nil) else {
			return ""
		}
		defer { pactffi_string_delete(UnsafeMutablePointer(mutating: buffer)) }

		return String(cString: buffer)
	}

}

private extension LevelFilter {
	init(_ levelFilter: Pact.LogLevelFilter) {
		switch levelFilter {
		case .off: self = LevelFilter_Off
		case .error: self = LevelFilter_Error
		case .trace: self = LevelFilter_Trace
		case .debug: self = LevelFilter_Debug
		case .warn: self = LevelFilter_Warn
		case .info: self = LevelFilter_Info
		}
	}
}

private extension Pact.LogSink {
	var specifier: String {
		switch self {
		case .standardOut:
			return "stdout"
		case .standardError:
			return "stderr"
		case .buffer:
			return "buffer"
		case .file(let path):
			return "file \(path)"
		}
	}
}

public extension Array where Element == Pact.LogSinkConfig {
	static var defaultSinks: Self = [
		Element(.standardError, filter: .info),
		Element(.buffer, filter: .trace)
	]
}
