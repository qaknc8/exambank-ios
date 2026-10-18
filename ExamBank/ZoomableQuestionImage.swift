import SwiftUI
import UIKit

struct ZoomableQuestionImage: UIViewRepresentable {
    let image: UIImage?
    let resetToken: Int

    func makeUIView(context: Context) -> ZoomingScrollView {
        let view = ZoomingScrollView()
        view.setImage(image)
        context.coordinator.token = resetToken
        return view
    }

    func updateUIView(_ view: ZoomingScrollView, context: Context) {
        if context.coordinator.token != resetToken {
            context.coordinator.token = resetToken
            view.setImage(image)
            return
        }
        if view.currentImage !== image {
            view.setImage(image)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var token = -1
    }
}

final class ZoomingScrollView: UIScrollView, UIScrollViewDelegate {
    private let imageView = UIImageView()
    private var configuredSize: CGSize = .zero
    private var fitAllScale: CGFloat = 1
    private var fitWidthScale: CGFloat = 1

    var currentImage: UIImage? { imageView.image }

    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
        bouncesZoom = true
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        decelerationRate = .fast
        backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)

        let doubleTap = UITapGestureRecognizer(
            target: self,
            action: #selector(handleDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImage(_ image: UIImage?) {
        imageView.image = image
        configuredSize = .zero
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        configureIfNeeded()
    }

    private func configureIfNeeded() {
        guard let size = imageView.image?.size, size.width > 0, size.height > 0,
              bounds.width > 0, bounds.height > 0 else { return }

        let fitAll = min(bounds.width / size.width, bounds.height / size.height)
        let fitWidth = bounds.width / size.width
        guard configuredSize != bounds.size
                || abs(fitAllScale - fitAll) > 0.0001
                || abs(fitWidthScale - fitWidth) > 0.0001 else { return }

        configuredSize = bounds.size
        fitAllScale = fitAll
        fitWidthScale = fitWidth
        imageView.frame = CGRect(origin: .zero, size: size)
        minimumZoomScale = fitAll
        maximumZoomScale = max(fitWidth * 4, fitAll + 0.25)
        zoomScale = fitWidth
        centerContent()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView.image == nil ? nil : imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent()
    }

    private func centerContent() {
        guard imageView.image != nil else { return }
        let scaledWidth = imageView.bounds.width * zoomScale
        let scaledHeight = imageView.bounds.height * zoomScale
        let horizontal = max((bounds.width - scaledWidth) / 2, 0)
        let vertical = max((bounds.height - scaledHeight) / 2, 0)
        contentInset = UIEdgeInsets(
            top: vertical,
            left: horizontal,
            bottom: vertical,
            right: horizontal
        )
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard imageView.image != nil else { return }
        if zoomScale > fitWidthScale * 1.05 {
            setZoomScale(fitWidthScale, animated: true)
        } else {
            let point = gesture.location(in: imageView)
            let target = min(max(fitWidthScale * 2.2, minimumZoomScale), maximumZoomScale)
            guard target > zoomScale else { return }
            let width = bounds.width / target
            let height = bounds.height / target
            let rect = CGRect(
                x: point.x - width / 2,
                y: point.y - height / 2,
                width: width,
                height: height
            )
            zoom(to: rect, animated: true)
        }
    }
}
