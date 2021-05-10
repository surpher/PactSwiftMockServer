//
//  TransferProtocol.swift
//  PactSwiftMockServer
//
//  Created by Marko Justinek on 10/5/21.
//

import Foundation

/// Network transfer protocol
@objc public enum TransferProtocol: Int {

	case standard
	case secure

	var `protocol`: String {
		switch self {
		case .standard: return "http"
		case .secure: return "https"
		}
	}

}
