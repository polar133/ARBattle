//
//  BattleARView.swift
//  ARBattle
//

import Foundation
import ARKit
import Combine
import RealityKit

class BattleARView: ARView {

    // Combine properties
    private weak var viewModel: ARViewModel?
    private var cancellables: Set<AnyCancellable> = []

    // Properties
    private var coachingOverlay: ARCoachingOverlayView?
    private var cube1: CubeEntity?
    private var cube2: CubeEntity?
    private var crosshair: CrosshairEntity?

    private var meshAnchors: [ARMeshAnchor] = [] {
        didSet {
            if meshAnchors.count > 0 {
                viewModel?.blocksCanBePlaced = true
            }
        }
    }

    convenience init(viewModel: ARViewModel) {
        self.init(frame: .zero)
        self.viewModel = viewModel
        setupActions()
        initAR()
    }

    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
    }

    required init?(coder decoder: NSCoder) {
        return nil
    }

    func setupActions() {
        viewModel?.actions.sink { action in
            switch action {
            case .start:
                self.setupAR()
                self.viewModel?.hasStarted.toggle()
            case .reset:
                self.restartScan()
            case .debug(enabled: let enabled):
                self.modifyDebugOptions(isDebugEnabled: enabled)
            case .placeBlocks:
                self.initCubes()
            case .restartBlocks:
                self.restartCubes()
                break
            }
        }.store(in: &cancellables)
    }

    func initAR() {
        session.delegate = self
        environment.sceneUnderstanding.options = []
        environment.sceneUnderstanding.options.insert(.occlusion)
        environment.sceneUnderstanding.options.insert(.physics)

        self.debugOptions = []
        self.renderOptions = [.disablePersonOcclusion, .disableDepthOfField, .disableMotionBlur]

        self.automaticallyConfigureSession = false
    }

    func setupAR(restart: Bool = false) {

        setupScanOverlay()

        let configuration = ARWorldTrackingConfiguration()
        configuration.sceneReconstruction = .meshWithClassification
        configuration.environmentTexturing = .automatic
        configuration.planeDetection = [.horizontal]
        configuration.worldAlignment = .gravity
        if restart {
            session.run(configuration, options: .resetSceneReconstruction)
        } else {
            session.run(configuration)
        }
        setGestures()

        initCrosshair()
    }

    // TODO: This funciton should present an alert to ask for camera permission if it was rejected.
    func handlePermissionCamera() {

    }

    func restartScan() {
        self.handlePermissionCamera()

        self.cube1?.removeFromParent()
        self.cube2?.removeFromParent()
        self.crosshair = nil

        setupAR(restart: true)
        scene.anchors.forEach {
            let anchor = $0
            anchor.children.forEach { anchor.removeChild($0) }
            scene.removeAnchor(anchor)
        }

        self.cube1 = nil
        self.cube2 = nil

        self.meshAnchors = []
        self.viewModel?.blocksArePlaced = false
    }

    func setupScanOverlay() {

        coachingOverlay = ARCoachingOverlayView(frame: bounds)
        coachingOverlay?.translatesAutoresizingMaskIntoConstraints = false
        coachingOverlay?.session = session
        coachingOverlay?.goal = .horizontalPlane
        coachingOverlay?.delegate = self

        guard let coachingOverlay = coachingOverlay else {
            return
        }

        addSubview(coachingOverlay)

        coachingOverlay.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        coachingOverlay.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true

        coachingOverlay.activatesAutomatically = true
        coachingOverlay.setActive(true, animated: true)
    }

    func modifyDebugOptions(isDebugEnabled: Bool) {
        if isDebugEnabled {
            self.debugOptions.insert(.showSceneUnderstanding)
            self.debugOptions.insert(.showPhysics)
        } else {
            self.debugOptions.remove(.showSceneUnderstanding)
            self.debugOptions.remove(.showPhysics)
        }
        self.viewModel?.isDebugEnabled = self.debugOptions.contains(.showSceneUnderstanding)
    }

    func initCubes() {

        self.cube1 = self.placeCube(name: Cube.cube1, move: false)
        self.cube2 = self.placeCube(name: Cube.cube2, move: true)

        guard let cube1 = self.cube1, let cube2 = self.cube2 else {
            /// Cubes are not placed correctly, better to clean and start over
            self.cube1?.removeFromParent()
            self.cube2?.removeFromParent()
            return
        }
        cube1.setPhysicsBodyMode(to: .dynamic)
        cube2.setPhysicsBodyMode(to: .dynamic)
        self.viewModel?.blocksArePlaced = true

        hideCrosshair()
    }

    func restartCubes() {
        self.cube1?.restartPosition()
        self.cube2?.restartPosition()
    }

    func initCrosshair() {
        crosshair = CrosshairEntity()
        let anchor = AnchorEntity(plane: .horizontal)
        anchor.addChild(crosshair!)
        crosshair?.isEnabled = true
        scene.addAnchor(anchor)
    }

    func hideCrosshair() {
        crosshair?.isEnabled = false
    }

    func placeCube(name: Cube, move: Bool) -> CubeEntity? {
        
        guard let entity = try? CubeEntity(cube: name) else {
            return nil
        }

        let anchor = AnchorEntity(plane: .horizontal)
        anchor.addChild(entity)

        let position = getPosition(extra: (x: 0, y: entity.getHeight() ?? 0, z: move ? -1 : 0))

        guard isValidPosition(position: position) else {
            self.viewModel?.showNoMeshDetectedMessage()
            return nil
        }

        entity.setStartingPosition(position)

        let gesture = installGestures(for: entity)
        gesture.forEach { $0.delegate = self }

        scene.addAnchor(anchor)

        return entity
    }

    func getPosition(extra: (x:Float, y:Float, z:Float) = (0,0,0)) -> simd_float3 {

        return simd_float3(x: crosshair!.position.x + extra.x,
                           y: crosshair!.position.y + extra.y,
                           z: crosshair!.position.z + extra.z)

    }

    func isValidPosition(position: simd_float3) -> Bool {
        var meshAnchors: [ARMeshAnchor] = self.meshAnchors
        let cutoffDistance: Float = 1.0
        meshAnchors.removeAll { distance($0.transform.position, position) > cutoffDistance }
        meshAnchors.sort { distance($0.transform.position, position) < distance($1.transform.position, position) }
        return meshAnchors.count > 0
    }

    func setGestures() {
        let gestureRecognizer = UITapGestureRecognizer(target: self,
                                                       action: #selector(tapped))
        self.addGestureRecognizer(gestureRecognizer)
    }

    @objc func tapped(gesture: UITapGestureRecognizer) {
        guard gesture.view != nil else { return }

        let screenLocation = gesture.location(in: self)
        let hits = hitTest(screenLocation, query: .nearest, mask: .all)

        for hit in hits {
            if self.cube1?.isCubeEntity(hit.entity) == true, let cube2 = self.cube2 {
                self.cube1?.moveCloser(to: cube2)
            } else if self.cube2?.isCubeEntity(hit.entity) == true, let cube1 = self.cube1 {
                self.cube2?.moveAway(from: cube1, at: hit.position)
            }
        }
    }

    func updateCrosshair() {
        guard let raycastResult = self.raycast(from: CGPoint(x: self.bounds.midX, y: self.bounds.midY), allowing: .estimatedPlane, alignment: .horizontal).first
        else { return }

        let cameraTransform = cameraTransform
        let resultWorldPosition = raycastResult.worldTransform.position
        let rayDirection = normalize(resultWorldPosition - cameraTransform.translation)
        let textPositionInWorldCoordinates = resultWorldPosition - (rayDirection * 0.1)

        var transform = Transform(matrix: raycastResult.worldTransform)
        transform.translation = textPositionInWorldCoordinates

        self.crosshair?.move(to: transform, relativeTo: nil, duration: 0.1)
    }
}

extension BattleARView: ARSessionDelegate, ARCoachingOverlayViewDelegate {

    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        self.viewModel?.planeHasBeenFound = true
    }

    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        self.viewModel?.planeHasBeenFound = false
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let meshAnchor = anchor as? ARMeshAnchor  {
                meshAnchors.append(meshAnchor)
            }
        }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .horizontal, planeAnchor.classification != .ceiling {
                updateCrosshair()
            }
        }
    }



}
