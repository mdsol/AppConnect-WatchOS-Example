//
//  logger.swift
//  watch-lib-tester WatchKit Extension
//
//  Created by Nathaniel Jacobs on 10/18/19.
//  Copyright © 2019 Nathaniel Jacobs. All rights reserved.
//
import Foundation
import os.log

/// Logs with varying log levels
public struct Logger {
    
    private static let subsystem: String = Bundle.main.bundleIdentifier ?? "com.mdsol.watchtester"
    
    /// Custom log object that is passed to logging functions in order to send messages to the logging system.
    private static let log = OSLog(subsystem: subsystem, category: "watchtester")
    
    /// Logs info message out to NSLog, including funtion, file, and line information
    public static func info(_ logMessage: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        let message = Logger.humanReadableMessage(functionName: functionName, fileName: fileName, lineNumber: lineNumber, logMessage: logMessage)
        os_log("%{public}@", log: log, type: .info, message)
    }
    
    /// Logs error message out to NSLog, including funtion, file, and line information
    public static func error(_ logMessage: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        let message = Logger.humanReadableMessage(functionName: functionName, fileName: fileName, lineNumber: lineNumber, logMessage: logMessage)
        os_log("%{public}@", log: log, type: .error, message)
    }
    
    private static func humanReadableMessage(functionName: String, fileName: String, lineNumber: Int, logMessage: String) -> String {
        let normalizedFilename = FileManager.default.displayName(atPath: fileName)
        return "[\(normalizedFilename):\(lineNumber)] \(functionName) > \(logMessage)"
    }
}
