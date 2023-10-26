//
//  Helper.swift
//  ReceiptsRecognizer
//
//  Created by James Kong on 21/10/2023.
//

import Foundation
import UIKit
import Vision
import SwiftUI
import NaturalLanguage

func recognizeTextRequest(_ image: UIImage) -> VNRecognizeTextRequest {

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
//recognizeTextRequest.recognitionLevel = .accurate

func request(_ image: Image) {
    request(image.snapshot())
}
func request(_ image: UIImage) {
    guard let cgImage = image.cgImage else {
        return
    }
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    DispatchQueue.global(qos: .userInitiated).async {
        do {
            try handler.perform([recognizeTextRequest(image)])
        }
        catch let error as NSError {
            print("Failed: \(error)")
        }
    }
}
//request(image)

//https://www.udemy.com/course/machine-learning-with-core-ml-2-and-swift
public func visualization(_ image: UIImage, observations: [VNDetectedObjectObservation]) -> UIImage {
    var transform = CGAffineTransform.identity
        .scaledBy(x: 1, y: -1)
        .translatedBy(x: 1, y: -image.size.height)
    transform = transform.scaledBy(x: image.size.width, y: image.size.height)

    UIGraphicsBeginImageContextWithOptions(image.size, true, 0.0)
    let context = UIGraphicsGetCurrentContext()

    image.draw(in: CGRect(origin: .zero, size: image.size))
    context?.saveGState()

    context?.setLineWidth(2)
    context?.setLineJoin(CGLineJoin.round)
    context?.setStrokeColor(UIColor.black.cgColor)
    context?.setFillColor(red: 0, green: 1, blue: 0, alpha: 0.3)

    observations.forEach { observation in
        let bounds = observation.boundingBox.applying(transform)
        context?.addRect(bounds)
    }

    context?.drawPath(using: CGPathDrawingMode.fillStroke)
    context?.restoreGState()
    let resultImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return resultImage!
}
