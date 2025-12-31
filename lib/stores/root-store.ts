import { ProjectStore } from "./project-store"
import { SceneStore } from "./scene-store"
import { SelectionStore } from "./selection-store"
import { ViewportStore } from "./viewport-store"

export class RootStore {
  projectStore: ProjectStore
  sceneStore: SceneStore
  selectionStore: SelectionStore
  viewportStore: ViewportStore

  constructor() {
    this.projectStore = new ProjectStore(this)
    this.sceneStore = new SceneStore(this)
    this.selectionStore = new SelectionStore(this)
    this.viewportStore = new ViewportStore(this)
  }
}
