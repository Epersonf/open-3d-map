import React from 'react'
import Toolbar from './presentation/components/toolbar/Toolbar'

export default function App(): JSX.Element {
  return (
    <div className="app-root">
      <Toolbar />
      <main className="app">
        <h1>Electron + React + TypeScript</h1>
        <p>Aplicação básica com todos os sources em SRC usando TypeScript.</p>
      </main>
    </div>
  )
}
