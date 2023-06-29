//
//  CrosshairEntity.swift
//  ARBattle
//

import RealityKit
import ARKit

class CrosshairEntity: Entity, HasModel, HasAnchoring, HasCollision {

    required init() {
        super.init()
        self.didSetup()
    }

    fileprivate func didSetup() {
        let model = generateModel()
        self.addChild(model)
        self.generateCollisionShapes(recursive: true)
    }

    func generateModel() -> ModelEntity {
        let mesh: MeshResource =  MeshResource.generatePlane(width: 0.2, depth: 0.2)
        var material = SimpleMaterial()
        material.color = .init(tint: .white.withAlphaComponent(0.999), texture: .init(try! .load(named: "crosshair.png")))
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.name = "crosshair"
        return model
    }
}
