//
//  OpenAIService.swift
//  RecycleBot
//
//  Created by Noah Brauner on 11/30/23.
//

import Foundation
import UIKit

class GPTService {
    static let shared = GPTService()
    
    private init() {}

    // MARK: - Use your OpenAI API key here
    struct Constants {
        static let APIKey = Bundle.main.infoDictionary?["API_KEY"] as? String
        static let MaxTokens = 300
    }

    enum OpenAIError: Error {
        case failedToDecode
        case noAPIKeyFound
    }
    
    func callAPI(with image: UIImage, town: String, state: String, personality: String, completion: @escaping (Result<GPTResponse, Error>) -> Void) {
        guard let apiKey = Constants.APIKey, apiKey != "YOUR_API_KEY_HERE" else {
            completion(.failure(OpenAIError.noAPIKeyFound))
            return
        }
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to get image data"])))
            return
        }

        let base64Image = imageData.base64EncodedString()
        
        let locationQuery = {
            let baseString = "You are a local waste management director "
            if town.isEmpty && state.isEmpty {
                return baseString + "."
            }
            else if town.isEmpty {
                return baseString + " in the state of \(state)."
            }
            else if state.isEmpty {
                return baseString + "in the town of \(town)."
            }
            else {
                return baseString + "in \(town), \(state)."
            }
        }()
        let personalityQuery = "You have a \(personality.isEmpty ? "professional" : personality) personality."
        
        let payload: [String: Any] = [
            "model": "gpt-4-vision-preview",
            "messages": [
                [
                    "role": "system", "content": "\(locationQuery) \(personalityQuery) Be sure your response is still entirely accurate."
                ],
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "What item is this? Can this be recycled? Answer in this format: item|yes/no|how to do this. Examples: Plastic Bottle|Yes|Just toss it into your recycling bin. Battery|Somewhat|Take this to an electronics recycling facility. Chess Piece|No|Not recyclable and why. Just toss it in the trash!"
                        ],
                        [
                            "type": "image_url", 
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)",
                                "detail": "low"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": Constants.MaxTokens
        ]
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error!))
                return
            }
            
            do {
                let r = try JSONDecoder().decode(GPTResponse.self, from: data)
                completion(.success(r))
            }
            catch {
                completion(.failure(OpenAIError.failedToDecode))
            }
        }.resume()
    }
}

struct GPTResponse: Codable {
    let id, object: String
    let created: Int
    let model: String
    let usage: Usage
    let choices: [Choice]
    
    
    var content: [String]? { choices.first?.message.content.components(separatedBy: "|") }
    var item: String {
        guard let content, content.count > 0 else { return "" }
        return content[0]
    }
    var recyclable: String {
        guard let content, content.count > 1 else { return "" }
        return content[1]
    }
    var message: String {
        guard let content, content.count > 2 else { return "" }
        return content[2]
    }
}

struct Choice: Codable {
    let message: Message
    let finishDetails: FinishDetails
    let index: Int

    enum CodingKeys: String, CodingKey {
        case message
        case finishDetails = "finish_details"
        case index
    }
}

struct FinishDetails: Codable {
    let type, stop: String
}

struct Message: Codable {
    let role, content: String
}

struct Usage: Codable {
    let promptTokens, completionTokens, totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}
