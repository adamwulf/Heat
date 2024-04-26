import Foundation
import GenKit

extension Tool {
    
    public static var searchWeb: Self =
        .init(
            type: .function,
            function: .init(
                name: "search_web",
                description: "Return a search query to search the web.",
                parameters: .init(
                    type: .object,
                    properties: [
                        "query": .init(
                            type: .string,
                            description: "A web search query"
                        ),
                    ],
                    required: ["query"]
                )
            )
        )
    
    public struct SearchWeb: Codable {
        public var query: String
        
        public static func decode(_ arguments: String) throws -> Self {
            guard let data = arguments.data(using: .utf8) else {
                throw HeatKitError.failedtoolDecoding
            }
            return try JSONDecoder().decode(Self.self, from: data)
        }
    }
    
    public struct SearchWebResponse: Codable {
        public var instructions: String
        public var results: [WebSearchResult]
    }
}
