import UIKit

final class ImageLoader {
    static let shared = ImageLoader()

    private let cache = NSCache<NSURL, UIImage>()
    private let queue = DispatchQueue(
        label: "examBank.imageLoader",
        qos: .userInitiated,
        attributes: .concurrent
    )

    private init() {
        cache.countLimit = 5
    }

    func image(for url: URL, completion: @escaping (UIImage?) -> Void) {
        let key = url as NSURL
        if let cached = cache.object(forKey: key) {
            completion(cached)
            return
        }

        queue.async {
            let image = UIImage(contentsOfFile: url.path)
            if let image {
                self.cache.setObject(image, forKey: key)
            }
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
}
