import { defineConfig } from 'vitepress';

export default defineConfig({
  title: 'PaperMD',
  description: '原生 macOS Markdown 编辑器',
  lang: 'zh-CN',
  base: '/',
  cleanUrls: true,
  ignoreDeadLinks: true,
  markdown: {
    image: { lazyLoading: true },
  },

  head: [
    ['link', { rel: 'icon', type: 'image/svg+xml', href: '/favicon.svg' }],
    ['meta', { name: 'author', content: 'LuoYaoSheng' }],
    ['meta', { name: 'keywords', content: 'Markdown编辑器,macOS,原生,写作工具,TextKit,PaperMD' }],
    ['meta', { property: 'og:type',        content: 'website' }],
    ['meta', { property: 'og:site_name',   content: 'PaperMD' }],
    ['meta', { property: 'og:title',       content: 'PaperMD — 原生 macOS Markdown 编辑器' }],
    ['meta', { property: 'og:description', content: '强调极致输入体验的原生 macOS Markdown 编辑器，零卡顿、光标行为 100% 可预测。' }],
    ['meta', { property: 'og:url',         content: 'https://paper.open.i2kai.com/' }],
    ['meta', { property: 'og:locale',      content: 'zh_CN' }],
    ['meta', { name: 'twitter:card',        content: 'summary_large_image' }],
    ['meta', { name: 'twitter:title',       content: 'PaperMD — 原生 macOS Markdown 编辑器' }],
    ['meta', { name: 'twitter:description', content: '强调极致输入体验的原生 macOS Markdown 编辑器。' }],
    ['meta', { name: 'theme-color', content: '#646cff' }],
  ],

  themeConfig: {
    nav: [
      { text: '首页', link: '/' },
      { text: '产品说明', link: '/产品说明' },
      { text: 'UI 设计', link: '/UI' },
    ],
    sidebar: [
      {
        text: '文档',
        items: [
          { text: '产品说明', link: '/产品说明' },
          { text: 'UI 设计', link: '/UI' },
        ],
      },
    ],
    socialLinks: [
      { icon: 'github', link: 'https://github.com/LuoYaoSheng/lys-paper-md' },
      { icon: 'github', link: 'https://gitee.com/luoyaosheng/lys-paper-md', ariaLabel: 'Gitee' },
    ],
  },
});
