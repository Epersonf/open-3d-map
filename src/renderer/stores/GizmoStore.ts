import { makeAutoObservable } from 'mobx'

export type TransformMode = 'translate' | 'rotate' | 'scale'
export type SpaceMode = 'local' | 'global'

export class GizmoStore {
  transformMode: TransformMode = 'translate'
  spaceMode: SpaceMode = 'local'
  snapEnabled: boolean = false
  snapGrid: number = 1

  constructor() {
    makeAutoObservable(this)
  }

  setTransformMode(mode: TransformMode) {
    this.transformMode = mode
  }

  setSpaceMode(mode: SpaceMode) {
    this.spaceMode = mode
  }

  toggleSnap() {
    this.snapEnabled = !this.snapEnabled
  }

  setSnapGrid(value: number) {
    if (value <= 0) return
    this.snapGrid = value
  }
}

export default GizmoStore
