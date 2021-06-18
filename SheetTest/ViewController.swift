//
//  ViewController.swift
//  SheetTest
//
//  Created by Dillon McElhinney on 6/16/21.
//

import Anchorage
import UIKit

extension UIViewController {
    var sheetPresentationController: UISheetPresentationController? {
        presentationController as? UISheetPresentationController
    }
}

class ViewController: UIViewController {
    static var preferredCornerRadius: CGFloat = 24

    private lazy var contentView: GradientView = .init()
    private let addButton = UIButton(configuration: .plain())
    private let cornerRadiusSlider = UISlider()
    private lazy var grabberAction = UIAction(title: "Grabber") { _ in
        self.updateGrabber()
    }
    private lazy var showsGrabberButton = UIButton(primaryAction: grabberAction)
    private lazy var edgeAction = UIAction(title: "Edge Attached") { _ in
        self.updateEdgeAttached()
    }
    private lazy var edgeAttachedButton = UIButton(primaryAction: edgeAction)

    private let dimmingSelection = UIButton(primaryAction: nil)

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let start = startPoints.randomElement()!
        contentView.gradientLayer.startPoint = start
        contentView.gradientLayer.endPoint = start.opposite()
        contentView.gradientLayer.colors = colorSets.randomElement()!
                                                    .map(\.cgColor)

        let arrowConfig = UIImage.SymbolConfiguration(pointSize: 36,
                                                      weight: .black)
        let arrow = UIImage(systemName: "arrow.clockwise",
                            withConfiguration: arrowConfig)
        addButton.configuration?.image = arrow
        addButton.tintColor = .white
        let addAction = UIAction { _ in self.presentSheet() }
        addButton.addAction(addAction, for: .primaryActionTriggered)

        cornerRadiusSlider.maximumValue = 60
        cornerRadiusSlider.minimumValue = 0
        cornerRadiusSlider.maximumTrackTintColor = .white.withAlphaComponent(0.3)
        cornerRadiusSlider.minimumTrackTintColor = .white
        cornerRadiusSlider.value = Float(Self.preferredCornerRadius)

        let updateRadiusAction = UIAction { _ in self.updateRadius() }
        cornerRadiusSlider.addAction(updateRadiusAction, for: .primaryActionTriggered)

        showsGrabberButton.changesSelectionAsPrimaryAction = true
        showsGrabberButton.tintColor = .white

        edgeAttachedButton.changesSelectionAsPrimaryAction = true
        edgeAttachedButton.tintColor = .white

        let dimmingHandler: UIActionHandler = { action in
            if let detent = Detent(rawValue: action.title.lowercased()) {
                self.updateDimming(detent)
            }
        }
        dimmingSelection.menu = UIMenu(children: [
            UIAction(title: "None", handler: dimmingHandler),
            UIAction(title: "Medium", handler: dimmingHandler),
            UIAction(title: "Large", handler: dimmingHandler),
        ])

        dimmingSelection.showsMenuAsPrimaryAction = true
        dimmingSelection.changesSelectionAsPrimaryAction = true
        dimmingSelection.tintColor = .white
        (dimmingSelection.menu?.children[0] as? UIAction)?.state = .on

        let buttonStack = UIStackView(arrangedSubviews: [
            showsGrabberButton, edgeAttachedButton
        ])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 20

        let stack = UIStackView(arrangedSubviews: [
            addButton, cornerRadiusSlider, buttonStack, dimmingSelection
        ])
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center

        view.addSubview(stack)
        stack.centerXAnchor == view.centerXAnchor
        stack.centerYAnchor == view.centerYAnchor + 72
        cornerRadiusSlider.horizontalAnchors == view.readableContentGuide.horizontalAnchors + 20
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        let min = min(view.frame.width, view.frame.height)
        cornerRadiusSlider.maximumValue = Float(min / 2) - 24
        cornerRadiusSlider.value = Float(sheetPresentationController?.__preferredCornerRadius ?? 24)
    }

    private func presentSheet() {
        sheetPresentationController?.animateChanges {
            sheetPresentationController?.selectedDetentIdentifier = .large
        }

        let viewController = ViewController()
        viewController.view.backgroundColor = .systemOrange

        let sheet = viewController.sheetPresentationController
        sheet?.detents = [.medium(), .large()]
        sheet?.__preferredCornerRadius = Self.preferredCornerRadius
        present(viewController, animated: true)
    }

    private func updateRadius() {
        let radius = CGFloat(cornerRadiusSlider.value)
        sheetPresentationController?.__preferredCornerRadius = radius
        Self.preferredCornerRadius = radius
    }

    private func updateGrabber() {
        showsGrabberButton.isSelected.toggle()
        sheetPresentationController?.animateChanges {
            sheetPresentationController?.prefersGrabberVisible = showsGrabberButton.isSelected
        }
    }

    private func updateEdgeAttached() {
        edgeAttachedButton.isSelected.toggle()
        sheetPresentationController?.animateChanges {
            sheetPresentationController?.prefersEdgeAttachedInCompactHeight = edgeAttachedButton.isSelected
        }
    }

    private func updateDimming(_ detent: Detent) {
        sheetPresentationController?.animateChanges {
            sheetPresentationController?.smallestUndimmedDetentIdentifier = detent.identifier
        }
    }

    enum Detent: String {
        case none, medium, large

        var identifier: UISheetPresentationController.Detent.Identifier? {
            switch self {
            case .none: return nil
            case .medium: return .medium
            case .large: return .large
            }
        }
    }
}

let colorSets: [[UIColor]] = [
    [.systemTeal, .systemGreen, .systemOrange],
    [.systemRed, .systemPurple, .systemBlue],
    [.systemPink, .systemIndigo, .systemTeal],
    [.systemPink, .systemYellow, .systemGreen],
    [.systemGreen, .systemTeal, .systemPurple],
    [.systemYellow, .systemPink, .systemIndigo],
    [.systemRed, .systemYellow, .systemTeal]
]

let startPoints: [CGPoint] = [
    CGPoint(x: 0.5, y: 0),
    CGPoint(x: 0, y: 0.3),
    CGPoint(x: 0.5, y: 1),
    CGPoint(x: 0, y: 0.8),
    CGPoint(x: 1, y: 0.3),
    CGPoint(x: 1, y: 0.8),
]

class GradientView: UIView {
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }
}

extension CGPoint {
    func opposite() -> CGPoint {
        let x = 1 - self.x
        let y = 1 - self.y
        return CGPoint(x: x, y: y)
    }
}
