//
//  CubeEntity.swift
//  ARBattle
//

import UIKit
import RealityKit
import Combine

enum Cube: String {
    case cube1 = "cube1"
    case cube2 = "cube2"
}
class CubeEntity: Entity, HasModel, HasPhysics, HasAnchoring, HasCollision {

    private var cube: ModelEntity?
    private var startingPosition: simd_float3?
    private var maxForce: Float = 5

    required init(cube: Cube) throws {
        super.init()

        self.cube = try ModelEntity.loadModel(named: cube.rawValue)
        self.cube?.scale = simd_float3(x: 0.4, y: 0.4, z: 0.4)
        self.cube?.name = cube.rawValue

        self.addChild(self.cube!)

        self.cube?.physicsBody = PhysicsBodyComponent()
        self.cube?.physicsBody?.mode = .static
        self.cube?.physicsBody?.massProperties = .init(mass: 1)
        self.cube?.generateCollisionShapes(recursive: true)
        
    }

    required init() {
        fatalError("init() has not been implemented")
    }

    func getEntity() -> Entity? {
        return self.cube
    }

    func getHeight() -> Float? {
        guard let maxY = self.cube?.model?.mesh.bounds.max.y,
              let minY = self.cube?.model?.mesh.bounds.min.y else {
            return nil
        }

        return maxY - minY
    }

    func setPhysicsBodyMode(to mode: PhysicsBodyMode) {
        self.cube?.physicsBody?.mode = mode
    }

    func setStartingPosition(_ pos: simd_float3) {
        self.startingPosition = pos
        self.cube?.position = pos
    }

    func restartPosition() {
        guard let pos = self.startingPosition else {
            return
        }
        self.setPhysicsBodyMode(to: .static)
        self.cube?.position = pos

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.setPhysicsBodyMode(to: .dynamic)
        }

    }

    func currentPosition() -> vector_float3? {
        return self.cube?.position
    }

    func removeFromParent() {
        self.cube?.removeFromParent()
    }

    func isCubeEntity(_ entity: Entity) -> Bool {
        return entity == self.cube
    }

    func distanceToEntity(_ entity: Entity) -> vector_float3 {
        guard let cube = self.cube else {
            return [0, 0, 0]
        }
        let a = cube.position(relativeTo: nil)
        let b = entity.position(relativeTo: nil)
        var distance: SIMD3<Float> = [0, 0, 0]
        distance.x = (a.x - b.x)
        distance.y = (a.y - b.y)
        distance.z = (a.z - b.z)
        return distance
    }

    func moveAway(from cube: CubeEntity, at side: vector_float3?) {
        guard let entity = cube.getEntity() else { return }
        let distance = self.distanceToEntity(entity)
        self.pushCube(force: [distance.x * maxForce, 0, distance.z * maxForce], at: side)
    }

    func moveCloser(to cube: CubeEntity) {
        guard let entity = cube.getEntity() else { return }
        let distance = self.distanceToEntity(entity)
        self.pushCube(force: [-(distance.x * maxForce), 0, -(distance.z * maxForce)])
    }

    func pushCube(force: vector_float3, at side: vector_float3? = nil) {
        if let side = side {
            self.cube?.addForce(force, at: side, relativeTo: nil)
        } else {
            self.cube?.addForce(force, relativeTo: nil)
        }
    }
}

