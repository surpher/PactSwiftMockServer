//
//  Created by Marko Justinek on 9/8/2022.
//  Copyright © 2022 Marko Justinek. All rights reserved.
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

public enum PactFileManager {

	/// Where default location Pact contracts are written to.
	///
	/// macOS:
	///
	/// Running tests for macOS it will default to app's Documents folder:
	///
	/// (eg: `~/Library/Containers/au.com.pact-foundation.Pact-macOS-Example/Data/Documents`)
	///
	/// If testing a sandboxed macOS app, this is the default location and it can not be overwritten.
	/// If testing a macOS app that is not sandboxed, define a `PACT_OUTPUT_DIR` Environment Variable (in the scheme)
	/// with the path to where you want Pact contracts to be written to.
	///
	/// iOS/tvOS or non-Xcode project:
	///
	/// Default location where Pact contracts are written is `/tmp/pacts` and can be overwritten
	/// with a `PACT_OUTPUT_DIR` environment variable set to an absolute path (eg: `$(PROJECT_DIR)/tmp/pacts`).
	///
	public static var defaultPactDirectoryPath: String {
		#if os(macOS) || os(OSX)
		let defaultPath = NSHomeDirectory() + "/Documents"
		if isSandboxed {
			return defaultPath
		}
		return ProcessInfo.processInfo.environment["PACT_OUTPUT_DIR"] ?? defaultPath
		#else
		return ProcessInfo.processInfo.environment["PACT_OUTPUT_DIR"] ?? "/tmp/pacts"
		#endif
	}
    
}

private extension PactFileManager {
	
	/// Returns true if app is sandboxed
	static var isSandboxed: Bool {
		let environment = ProcessInfo.processInfo.environment
		return environment["APP_SANDBOX_CONTAINER_ID"] != nil
	}

}
