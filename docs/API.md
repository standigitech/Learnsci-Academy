# LearnSci REST API

Base URL: `/api`

## Auth

### POST `/auth/register`
Body:
```json
{"name":"Jane Doe","email":"jane@example.com","password":"Password123!","confirmPassword":"Password123!"}
```
Returns JWT and user. Frontend must route the learner to `/subscribe`.

### POST `/auth/login`
Returns JWT and subscription state.

### GET `/auth/me`
Bearer token required.

## Payments

### POST `/payments/checkout`
Body:
```json
{"plan":"monthly","method":"mpesa","phone":"254700000000"}
```

Plans:
- monthly: KSh 499
- annual: KSh 4,999

### POST `/payments/simulate-success`
Development-only gate test. Activates a subscription through the same database transition used by verified payments.

### GET `/payments/history`
Returns authenticated user's payment history.

### GET `/payments/subscriptions/me`
Returns latest subscription.

### POST `/payments/mpesa/callback`
Provider callback endpoint.

### POST `/payments/stripe/webhook`
Provider webhook endpoint.

## Premium content

`GET /lessons/:id`, `GET /quizzes/:id`, and `POST /quizzes/:id/attempts` require both authentication and an active subscription.

## Content

- `GET /subjects`
- `GET /subjects/:slug`
- `GET /articles`

## Security

Use HTTPS, secret rotation, provider signature verification, strict production CORS, database SSL, secure secrets and a production session/cookie strategy where appropriate.
