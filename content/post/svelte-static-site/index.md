---
date: 2025-01-04
title: Building a static website with SvelteKit
image: images/sveltekit.png
tags: [svelte, frontend, docker]
categories: [web-dev]
---

SvelteKit can be used to build both static and server-rendered websites. I had a great experience building static websites with it multiple times, so I decided to write down the steps here.

## Create a Svelte project

First, create a new Svelte project:
```bash
npx sv create my-static-website
```

Select the following options:
1. SvelteKit minimal
2. TypeScript (optional)
3. "What would you like to add to your project?" - Nothing
4. Package manager: npm

The project should be populated with a sample page. Feel free to modify it, but we will continue with the default one for this tutorial.

## Build the project

To build a static site, we first need to install the required dependency:
```bash
npm i -D @sveltejs/adapter-static
```

Then, add the adapter to the `svelte.config.js` file:
```js
// svelte.config.js

import adapter from '@sveltejs/adapter-static';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	// Consult https://kit.svelte.dev/docs/integrations#preprocessors
	// for more information about preprocessors
	preprocess: vitePreprocess(),

	kit: {
		// adapter-auto only supports some environments, see https://kit.svelte.dev/docs/adapter-auto for a list.
		// If your environment is not supported, or you settled on a specific environment, switch out the adapter.
		// See https://kit.svelte.dev/docs/adapters for more information about adapters.
		adapter: adapter({
			// default options are shown. On some platforms
			// these options are set automatically — see below
			pages: 'build',
			assets: 'build',
			fallback: undefined,
			precompress: false,
			strict: true
		}),
        // If your repo name is not equivalent to your-username.github.io, make sure to update config.kit.paths.base to match your repo name.
        // This is because the site will be served from https://your-username.github.io/your-repo-name rather than from the root.
        paths: {
            base: process.argv.includes('dev') ? '' : process.env.BASE_PATH
        }
	}
};

export default config;
```

We also need to specify some options in `src/routes/+layout.ts` to make sure the site can be statically generated at build time:
```ts
// server-side rendering
// false = single-page application
export const ssr = false;

// client-side rendering
// false = no js on client
export const csr = true;

// Prerendering means generating HTML for a page once, at build time, rather than dynamically for each request
// no effect when running in dev mode
export const prerender = true;

// Optional: always add trailing slash to URLs
export const trailingSlash = "always";
```

We should be able to build the project now:
```bash
npm run build
```

## Deploy the site

For deployment, there are a few options as described in the [official documentation](https://svelte.dev/docs/kit/building-your-app). I like to deploy my stuff with Docker.

First, create a Dockerfile in the root of the project:
```Dockerfile
# Dockerfile
FROM node:22 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

Then, test building the Docker image:
```bash
docker build -t static:test .
```

This will produce a light-weight docker image that contains nginx and the static site.

It is totally fine to manually build and push the image for deployment, but I like to automate it with GitHub Actions. Details in [this post]({{< ref "github-actions-docker" >}}).

