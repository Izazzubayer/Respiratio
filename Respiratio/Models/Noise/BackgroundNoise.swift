import Foundation

public struct BackgroundNoise: Hashable, Identifiable {
    public let id = UUID()
    public let title: String
    public let summary: String
    public let tags: [String]
    public let fileName: String
    public let fileExt: String

    public init(
        title: String,
        summary: String,
        tags: [String],
        fileName: String,
        fileExt: String = "mp3"
    ) {
        self.title = title
        self.summary = summary
        self.tags = tags
        self.fileName = fileName
        self.fileExt = fileExt
    }
}
