import { makeAutoObservable } from "mobx"
import type { RootStore } from "./root-store"
import type { Scene } from "@/lib/domain/entities/scene"
import { SceneService } from "@/lib/application/services/scene-service"
import type { Vector3 } from "@/lib/domain/entities/vector3"

export class SceneStore {
  currentScene: Scene | null = null
  private sceneService: SceneService

  constructor(private rootStore: RootStore) {
    makeAutoObservable(this)
    this.sceneService = new SceneService()
  }

  setCurrentScene(scene: Scene) {
    this.currentScene = scene
    // Notify viewport to sync
    this.rootStore.viewportStore.syncScene()
  }

  createGameObject(name: string, parentId?: string) {
    if (!this.currentScene) return null

    const gameObject = this.sceneService.createGameObject(this.currentScene, name, parentId)

    // Notify viewport to add object
    this.rootStore.viewportStore.syncScene()

    return gameObject
  }

  deleteGameObject(objectId: string) {
    if (!this.currentScene) return false

    const success = this.sceneService.deleteGameObject(this.currentScene, objectId)

    if (success) {
      // Clear selection if deleted object was selected
      if (this.rootStore.selectionStore.selectedObjects.includes(objectId)) {
        this.rootStore.selectionStore.clearSelection()
      }

      // Notify viewport to remove object
      this.rootStore.viewportStore.syncScene()
    }

    return success
  }

  duplicateGameObject(objectId: string) {
    if (!this.currentScene) return null

    const duplicate = this.sceneService.duplicateGameObject(this.currentScene, objectId)

    if (duplicate) {
      // Notify viewport to add object
      this.rootStore.viewportStore.syncScene()
    }

    return duplicate
  }

  updateObjectTransform(objectId: string, position?: Vector3, rotation?: Vector3, scale?: Vector3) {
    if (!this.currentScene) return

    const object = this.currentScene.findObjectById(objectId)
    if (!object) return

    this.sceneService.updateTransform(object, position, rotation, scale)

    // Notify viewport to update transform
    this.rootStore.viewportStore.updateObjectTransform(objectId)
  }

  reparentObject(objectId: string, newParentId: string | null) {
    if (!this.currentScene) return false

    const success = this.sceneService.reparentGameObject(this.currentScene, objectId, newParentId)

    if (success) {
      // Notify viewport to update hierarchy
      this.rootStore.viewportStore.syncScene()
    }

    return success
  }

  getAllObjects() {
    return this.currentScene?.getAllObjects() || []
  }

  findObjectById(id: string) {
    return this.currentScene?.findObjectById(id) || null
  }
}
