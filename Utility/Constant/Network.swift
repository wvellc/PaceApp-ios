//
//  Network.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/12/26.
//


// MARK: Network Level
struct NetworkConst {
	static fileprivate let baseURL      = "https://paceapp.net"
	
	struct API {
		// Base endpoints
		struct EndPoint {
			static let activities       = "/activitylist-service/activities"
			static let athlete          = "/wellness-service/wellness/user"
			static let heartRate        = "/wellness-service/wellness/dailyHeartRate"
		}
		
		struct ReqParam {
			static let limit            = "limit"
			static let start            = "start"
			static let activityType     = "activityType"
		}
	}
	
	struct WebUrl {
		static let privacyPolicy    = "\(baseURL)/privacy-policy"
		static let termsOfService   = "\(baseURL)/terms-of-service"
		static let licences         = "\(baseURL)/licenses"
		static let wvelabs     	    = "https://wvelabs.com"
		
	}
}
