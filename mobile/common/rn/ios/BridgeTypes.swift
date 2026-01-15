import Foundation

public typealias ResolveBlock = @Sendable @convention(block) (Any?) -> Void
public typealias RejectBlock = @Sendable @convention(block) (String?, String?, Error?) -> Void
