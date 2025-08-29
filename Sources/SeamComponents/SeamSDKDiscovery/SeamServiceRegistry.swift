import Foundation
import ObjectiveC.runtime


@MainActor
public enum SeamServiceRegistry {
    public private(set) static var live: (any SeamServiceProtocol)? = nil

    #if DEBUG
    public private(set) static var mock: (any SeamServiceProtocol)? = PreviewSeamService.shared
    #endif

    public static func findLiveService() -> (any SeamServiceProtocol)? {
        if live != nil { return live }
        // Discover any SeamServiceRegistration subclasses that the SDK (or other providers) shipped.
        let types = registeredServices()
        // Determine a Components version string to pass along (best-effort).
        let componentsVersion = "0.0.0"

        // Instantiate the first available registration and create the live service.
        let registration = types.first?.init()
        let service = registration?.createService(componentsVersion: componentsVersion)
        live = service
        return live
    }

    private static func registeredServices() -> [SeamServiceRegistration.Type] {
        var result: [SeamServiceRegistration.Type] = []

        var count: UInt32 = 0
        let classList = objc_copyClassList(&count)!
        defer { free(UnsafeMutableRawPointer(classList)) }
        let classes = UnsafeBufferPointer(start: classList, count: Int(count))
        for cls in classes {
            // Walk superclass chain to see if `cls` inherits from `SeamServiceRegistration`
            var s: AnyClass? = cls
            var isSubclass = false
            while let current = s {
                if current == SeamServiceRegistration.self {
                    isSubclass = true
                    break
                }
                s = class_getSuperclass(current)
            }

            if isSubclass,
               cls != SeamServiceRegistration.self,  // exclude the base class itself
               let typed = cls as? SeamServiceRegistration.Type {
                result.append(typed)
                break
            }
        }
        return result
    }
}


@_spi(Internal)
@objc open class SeamServiceRegistration: NSObject {
    open var sdkVersion: String {
        fatalError("Must override version in SeamSDK.")
    }

    @MainActor
    open func createService(componentsVersion: String) -> any SeamServiceProtocol {
        fatalError("Must override createSeamService(componentsVersion:).")
    }

    public override required init() { }
}
