import { defineConfig } from 'vite'
import { readdirSync } from 'fs'

const ROMS_ID = '\0virtual:roms'

export default defineConfig({
  base: './',
  plugins: [
    {
      name: 'assets',
      resolveId: (id) => (id === 'virtual:roms' ? ROMS_ID : null),
      load: (id) =>
        id === ROMS_ID
          ? `export default ${JSON.stringify(readdirSync('public/_roms').filter((n) => n.endsWith('.ch8')).sort())}`
          : null
    }
  ]
})
