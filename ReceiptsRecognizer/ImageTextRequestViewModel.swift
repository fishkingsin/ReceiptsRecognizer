//
//  ImageTextRequestViewModel.swift
//  ReceiptsRecognizer
//
//  Created by James Kong on 21/10/2023.
//

import Foundation
import Combine
import Vision
import VisionKit
import UIKit
import NaturalLanguage

/**
 A view model class responsible for text extraction from images using the Vision framework.

 This class uses the Vision framework to extract text from an input NSImage and publishes the extracted text using Combine.
 */
class ImageTextRequestViewModel: ObservableObject {

    /// Published property to store the extracted text.
    @Published var extractedText: [String] = []

    /// Set to manage Combine cancellable objects.
    private var cancellable = Set<AnyCancellable>()

    /**
     Extracts text from an input NSImage using the Vision framework.

     - Parameters:
     - image: The NSImage from which text will be extracted.
     */
    
    func extractText(image: UIImage) {
        // Convert NSImage to CGImage
        guard let cgImage = image.cgImage else { return }

        // Create a text recognition request
        let textRequest = recognizeTextRequest(image)
        textRequest.recognitionLevel = .accurate
        let handler = VNImageRequestHandler(cgImage: cgImage)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                // Perform the text recognition request
                try handler.perform([textRequest])

                // Process the recognition results
                let result = textRequest.results
                result?.forEach { text in
                    self.populateText(text: text.topCandidates(1).first?.string ?? "")
                }

            } catch let error {
                print(error.localizedDescription)
            }
        }
    }

    /**
     Populates the extracted text array and publishes the value using Combine.

     - Parameter text: The text to be added to the extractedText array.
     */
    func populateText(text: String) {
        Just(text)
            .receive(on: DispatchQueue.main)
            .sink { value in
                print("populateText: \(value)")
                // Append the extracted text to the array
                self.extractedText.append(value)
            }
            .store(in: &cancellable)
    }

    private func recognizeTextRequest(_ image: UIImage) -> VNRecognizeTextRequest {

        let tagger = NLTagger(tagSchemes: [.nameTypeOrLexicalClass])

        let recognizeTextRequest = VNRecognizeTextRequest  { (request, error) in

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("Error: \(error! as NSError)")
                return
            }
            print("-------------OCR Results-------------")
            for currentObservation in observations {
                let topCandidate = currentObservation.topCandidates(1)
                if let recognizedText = topCandidate.first {
                    //OCR Results
                    print(recognizedText.string)
                }
            }
            print("-------------Tagger-------------")
            let ocrResults = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            tagger.string = ocrResults
            tagger.enumerateTags(in: ocrResults.startIndex..<ocrResults.endIndex, unit: NLTokenUnit.word, scheme: NLTagScheme.nameTypeOrLexicalClass, options: [.omitPunctuation, .omitWhitespace]) { tag, range in
                print("Tag: \(tag?.rawValue ?? "unknown") -> \(ocrResults[range])")
                return true
            }

            let fillColor: UIColor = UIColor.green.withAlphaComponent(0.3)

            let result = visualization(image, observations: observations)
        }
        recognizeTextRequest.recognitionLevel = .accurate
        return recognizeTextRequest
    }
}
