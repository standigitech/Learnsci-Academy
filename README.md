# LearnSci — Learn. Understand. Excel.

A commercial-ready EdTech foundation for secondary-school and college learners studying Mathematics, Chemistry, Physics and Biology.

## Core gate

**Register → choose plan → payment → webhook/verified payment → active subscription → premium platform access.**

New learners are never dropped into a free dashboard after registration. Premium routes and APIs check an active subscription. Free teaser content is intentionally limited.

## Stack

- Frontend: React + Vite, React Router, HTML5/CSS3
- Backend: Node.js + Express
- Database: PostgreSQL
- Auth: bcrypt + JWT
- Payments: M-Pesa Daraja adapter + Stripe Checkout/webhook
- Security: Helmet, CORS, rate limiting, validation, parameterized SQL
- API style: REST

## Requirements

- Node.js 20+
- PostgreSQL 15+
- M-Pesa/Stripe credentials only for real payments

## Quick start

```bash
cp backend/.env.example backend/.env
# configure DATABASE_URL, JWT_SECRET and payment credentials
npm run install:all
createdb learnsci
npm --prefix backend run migrate
npm --prefix backend run seed
npm run dev
```

Frontend: http://localhost:5173  
Backend: http://localhost:4000

For a safe local demo, the checkout page provides **Simulate successful payment**. It activates a monthly/annual subscription through the same server-side access gate used by real payments.

## Production payment flow

1. Frontend requests a checkout session from the API.
2. Backend creates the M-Pesa STK push or Stripe Checkout Session.
3. Provider sends a server-to-server callback/webhook.
4. Backend verifies the provider event and creates/updates `payments` + `subscriptions`.
5. API access middleware checks the active subscription.
6. Frontend refreshes subscription state and unlocks premium routes.

Never put M-Pesa consumer keys, Stripe secret keys or webhook secrets in Vite client code.

## Main API

- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/auth/me`
- `POST /api/payments/checkout`
- `POST /api/payments/simulate-success` (development only)
- `POST /api/payments/mpesa/callback`
- `POST /api/payments/stripe/webhook`
- `GET /api/payments/history`
- `GET /api/subscriptions/me`
- `GET /api/subjects`
- `GET /api/lessons/:id`
- `GET /api/articles`
- `GET /api/quizzes`
- `GET /api/quizzes/:id`
- `POST /api/quizzes/:id/attempts`
- `GET /api/dashboard`
- `GET /api/teacher/dashboard`
- `GET /api/admin/dashboard`

## Test accounts after seed

- Learner: `learner@learnsci.test` / `Password123!`
- Teacher: `teacher@learnsci.test` / `Password123!`
- Admin: `admin@learnsci.test` / `Password123!`

The seeded learner has no active subscription so the paywall can be tested. Use the development simulation endpoint through the UI to unlock access.

## Testing checklist

### Gated journey
Register → plan → simulate payment → dashboard → subjects → premium lesson → quiz → progress.

### Negative paths
- Attempt premium route before payment: blocked.
- Failed checkout: remains locked.
- Expired subscription: blocked.
- Free teaser: accessible without subscription.
- Teacher/admin routes: rejected for learners.

## Deployment

Build the frontend:

```bash
npm run build
```

Serve `frontend/dist` through a CDN/static host and deploy the Express API separately. Set production CORS origins, HTTPS-only cookies if using sessions, provider webhook URLs, database SSL, and strong secrets.

## Architecture

See `docs/API.md`, `docs/ARCHITECTURE.md`, `database/schema.sql`, and `database/seed/seed.js`.
# LearnSci-Academy-Platform
