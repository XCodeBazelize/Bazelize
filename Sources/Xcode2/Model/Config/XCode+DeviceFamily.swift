import Foundation

public extension XCode {
    enum DeviceFamily: String {
        case iphone = "1"
        case ipad = "2"
        case appletv = "3"
        case applewatch = "4"
        case homepod = "5"
        case mac = "6"

        public var code: String {
            switch self {
            case .iphone: return "iphone"
            case .ipad: return "ipad"
            case .appletv: return "appletv"
            case .applewatch: return "watch"
            case .homepod: return "homepod"
            case .mac: return "mac"
            }
        }

        static func parse(_ rawValue: String?) -> [Self] {
            rawValue?
                .split { $0 == "," || $0 == " " }
                .map(String.init)
                .compactMap(Self.init(rawValue:)) ?? []
        }
    }
}
