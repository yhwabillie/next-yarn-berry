FROM node:20-alpine AS base

FROM base AS deps
RUN corepack enable && corepack prepare yarn@4.3.1
WORKDIR /app
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn/releases/yarn-4.3.1.cjs ./.yarn/releases/yarn-4.3.1.cjs
RUN yarn install --immutable

FROM base AS builder
RUN corepack enable && corepack prepare yarn@4.3.1
WORKDIR /app
COPY --from=deps /app/.yarn ./.yarn
COPY --from=deps /app/.pnp.cjs ./.pnp.cjs
COPY --from=deps /app/.pnp.loader.mjs ./.pnp.loader.mjs
COPY . .
RUN yarn build

FROM base AS runner
WORKDIR /app
COPY --from=builder /app/public ./public
COPY --from=builder /app/.pnp.cjs ./
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

RUN rm -rf ./.yarn
# COPY --from=builder /app/.yarn/cache ./.yarn/cache

COPY --from=builder /app/.yarn/cache ./.yarn/cache
COPY --from=builder /app/.yarn/releases ./.yarn/releases
# COPY --from=builder /app/.yarn/unplugged ./.yarn/unplugged
# COPY --from=builder /app/.yarn/install-state.gz ./.yarn/install-state.gz

ENV HOSTNAME "0.0.0.0"
EXPOSE 3000
CMD ["node", "-r", "/app/.pnp.cjs", "/app/server.js"]