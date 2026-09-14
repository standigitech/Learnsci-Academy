# Architecture

## Frontend

React + Vite:
- `layouts/` app shell and auth shell
- `components/` reusable UI and route gate
- `pages/` feature screens
- `services/` API client
- `hooks/` auth state
- `styles/` design system

## Backend

Express REST API:
- controllers contain request/response logic
- routes map resources
- middleware enforces authentication, RBAC and subscription state
- services can hold provider integrations
- config centralizes environment variables
- PostgreSQL stores normalized relational data

## Access control

The server is authoritative:

`JWT -> user -> role -> active subscription -> resource`

The frontend gate improves UX but never replaces server-side authorization.

## Payment lifecycle

`checkout request -> provider -> webhook/callback -> verified payment -> subscription active -> premium API allowed`

For M-Pesa, production implementation should create an STK Push using Daraja, persist the checkout request, validate the callback result and reconcile the transaction reference before activating access.

For Stripe, use Checkout Sessions and verify the webhook signature with the raw request body before changing subscription state.

## Scaling notes

For production:
- Redis for rate-limit/session/cache workloads
- object storage + signed URLs for PDFs/video
- background job queue for emails, certificates and webhook retries
- PostgreSQL read replicas as traffic grows
- CDN for public assets
- search service or PostgreSQL full-text search
- observability with structured logs, metrics and tracing
