import UserNotifications

final class NotificationService: UNNotificationServiceExtension {
    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void)
    {
        contentHandler(request.content)
    }
}
