import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Typeforge Docs",
  description: "A Type Function utility library for Luau.",
  themeConfig: {
    search: {
      provider: 'local'
    },
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Docs', link: '/docs' }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/typeforge-luau/typeforge' }
    ]
  }
})
