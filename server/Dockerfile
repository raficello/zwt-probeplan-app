FROM node:22-slim

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY index.js queries.js validation.js pdf.js pdf-layout.js auth.js db.js ./
COPY public ./public

ENV PORT=3000
EXPOSE 3000

CMD ["node", "index.js"]
