import * as THREE from "three"
import type { Scene } from "@/lib/domain/entities/scene"
import type { GameObject } from "@/lib/domain/entities/game-object"

export class ThreeSceneAdapter {
  private threeScene: THREE.Scene
  private objectMap: Map<string, THREE.Object3D>

  constructor() {
    this.threeScene = new THREE.Scene()
    this.objectMap = new Map()
  }

  getThreeScene(): THREE.Scene {
    return this.threeScene
  }

  syncFromDomain(domainScene: Scene): void {
    // Clear existing objects
    this.threeScene.clear()
    this.objectMap.clear()

    // Add all domain objects to Three.js scene
    domainScene.rootObjects.forEach((obj) => {
      const threeObj = this.createThreeObject(obj)
      this.threeScene.add(threeObj)
    })
  }

  private createThreeObject(gameObject: GameObject): THREE.Object3D {
    const group = new THREE.Group()
    group.name = gameObject.name
    group.userData.domainId = gameObject.id

    // Set transform
    group.position.set(
      gameObject.transform.position.x,
      gameObject.transform.position.y,
      gameObject.transform.position.z,
    )

    group.rotation.set(
      (gameObject.transform.rotation.x * Math.PI) / 180,
      (gameObject.transform.rotation.y * Math.PI) / 180,
      (gameObject.transform.rotation.z * Math.PI) / 180,
    )

    group.scale.set(gameObject.transform.scale.x, gameObject.transform.scale.y, gameObject.transform.scale.z)

    // Add a default cube mesh for visualization
    const geometry = new THREE.BoxGeometry(1, 1, 1)
    const material = new THREE.MeshStandardMaterial({ color: 0x4488ff })
    const mesh = new THREE.Mesh(geometry, material)
    group.add(mesh)

    // Store mapping
    this.objectMap.set(gameObject.id, group)

    // Recursively add children
    gameObject.children.forEach((child) => {
      const childObj = this.createThreeObject(child)
      group.add(childObj)
    })

    return group
  }

  updateObjectTransform(
    objectId: string,
    position?: THREE.Vector3,
    rotation?: THREE.Euler,
    scale?: THREE.Vector3,
  ): void {
    const threeObj = this.objectMap.get(objectId)
    if (!threeObj) return

    if (position) threeObj.position.copy(position)
    if (rotation) threeObj.rotation.copy(rotation)
    if (scale) threeObj.scale.copy(scale)
  }

  getThreeObject(objectId: string): THREE.Object3D | undefined {
    return this.objectMap.get(objectId)
  }

  removeObject(objectId: string): void {
    const threeObj = this.objectMap.get(objectId)
    if (!threeObj) return

    threeObj.removeFromParent()
    this.objectMap.delete(objectId)
  }
}
