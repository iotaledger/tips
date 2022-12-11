const { link } = require('fs');
const path = require('path');

module.exports = {
  plugins: [
    [
        '@docusaurus/plugin-content-docs',
        {
            id: 'iota-tips', 
            path: path.resolve(__dirname, './'),
            routeBasePath: 'tips',
            editUrl: 'https://github.com/iotaledger/tips/edit/main/',
            remarkPlugins: [require('remark-import-partial')],
            include: ['tips/**/*.md', 'README.md'],

            // Create own sidebar to flatten hierarchy and use own labeling
            async sidebarItemsGenerator({
              defaultSidebarItemsGenerator,
              ...args
            }) {
              const items = await defaultSidebarItemsGenerator(args);

              const result = items[1].items.map((item) => {
                if (item.type === 'category') {
                  if (item.link.type === 'doc') {
                    // Get TIP number and append TIP name
                    item.label = item.link.id.slice(-4) + '-' + item.label
                  }
                }
                return item;
              });

              return [items[0]].concat(result);
            },
        }
    ],
  ],
  staticDirectories: [],
};
