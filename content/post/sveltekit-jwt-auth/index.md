---
date: 2025-01-09
title: Full-stack SvelteKit web app with JWT authentication
image: images/sveltekit.png
tags: [svelte, frontend, backend, database, docker]
categories: [web-dev]
---

Recently I started a new project [Review Planner](https://github.com/jywang99/review-planner), and decided to dive a little deeper into the rabbit hole of authentication/authorization.

I have decided to use SvelteKit again, but this will be my first time using it in a truly full-stack way. Below are what I used:
1. **SvelteKit**: the framework for both frontend and backend.
2. **Drizzle**: an ORM library for TypeScript
3. **jsonwebtoken**, **bcrypt**: for encoding and decoding JWT tokens
3. **PostgreSQL**: database

This will be a step-by-step guide on how to build a full-stack application using SvelteKit, with JWT authentication.

Since it is a bit too much to cover in one post, I will split it into several parts:
1. [Developing a fullstack application with SvelteKit + Drizzle]({{< ref "/post/fullstack-sveltekit-drizzle" >}})

Source code is available on [GitHub](https://github.com/jywang99/svelte-jwt-example).

