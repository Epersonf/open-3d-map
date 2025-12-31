"use client"

import { useEffect, useState } from "react"

export function ElectronStatus() {
  const [isElectron, setIsElectron] = useState(false)
  const [apiStatus, setApiStatus] = useState("checking...")

  useEffect(() => {
    const checkElectron = () => {
      const hasElectron = typeof window !== "undefined" && (window as any).electronAPI !== undefined
      setIsElectron(hasElectron)

      if (hasElectron) {
        setApiStatus("✅ Electron API available")
        // eslint-disable-next-line no-console
        console.log("Electron API available:", (window as any).electronAPI)
      } else {
        setApiStatus("❌ Electron API not available")
        // eslint-disable-next-line no-console
        console.log("Running in browser mode")
      }
    }

    checkElectron()
  }, [])

  return (
    <div className="fixed bottom-4 right-4 bg-black/80 text-white p-3 rounded-lg text-sm font-mono z-50">
      <div>Electron: {isElectron ? "✅" : "❌"}</div>
      <div>Status: {apiStatus}</div>
      <div>User Agent: {typeof navigator !== "undefined" ? navigator.userAgent : "unknown"}</div>
    </div>
  )
}
