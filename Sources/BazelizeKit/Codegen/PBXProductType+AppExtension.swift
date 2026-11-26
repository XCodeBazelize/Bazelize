import XcodeProj

extension PBXProductType {
    /// Every product type whose identifier is an `app-extension` one: the
    /// plain one, and the tvOS, Messages, sticker pack, and Intents variants.
    var isAppExtension: Bool {
        switch self {
        case .appExtension, .tvExtension, .messagesExtension, .stickerPack, .intentsServiceExtension:
            true
        default:
            false
        }
    }
}
