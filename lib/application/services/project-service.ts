import { Project } from "@/lib/domain/entities/project"
import { Scene } from "@/lib/domain/entities/scene"

export class ProjectService {
  createNewProject(name: string): Project {
    const defaultScene = new Scene({
      name: "Main Scene",
      rootObjects: [],
    })

    return new Project({
      name,
      version: "1.0.0",
      scenes: [defaultScene],
      tags: [],
    })
  }

  loadProject(data: any): Project {
    return Project.fromJSON(data)
  }

  saveProject(project: Project): any {
    return project.toJSON()
  }

  exportProject(project: Project): string {
    return JSON.stringify(project.toJSON(), null, 2)
  }
}
