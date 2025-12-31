import { makeAutoObservable } from 'mobx'

export interface GameObject {
  id: string
  name: string
  transform: {
    position: { x: number; y: number; z: number }
    rotation: { x: number; y: number; z: number }
    scale: { x: number; y: number; z: number }
  }
  tags: Record<string, string>
}

export class SelectionStore {
  selectedObject: GameObject | null = null

  constructor() {
    makeAutoObservable(this)
  }

  selectObject(obj: GameObject | null) {
    this.selectedObject = obj
  }

  updateTransform(axis: string, component: 'x' | 'y' | 'z', value: number) {
    if (!this.selectedObject) return
    const [transformType, coord] = axis.split('.')
    if (transformType === 'position' || transformType === 'rotation' || transformType === 'scale') {
      (this.selectedObject.transform as any)[transformType][coord] = value
    }
  }

  addTag(key: string, value: string) {
    if (!this.selectedObject) return
    this.selectedObject.tags[key] = value
  }

  removeTag(key: string) {
    if (!this.selectedObject) return
    delete this.selectedObject.tags[key]
  }

  updateTag(key: string, newValue: string) {
    if (!this.selectedObject) return
    this.selectedObject.tags[key] = newValue
  }
}

export default SelectionStore
