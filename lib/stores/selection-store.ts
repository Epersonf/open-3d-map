import { makeAutoObservable } from "mobx"
import type { RootStore } from "./root-store"

export class SelectionStore {
  selectedObjects: string[] = []

  constructor(private rootStore: RootStore) {
    makeAutoObservable(this)
  }

  select(objectId: string) {
    this.selectedObjects = [objectId]
  }

  addToSelection(objectId: string) {
    if (!this.selectedObjects.includes(objectId)) {
      this.selectedObjects.push(objectId)
    }
  }

  removeFromSelection(objectId: string) {
    const index = this.selectedObjects.indexOf(objectId)
    if (index > -1) {
      this.selectedObjects.splice(index, 1)
    }
  }

  clearSelection() {
    this.selectedObjects = []
  }

  isSelected(objectId: string): boolean {
    return this.selectedObjects.includes(objectId)
  }

  get firstSelected(): string | null {
    return this.selectedObjects.length > 0 ? this.selectedObjects[0] : null
  }
}
