import type { Project } from "@/lib/domain/entities/project"
import type { GameObject } from "@/lib/domain/entities/game-object"

export class TagService {
  getAllProjectTags(project: Project): string[] {
    const tags = new Set<string>(project.tags)

    project.scenes.forEach((scene) => {
      scene.getAllObjects().forEach((obj) => {
        obj.tags.forEach((tag) => tags.add(tag))
      })
    })

    return Array.from(tags).sort()
  }

  addTagToProject(project: Project, tag: string): void {
    if (!project.tags.includes(tag)) {
      project.tags.push(tag)
    }
  }

  removeTagFromProject(project: Project, tag: string): void {
    const index = project.tags.indexOf(tag)
    if (index > -1) {
      project.tags.splice(index, 1)
    }
  }

  findObjectsWithTag(project: Project, tag: string): GameObject[] {
    const result: GameObject[] = []

    project.scenes.forEach((scene) => {
      scene.getAllObjects().forEach((obj) => {
        if (obj.hasTag(tag)) {
          result.push(obj)
        }
      })
    })

    return result
  }
}
