FROM node:20-alpine AS base
RUN corepack enable && corepack prepare yarn@4.3.1

FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json yarn.lock .yarnrc.yml ./ 
RUN yarn --immutable

FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/.yarn ./.yarn
COPY . .
RUN yarn build

FROM base AS runner
WORKDIR /app
RUN mkdir .next
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/.next/cache ./.next/cache

ENV HOSTNAME "0.0.0.0"
EXPOSE 3000
CMD ["node", "server.js"]