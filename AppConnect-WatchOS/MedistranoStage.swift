//
//  MedistranoStage.swift
//  watch-lib-tester WatchKit Extension
//
//  Created by Nathaniel Jacobs on 10/18/19.
//  Copyright © 2019 Nathaniel Jacobs. All rights reserved.
//

import Foundation

/// Medistrano Stage
public enum MedistranoStage: String, Codable, Hashable, CaseIterable {
    /// Production
    case production
    
    /// Innovate
    case innovate
    
    /// Validation
    case validation

    
    /// Sandbox
    case sandbox
    
    /// Default Stage
    public static let `default` = MedistranoStage.production
    
    /// Broadacre URL associated with the stage
    public var eproURL: URL {
        switch self {
        case .production:
            return URL(string: "https://epro.imedidata.com")!
        case .innovate:
            return URL(string: "https://epro-innovate.imedidata.com")!
        case .validation:
            return URL(string: "https://epro-validation.imedidata.net")!
        case .sandbox:
            return URL(string: "https://epro-sandbox.imedidata.net")!
        }
    }
    
}
