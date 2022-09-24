const path = require('path');

module.exports = {
  plugins: [
    [
        '@docusaurus/plugin-content-docs',
        {
            id: 'iota-tips', 
            path: path.resolve(__dirname, 'tips'),
            routeBasePath: 'tips',
            editUrl: 'https://github.com/iotaledger/tips/edit/main/',
            remarkPlugins: [require('remark-import-partial')],

            async sidebarItemsGenerator({
              defaultSidebarItemsGenerator,
              ...args
            }) {
              const items = await defaultSidebarItemsGenerator(args);

              const result = items.map((item) => {
                if (item.type === 'category') {
                  if (item.link.type === 'doc') {
                    item.label = item.link.id.slice(-4) + '-' + item.label
                  }
                }
                return item;
              });

              return result;
            },
        }
    ],
  ],
  staticDirectories: [],
};