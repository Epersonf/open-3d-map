import type { Scene } from "@/lib/domain/entities/scene"
import { GameObject } from "@/lib/domain/entities/game-object"
import { Transform } from "@/lib/domain/entities/transform"
import type { Vector3 } from "@/lib/domain/entities/vector3"

export class SceneService {
  createGameObject(scene: Scene, name: string, parentId?: string): GameObject {
    const gameObject = new GameObject({
      name,
      transform: new Transform(),
      tags: [],
    })

    if (parentId) {
      const parent = scene.findObjectById(parentId)
      if (parent) {
        parent.addChild(gameObject)
      } else {
        scene.addObject(gameObject)
      }
    } else {
      scene.addObject(gameObject)
    }

    return gameObject
  }

  deleteGameObject(scene: Scene, objectId: string): boolean {
    const object = scene.findObjectById(objectId)
    if (!object) return false

    if (object.parent) {
      object.parent.removeChild(object)
    } else {
      scene.removeObject(object)
    }

    return true
  }

  duplicateGameObject(scene: Scene, objectId: string): GameObject | null {
    const original = scene.findObjectById(objectId)
    if (!original) return null

    const duplicate = GameObject.fromJSON(original.toJSON())
    duplicate.name = `${original.name} (Copy)`

    if (original.parent) {
      original.parent.addChild(duplicate)
    } else {
      scene.addObject(duplicate)
    }

    return duplicate
  }

  updateTransform(gameObject: GameObject, position?: Vector3, rotation?: Vector3, scale?: Vector3): void {
    if (position) {
      gameObject.transform.position = position.clone()
    }
    if (rotation) {
      gameObject.transform.rotation = rotation.clone()
    }
    if (scale) {
      gameObject.transform.scale = scale.clone()
    }
  }

  reparentGameObject(scene: Scene, objectId: string, newParentId: string | null): boolean {
    const object = scene.findObjectById(objectId)
    if (!object) return false

    // Remove from current parent
    if (object.parent) {
      object.parent.removeChild(object)
    } else {
      scene.removeObject(object)
    }

    // Add to new parent
    if (newParentId) {
      const newParent = scene.findObjectById(newParentId)
      if (!newParent) return false
      newParent.addChild(object)
    } else {
      scene.addObject(object)
    }

    return true
  }
}
