import Flutter
import UIKit
import Vision

@available(iOS 15.0, *)
public class ObjectRemoverPlugin: NSObject, FlutterPlugin {
    
    var inputImage: UIImage?
    let ciContext = CIContext()
    
    lazy var model: LaMa? = {
        do {
            let config = MLModelConfiguration()
            let model = try LaMa(configuration: config)
            return model
        } catch let error {
            print(error)
            return nil
        }
    }()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "methodChannel.objectRemover", binaryMessenger: registrar.messenger())
        let instance = ObjectRemoverPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "removeObject":
            guard let args = call.arguments as? [String: Any],
                  let defaultImageUint8List = args["defaultImage"] as? FlutterStandardTypedData,
                  let maskedImageUint8List = args["maskedImage"] as? FlutterStandardTypedData else {
                result(["status": 0, "message": "Invalid arguments!"])
                return
            }
            
            guard let defaultImage = UIImage(data: defaultImageUint8List.data),
                  let maskedImage = UIImage(data: maskedImageUint8List.data) else {
                result(["status": 0, "message": "Unable to process image"])
                return
            }
            
            self.inputImage = defaultImage
            
            processImages(defaultImage: defaultImage, maskImage: maskedImage) { processedImage in
                if let processedImageData = processedImage?.pngData() {
                    result(["status": 1, "message": "Success", "imageBytes": processedImageData])
                } else {
                    result(["status": 0, "message": "Unable to object removing"])
                }
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func processImages(defaultImage: UIImage, maskImage mask: UIImage, completion: @escaping (UIImage?) -> Void) {
        let normalizedDrawingRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        
        guard let model = model else {
            completion(nil)
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                var input: LaMaInput?
                let originalSize = self.inputImage!.size
                let drawingRect = CGRect(x: normalizedDrawingRect.minX * originalSize.width, y: normalizedDrawingRect.minY * originalSize.height, width: normalizedDrawingRect.width * originalSize.width, height: normalizedDrawingRect.height * originalSize.height)
                
                input = try LaMaInput(imageWith: (self.inputImage?.cgImage!)!, maskWith: mask.cgImage!)
                
                let start = Date()
                let out = try model.prediction(input: input!)
                let pixelBuffer = out.output
                let resultCIImage = CIImage(cvPixelBuffer: pixelBuffer)
                
                guard let resultCGImage = self.ciContext.createCGImage(resultCIImage, from: resultCIImage.extent) else {
                    completion(nil)
                    return
                }
                
                let resultImage = UIImage(cgImage: resultCGImage).resize(size: originalSize)
                guard let croppedResultImage = self.cropImage(image: resultImage!, rect: drawingRect) else {
                    completion(nil)
                    return
                }
                
                let image = self.mergeImageWithRect(image1: self.inputImage!, image2: croppedResultImage, mergeRect: drawingRect)
                
                completion(image)
            } catch {
                completion(nil)
            }
        }
    }
    
    func cropImage(image: UIImage, rect: CGRect) -> UIImage? {
        if let cgImage = image.cgImage {
            let toCGImageScale = CGFloat(cgImage.width) / image.size.width
            let cropRect = CGRect(x: rect.minX * toCGImageScale, y: rect.minY * toCGImageScale, width: rect.width * toCGImageScale, height: rect.height * toCGImageScale)
            let croppedCGImage = cgImage.cropping(to: cropRect)
            return UIImage(cgImage: croppedCGImage!)
        }
        return nil
    }
    
    func mergeImageWithRect(image1: UIImage, image2: UIImage, mergeRect: CGRect) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image1.size, false, image1.scale)
        
        image1.draw(in: CGRect(x: 0, y: 0, width: image1.size.width, height: image1.size.height))
        
        image2.draw(in: mergeRect)
        
        let mergedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return mergedImage
    }
}

extension UIImage {
    func resize(size _size: CGSize) -> UIImage? {
        let aspectWidth = _size.width / size.width
        let aspectHeight = _size.height / size.height
        let aspectRatio = min(aspectWidth, aspectHeight)
        
        let scaledWidth = size.width * aspectWidth
        let scaledHeight = size.height * aspectHeight
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: scaledWidth, height: scaledHeight), false, 0.0)
        draw(in: CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
}
