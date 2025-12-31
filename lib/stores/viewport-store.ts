import { makeAutoObservable } from "mobx"
import type { RootStore } from "./root-store"
import type { ThreeSceneAdapter } from "@/lib/infrastructure/adapters/three-scene-adapter"

export type TransformMode = "translate" | "rotate" | "scale"
export type TransformSpace = "local" | "global"

export class ViewportStore {
  transformMode: TransformMode = "translate"
  transformSpace: TransformSpace = "global"
  snapEnabled = false
  snapValue = 1
  sceneAdapter: ThreeSceneAdapter | null = null

  constructor(private rootStore: RootStore) {
    makeAutoObservable(this)
  }

  initializeAdapter(adapter: ThreeSceneAdapter) {
    this.sceneAdapter = adapter
  }

  setTransformMode(mode: TransformMode) {
    this.transformMode = mode
  }

  setTransformSpace(space: TransformSpace) {
    this.transformSpace = space
  }

  toggleSnap() {
    this.snapEnabled = !this.snapEnabled
  }

  setSnapValue(value: number) {
    this.snapValue = value
  }

  syncScene() {
    if (!this.sceneAdapter || !this.rootStore.sceneStore.currentScene) return

    this.sceneAdapter.syncFromDomain(this.rootStore.sceneStore.currentScene)
  }

  updateObjectTransform(objectId: string) {
    if (!this.sceneAdapter) return

    const object = this.rootStore.sceneStore.findObjectById(objectId)
    if (!object) return

    const threeObj = this.sceneAdapter.getThreeObject(objectId)
    if (!threeObj) return

    // Update Three.js object transform from domain
    threeObj.position.set(object.transform.position.x, object.transform.position.y, object.transform.position.z)

    threeObj.rotation.set(
      (object.transform.rotation.x * Math.PI) / 180,
      (object.transform.rotation.y * Math.PI) / 180,
      (object.transform.rotation.z * Math.PI) / 180,
    )

    threeObj.scale.set(object.transform.scale.x, object.transform.scale.y, object.transform.scale.z)
  }
}
