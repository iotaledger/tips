> **Note**
> This guide is meant for local development and contributing to the repository only, for guidance on the TIPs process and how to propose Tangle improvements, please see the [README](README.md)


# Documentation

The TIPs online documentation is built using [Docusaurus 2](https://docusaurus.io/). The deployment is done through a centralized build from [IOTA WIKI](https://github.com/iota-wiki/iota-wiki). To run a local instance, the [IOTA WIKI CLI](https://www.npmjs.com/package/@iota-wiki/cli) is used.

## Prerequisites

- [Node.js 16.10 or above](https://nodejs.org/en/download/).
- [Modern Yarn](https://yarnpkg.com/getting-started/install) enabled by running `corepack enable`.

## Installation

```console
yarn
```

This command installs all necessary dependencies.

## Local Development

```console
yarn start
```

This command starts a local, wiki themed development server and opens up a browser window. Most changes are reflected live without having to restart the server.
