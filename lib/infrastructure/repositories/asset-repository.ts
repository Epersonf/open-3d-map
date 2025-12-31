export interface AssetImportResult {
  fileName: string
  data: string
  path: string
}

export interface IAssetRepository {
  import(): Promise<AssetImportResult>
}

export class ElectronAssetRepository implements IAssetRepository {
  async import(): Promise<AssetImportResult> {
    if (typeof window === "undefined" || !window.electronAPI) {
      throw new Error("Electron API not available")
    }

    const result = await window.electronAPI.asset.import()

    if (!result.success) {
      if (result.canceled) {
        throw new Error("User canceled import")
      }
      throw new Error(result.error || "Failed to import asset")
    }

    return {
      fileName: result.fileName!,
      data: result.data!,
      path: result.path!,
    }
  }
}
