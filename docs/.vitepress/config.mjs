import { defineConfig } from 'vitepress';

export default defineConfig({
  title: 'PaperMD',
  description: '原生 macOS Markdown 编辑器',
  lang: 'zh-CN',
  cleanUrls: true,
  ignoreDeadLinks: true,
  markdown: {
    image: {
      lazyLoading: true,
    },
  },
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
    ],
  },
});
