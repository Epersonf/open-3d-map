# Electron + React (básico)

Todos os sources estão na pasta `src`.

Pré-requisitos

- Node.js (>=18 recomendado)

Instalação

```bash
npm install
```

Modo desenvolvimento (abre webpack-dev-server + Electron):

```bash
npm run dev
```

- Esse script usa `concurrently` e `wait-on` para iniciar o dev server do webpack e, em seguida, o Electron.

Build (renderer com webpack):

```bash
npm run build
```

Iniciar (após build):

```bash
npm start
```

Estrutura importante

- `src/main.js` — processo principal do Electron
- `src/preload.js` — preload script (contextBridge)
- `src/renderer` — app React (tudo dentro de `SRC`)
- `vite.config.cjs` — configuração do Vite apontando para `src/renderer`

Observações

- Para empacotar a aplicação (installer), recomendo adicionar e configurar `electron-builder` ou `electron-forge` conforme sua necessidade.
- Se preferir, posso ajustar para TypeScript ou adicionar empacotamento automático.
