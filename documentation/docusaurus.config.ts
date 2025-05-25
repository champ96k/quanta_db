import { themes as prismThemes } from 'prism-react-renderer';
import type { Config } from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const config: Config = {
  title: 'QuantaDB',
  tagline: 'A powerful and efficient database solution',
  favicon: 'img/logo_small.png',

  // Set the production url of your site here
  url: 'https://quantadb.netlify.app',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'tusharnikam', // Usually your GitHub org/user name.
  projectName: 'quanta_db', // Usually your repo name.

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          editUrl: 'https://github.com/champ96k/quanta_db/tree/master/documentation/',
        },
        blog: {
          showReadingTime: true,
          feedOptions: {
            type: ['rss', 'atom'],
            xslt: true,
          },
          editUrl: 'https://github.com/champ96k/quanta_db/tree/master/documentation/',
          blogTitle: 'QuantaDB Blog',
          blogDescription: 'Updates and announcements from the QuantaDB team',
          postsPerPage: 10,
          blogSidebarTitle: 'Recent Posts',
          blogSidebarCount: 5,
          onInlineTags: 'warn',
          onInlineAuthors: 'warn',
          onUntruncatedBlogPosts: 'ignore',
        },
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    // Replace with your project's social card
    image: 'img/docusaurus-social-card.jpg',
    navbar: {
      title: 'QuantaDB',
      logo: {
        alt: 'QuantaDB Logo',
        src: 'img/logo_small.png',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'tutorialSidebar',
          position: 'left',
          label: 'Documentation',
        },
        { to: '/blog', label: 'Blog', position: 'left' },
        {
          href: 'https://github.com/champ96k/quanta_db',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/champ96k/quanta_db',
            },
            {
              label: 'Issues',
              href: 'https://github.com/champ96k/quanta_db/issues',
            },
            {
              label: 'FAQ',
              href: 'https://github.com/champ96k/quanta_db/wiki/QuantaDB-Frequently-Asked-Questions',
            },
            {
              label: 'Blog',
              to: '/blog',
            },
            {
              label: 'Roadmap',
              href: 'https://github.com/champ96k/quanta_db/blob/master/roadmap.md',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} QuantaDB. Made with ❤️ by Tushar Nikam`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
