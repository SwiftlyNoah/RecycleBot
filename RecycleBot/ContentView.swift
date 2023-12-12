//
//  ContentView.swift
//  RecycleBot
//
//  Created by Noah Brauner on 11/30/23.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var isShowingImagePicker = false
    @State private var isShowingCamera = false
    @State private var isLoading = false
    
    @State var response: GPTResponse?
    
    @AppStorage("input_tokens") var inputTokens = 0
    @AppStorage("output_tokens") var outputTokens = 0
    @AppStorage("total_tokens") var totalTokens = 0
    @State var isViewingTokens = true
    
    @State var isShowingOptions = false
    
    @AppStorage("town") var town = ""
    @AppStorage("state") var state = ""
    @AppStorage("personality") var personality = ""
    
    var body: some View {
        ScrollView {
            HStack {
                Text("RECYCLE_BOT")
                    .font(.aquire(size: 36))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button {
                    withAnimation {
                        isShowingOptions.toggle()
                    }
                } label: {
                    Image(systemName: isShowingOptions ? "xmark" : "line.3.horizontal")
                        .frame(width: 40, height: 40)
                        .stylized(verticalPadding: 0, horizontalPadding: 0, cornerRadius: 8, usesFullWidth: false)
                }
                
            }
            
            if isShowingOptions {
                OptionsTextField(text: $town, placeholder: "Town")
                OptionsTextField(text: $state, placeholder: "State")
                OptionsTextField(text: $personality, placeholder: "Personality")
            }
            else {
                VStack {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .frame(maxHeight: 300)
                    }
                    
                    if let response {
                        VStack(spacing: 10) {
                            HStack {
                                Text(response.recyclable)
                                    .font(.title3.bold().monospaced())
                                    .foregroundStyle(getForegroundColor(for: response.recyclable))
                                
                                Spacer()
                                
                                Text(response.item)
                                    .font(.body.bold().monospaced())
                            }
                            
                            Text(response.message)
                                .font(.body.monospaced())
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .stylized(verticalPadding: 8, horizontalPadding: 16)
                    }
                    else if isLoading {
                        ProgressView()
                            .stylized(verticalPadding: 16, horizontalPadding: 16, usesFullWidth: false)
                    }
                    
                    HStack {
                        Button(action: {
                            checkCameraPermission { granted in
                                if granted {
                                    self.isShowingCamera = true
                                } else {
                                    // uh oh spaghettio
                                    // TODO: - Handle no camera access
                                }
                            }
                        }) {
                            Text("Take Photo")
                                .stylized()
                        }
                        
                        Button(action: {
                            self.isShowingImagePicker = true
                        }) {
                            Text("Upload Photo")
                                .stylized()
                        }
                    }
                }
                
            }
        }
        .padding([.horizontal, .top])
        .sheet(isPresented: $isShowingImagePicker) {
            PhotoPickerView(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $isShowingCamera) {
            ImagePickerView(selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage, initial: false) { _, newImage in
            if let image = newImage {
                callGPT4API(with: image)
            }
        }
        .preferredColorScheme(.dark)
        .overlay(alignment: .bottomTrailing) {
            Button(action: { isViewingTokens.toggle() }) {
                Text(isViewingTokens ? "\(totalTokens)" : costString())
                    .font(.body.weight(.medium).monospaced())
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding([.bottom, .trailing])
            }
        }
    }
    
    func getForegroundColor(for message: String?, defaultColor: Color = .primary) -> Color {
        guard let message else { return defaultColor }
        switch message.lowercased() {
        case "yes":
            return .green
        case "somewhat", "maybe":
            return .yellow
        case "no":
            return .red
        default:
            return defaultColor
        }
    }
    
    /// Returns the total usage cost in cents
    private func getCost() -> Double {
        var cost: Double = 0
        cost += Double(inputTokens) / 1000
        cost += Double(outputTokens) * 3 / 1000
        return cost
    }
    
    private func costString() -> String {
        let cents = getCost()
        let dollars = cents / 100
        let remainingCents = cents.truncatingRemainder(dividingBy: 100)
        let formattedString: String
        
        if remainingCents == 0 {
            formattedString = String(format: "$%d", dollars)
        } else {
            formattedString = String(format: "$%.3f", Double(cents) / 100.0)
        }
        
        return formattedString
    }
    
    private func callGPT4API(with image: UIImage) {
        response = nil
        isLoading = true
        GPTService.shared.callAPI(with: image, town: town, state: state, personality: personality) { result in
            isLoading = false
            switch result {
            case .success(let response):
                self.response = response
                self.inputTokens += response.usage.promptTokens
                self.outputTokens += response.usage.completionTokens
                self.totalTokens += response.usage.totalTokens
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        default:
            completion(false)
        }
    }
    
    @ViewBuilder func OptionsTextField(text: Binding<String>, placeholder: String) -> some View {
        TextField(text: text, prompt: Text(placeholder)) {
            Text(text.wrappedValue)
        }
        .tint(.white)
        .stylized(horizontalPadding: 16)
    }
}

extension View {
    func stylized(verticalPadding: CGFloat = 16, horizontalPadding: CGFloat = 0, textOpacity: CGFloat = 1, cornerRadius: CGFloat = 20, usesFullWidth: Bool = true) -> some View {
        self
            .font(.body.weight(.medium).monospaced())
            .foregroundStyle(.white.opacity(textOpacity))
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: usesFullWidth ? .infinity : nil)
            .padding(.horizontal, horizontalPadding)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

#Preview {
    ContentView()
}
