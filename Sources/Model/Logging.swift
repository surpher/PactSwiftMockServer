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

public enum Logging {

	public enum Error {
		case loggerApplyFailed(Int32)

		/// The logger sink could not be configured. The associated error codes:
		///
		/// - -1: Can't set logger (applying the logger failed, perhaps because one is applied already).
		/// * -2: No logger has been initialized (call ``Pact/loggerInitialize()`` before any other log function).
		/// * -3: The sink specifier was not UTF-8 encoded.
		/// * -4: The sink type specified is not a known type (known types: "stdout", "stderr", or "file /some/path").
		/// * -5: No file path was specified in a file-type sink specification.
		/// * -6: Opening a sink to the specified file path failed (check permissions).
		case loggerSinkFailed(Int32)
	}

	/// Defines Logging Levels.
	public enum Level: String {
		case trace = "TRACE", debug = "DEBUG", info = "INFO", warn = "WARN", error = "ERROR"
	}

	/// Defines Logging Level Filters.
	public enum Filter {
		case off, error, warn, info, debug, trace
	}

	/// The different types of log sinks that can be attached.
	public enum Sink {

		/// Defines the configuration of a ``Logging/Sink``.
		public struct Config {
			var sink: Sink
			var filter: Filter

			public init(_ sink: Sink, filter: Filter) {
				self.sink = sink
				self.filter = filter
			}
		}

		case standardOut
		case standardError
		case file(String)
		case buffer
	}

	/// Apply the previously configured sinks and levels to the program. If no sinks have been setup will set the log level to ``Level/info`` and the target to ``Sink/standardOut``.
	///
	/// This function will install a global tracing subscriber. Any attempts to modify the logger after the call to `loggerApply()` will fail.
	@MainActor
	private static func apply() throws {
		let result = pactffi_logger_apply()
		guard result == 0 else {
			throw Error.loggerApplyFailed(result)
		}
	}

	/// Initialize the logger with no sinks.
	///
	/// This initialized logger does nothing until ``Logging/apply()`` has been called.
	@MainActor 
	@discardableResult
	private static func initialize() -> Bool {
		guard isInitialized == false else {
			return false
		}

		pactffi_logger_init()
		isInitialized = true
		return true
	}

	/// Returns a value indicating whether the PactSwift ``Logging`` has been initialized.
	@MainActor public private(set) static var isInitialized = false

	/// Initialize the Pact logging infrastructure.
	///
	/// You should call this early
	/// in the lifetime of your Pact test case. Subsequent calls will do nothing.
	///
	/// For example:
	/// ```
	/// class PactTests: XCTestCase {
	///
	///   @MainActor
	///   class override func setUp() {
	///	    super.setUp()
	///     try! Logging.initialize()
	///   }
	///
	///   // ... tests...
	/// }
	/// ```
	///
	/// - Note: By default the underlying Pact library will not log messages.
	/// - Parameters:
	///   - logSinks: An array of ``Logging/Sink/Config`` instances to configure the log sinks.
	@MainActor
	public static func initialize(_ logSinks: [Logging.Sink.Config] = .defaultSinks) throws {
		guard initialize() else {
			return
		}

		for sink in logSinks {
			try Logging.attachSink(sink.sink, filter: sink.filter)
		}
		try Logging.apply()
	}

	/// Attach an additional sink to the thread-local logger.
	///
	/// - Note: This logger does nothing until ``Logging/apply`` has been called.
	///
	@MainActor
	private static func attachSink(_ sink: Sink, filter: Filter) throws {
		let result = pactffi_logger_attach_sink(sink.specifier.cString(using: .utf8), LevelFilter(filter))
		guard result == 0 else {
			throw Error.loggerSinkFailed(result)
		}
	}

	/// Fetch the in-memory logger buffer contents. This will only have any contents if the ``Sink/buffer`` sink has been configured to log to.
	public static var buffer: String {
		// Fetches the logs associated with the provided identifier, or uses the "global" one if the identifier is not specified (i.e. NULL).
		guard let buffer = pactffi_fetch_log_buffer(nil) else {
			return ""
		}
		defer { pactffi_string_delete(UnsafeMutablePointer(mutating: buffer)) }

		return String(cString: buffer)
	}

	/// Log using the shared Pact core logging facility.
	///
	/// This is useful for callers to have a single set of logs.
	///
	/// - Parameters:
	///   - level: The log level to use.
	///   - message: The message to log.
	///
	public static func log(_ level: Level, message: String) {
		pactffi_log_message("pact_swift".cString(using: .utf8), level.rawValue.cString(using: .utf8), message.cString(using: .utf8))
	}

	/// Get the last error message from the underlying `pact_ffi` library.
	public static var lastInternalErrorMessage: String? {
		withUnsafeTemporaryAllocation(of: CChar.self, capacity: 1_024) { buffer in // swiftlint:disable:this numbers_smell
			guard let baseAddress = buffer.baseAddress else {
				Logging.log(.error, message: "Failed to allocated temporary buffer!")
				return nil
			}

			let result = pactffi_get_error_message(baseAddress, Int32(buffer.count))
			switch result {
			case 0:
				break // No error message
			case -1: // if the provided buffer is a null pointer.
				fatalError("Failed to allocate temporary buffer. This is very unexpected.") // This should never happen but 🤷
			case -2: // if the provided buffer length is too small for the error message.
				Logging.log(.error, message: "Log message buffer capacity \(buffer.count) is insufficient for error message!")
			case -3: // if the write failed for some other reason.
				Logging.log(.error, message: "Writing error message to buffer failed for an unknown reason.")
			case -4: // if the error message had an interior NULL
				Logging.log(.error, message: "Error message had an interior NULL!?")
			case let result where result < -4:
				Logging.log(.error, message: "Unknown error code: \(result)")
			default:
				return String(cString: baseAddress)
			}
			return nil
		}
	}
}

private extension LevelFilter {
	init(_ levelFilter: Logging.Filter) {
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

private extension Logging.Sink {
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

public extension Array where Element == Logging.Sink.Config {
	static let defaultSinks: Self = [
		Element(.standardError, filter: .info),
		Element(.buffer, filter: .trace),
	]
}

extension Logging.Error: LocalizedError {
	public var failureReason: String? {
		switch self {
		case .loggerSinkFailed(let code):
			return String.localizedStringWithFormat(
				NSLocalizedString(
					"Can not configure logger sink (error code: %d)",
					comment: "Format for error failure reason when configure logger sink"
				),
				code
			)
		case .loggerApplyFailed(let code):
			return String.localizedStringWithFormat(
				NSLocalizedString(
					"Can not apply logger configuration (error code: %d)",
					comment: "Format for error failure reason when can't apply logger config"
				),
				code
			)
		}
	}
}
