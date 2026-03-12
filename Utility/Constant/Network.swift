//
//  Network.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 3/12/26.
//


// MARK: Network Level
struct NetworkConst {
	static fileprivate let baseURL      = "https://connectapi.garmin.com"
	
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
}
