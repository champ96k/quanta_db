import type { SidebarsConfig } from '@docusaurus/plugin-content-docs';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

/**
 * Creating a sidebar enables you to:
 - create an ordered group of docs
 - render a sidebar for each doc of that group
 - provide next/previous navigation

 The sidebars can be generated from the filesystem, or explicitly defined here.

 Create as many sidebars as you want.
 */
const sidebars: SidebarsConfig = {
  // By default, Docusaurus generates a sidebar from the docs folder structure
  // tutorialSidebar: [{type: 'autogenerated', dirName: '.'}], // Comment out or remove this line

  // But you can create a sidebar manually

  tutorialSidebar: [
    'intro',
    'installation',
    'usage',
    'crud',
    'query-operations',
    'transactions',
    'error-handling',
    'batch-operations',
    {
      type: 'category',
      label: 'Features',
      items: [
        'features/high-performance',
        'features/scalable-architecture',
        'features/flexible-data-model',
        'features/reliable-durable',
        'features/easy-integration',
        'features/powerful-query-engine',
        'features/data-security',
        'features/advanced-indexing',
        'features/real-time-updates',
        'features/type-safety',
        'features/lsm_storage',
        'features/query_engine',
        'features/schema_versioning',
         'features/cross-platform',
        'features/developer-experience',
      ],
    },
  ],
};

export default sidebars;
