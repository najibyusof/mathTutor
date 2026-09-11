# MathTutor API Documentation

Base URL: `https://<host>/api/v1`

All responses use a single JSON envelope:

```json
{
    "success": true,
    "message": "Request successful",
    "data": {}
}
```

Validation and application errors:

```json
{
    "success": false,
    "message": "Validation failed",
    "errors": { "field": ["The field is required."] },
    "code": "VALIDATION_ERROR"
}
```

List endpoints add a `meta` object alongside `data` with pagination info:

```json
{
    "success": true,
    "message": "Questions retrieved successfully",
    "data": [
        /* ... */
    ],
    "meta": { "current_page": 1, "per_page": 15, "last_page": 3, "total": 42 }
}
```

## Conventions

- **Authentication**: Bearer token via Laravel Sanctum personal access tokens, obtained from `POST /auth/register` or `POST /auth/login`.
- **Headers** (unless noted otherwise, on every request):
    - `Accept: application/json`
    - `Content-Type: application/json` (or `multipart/form-data` for file uploads)
    - `Authorization: Bearer <token>` (for protected endpoints)
- **Ownership**: every resource (question, solution, recognition attempt, tutor session, notification, history entry) belongs to exactly one user. Accessing another user's resource returns `403 FORBIDDEN`; an unknown id returns `404 NOT_FOUND`. The client can never set `user_id` — it is always taken from the bearer token.
- **Rate limiting**: `auth` routes are limited to 10 requests/minute per email+IP; `recognition` routes to 15 requests/minute per user; AI (`explanation`/`hint`) routes to 20 requests/minute per user; every other authenticated route falls under the general API limit of 60 requests/minute per user. Exceeding a limit returns `429 TOO_MANY_REQUESTS`.
- **Common error codes**: `VALIDATION_ERROR` (422), `UNAUTHENTICATED` (401), `FORBIDDEN` (403), `NOT_FOUND` (404), `METHOD_NOT_ALLOWED` (405), `TOO_MANY_REQUESTS` (429), `SERVER_ERROR` (500). Endpoint-specific codes are listed per endpoint below.

---

## Table of contents

1. [Authentication](#1-authentication)
2. [Profile](#2-profile)
3. [Questions](#3-questions)
4. [Recognition](#4-recognition)
5. [Solutions](#5-solutions)
6. [AI Explanations](#6-ai-explanations)
7. [History](#7-history)
8. [Tutor](#8-tutor)
9. [Notifications](#9-notifications)
10. [Health Check](#10-health-check)
11. [Workflows](#11-workflows)

---

## 1. Authentication

### POST /auth/register

Creates an account and returns a bearer token. Public endpoint (`throttle:auth`).

- **Auth required**: No
- **Body**:

| Field                   | Type   | Rules                                                           |
| ----------------------- | ------ | --------------------------------------------------------------- |
| `name`                  | string | required, min:2, max:255                                        |
| `email`                 | string | required, valid email, unique                                   |
| `password`              | string | required, confirmed, min 10 chars, mixed case, numbers, symbols |
| `password_confirmation` | string | required, must match `password`                                 |
| `device_name`           | string | optional, max:255 (labels the issued token)                     |

```json
{
    "name": "Ada Lovelace",
    "email": "ada@example.com",
    "password": "Str0ng-Passw0rd!",
    "password_confirmation": "Str0ng-Passw0rd!",
    "device_name": "iPhone 15"
}
```

- **Success — 201 Created**

```json
{
    "success": true,
    "message": "Registration successful",
    "data": {
        "user": {
            "id": 1,
            "name": "Ada Lovelace",
            "email": "ada@example.com",
            "role": "user",
            "avatar_url": null,
            "preferred_language": "en",
            "preferred_difficulty": "beginner",
            "email_verified_at": null,
            "last_active_at": null,
            "created_at": "2026-09-11T10:00:00+00:00",
            "updated_at": "2026-09-11T10:00:00+00:00"
        },
        "token": "1|VYxKmA0..."
    }
}
```

- **Errors**: `422` `VALIDATION_ERROR` (weak password, duplicate email, mismatched confirmation).

### POST /auth/login

- **Auth required**: No (`throttle:auth`)
- **Body**:

| Field         | Type   | Rules                 |
| ------------- | ------ | --------------------- |
| `email`       | string | required, valid email |
| `password`    | string | required              |
| `device_name` | string | optional, max:255     |

```json
{ "email": "ada@example.com", "password": "Str0ng-Passw0rd!" }
```

- **Success — 200 OK**

```json
{
    "success": true,
    "message": "Login successful",
    "data": {
        "user": {
            "id": 1,
            "name": "Ada Lovelace",
            "email": "ada@example.com",
            "role": "user"
        },
        "token": "2|9fGkq1..."
    }
}
```

- **Errors**:
    - `401 INVALID_CREDENTIALS` — wrong email/password (same response whether the email exists or not).
    - `422 VALIDATION_ERROR` — missing fields.

### POST /auth/logout

Revokes only the token used for this request.

- **Auth required**: Yes
- **Body**: none

```json
{ "success": true, "message": "Logout successful", "data": {} }
```

### GET /auth/user

Returns the authenticated user (identical shape to `profile`'s `user`).

- **Auth required**: Yes
- **Success — 200 OK**: `{ "success": true, "message": "User retrieved successfully", "data": { "user": { ... } } }`
- **Errors**: `401 UNAUTHENTICATED` (missing/invalid/expired token).

### POST /auth/forgot-password

Always returns the same message, whether or not the email exists, to prevent account enumeration.

- **Auth required**: No (`throttle:auth`)
- **Body**: `{ "email": "ada@example.com" }` — required, valid email

```json
{
    "success": true,
    "message": "If the email address exists, a password reset link has been sent.",
    "data": {}
}
```

- **Errors**: `422 VALIDATION_ERROR`, `429 RESET_THROTTLED` (Laravel's password broker throttling).

---

## 2. Profile

All routes require `Authorization: Bearer <token>` and always act on the authenticated user (no id in the URL).

### GET /profile

```json
{
    "success": true,
    "message": "Profile retrieved successfully",
    "data": {
        "user": {
            "id": 1,
            "name": "Ada Lovelace",
            "email": "ada@example.com",
            "role": "user",
            "avatar_url": "https://host/storage/avatars/8c...jpg",
            "preferred_language": "en",
            "preferred_difficulty": "beginner",
            "email_verified_at": null,
            "last_active_at": "2026-09-11T09:00:00+00:00",
            "created_at": "...",
            "updated_at": "..."
        }
    }
}
```

### PUT /profile

Partial update (every field is `sometimes`).

| Field                  | Rules                                                                    |
| ---------------------- | ------------------------------------------------------------------------ |
| `name`                 | string, min:2, max:255                                                   |
| `email`                | valid email, unique (ignoring self)                                      |
| `preferred_language`   | must be one of `config('app.supported_locales')` (default `en,fr,ar,es`) |
| `preferred_difficulty` | `beginner`\|`intermediate`\|`advanced`                                   |

Changing `email` resets `email_verified_at` to `null`.

```json
{ "name": "Grace Hopper", "preferred_difficulty": "advanced" }
```

- **Success — 200**: `{ "success": true, "message": "Profile updated successfully", "data": { "user": { ... } } }`
- **Errors**: `422 VALIDATION_ERROR`.

### PUT /profile/password

| Field                   | Rules                                                                             |
| ----------------------- | --------------------------------------------------------------------------------- |
| `current_password`      | required, must match the account's current password                               |
| `password`              | required, confirmed, different from current, same strength policy as registration |
| `password_confirmation` | required                                                                          |

Revokes every other personal access token; the token used for this request is kept.

- **Success — 200**: `{ "success": true, "message": "Password updated successfully", "data": { "user": { ... } } }`
- **Errors**: `422 VALIDATION_ERROR` (`errors.current_password` if incorrect).

### POST /profile/avatar

`multipart/form-data` with an `avatar` file field.

| Field    | Rules                                                                             |
| -------- | --------------------------------------------------------------------------------- |
| `avatar` | required, file, image, mimes: jpg/jpeg/png/webp, max 2048 KB, 64–2000 px per side |

- **Success — 200**: `{ "success": true, "message": "Avatar updated successfully", "data": { "user": { "avatar_url": "https://host/storage/avatars/...jpg", ... } } }` — the previous avatar file is deleted.
- **Errors**: `422 VALIDATION_ERROR` (wrong type, too large, wrong dimensions).

### DELETE /profile/avatar

Removes the stored avatar (no-op if none exists).

- **Success — 200**: `{ "success": true, "message": "Avatar removed successfully", "data": { "user": { "avatar_url": null, ... } } }`

---

## 3. Questions

All routes require authentication and are scoped to the caller — `user_id` is never accepted from the request body (`422` if present).

### GET /questions

Paginated list, filterable and sortable.

| Query param    | Rules                                                                                                    |
| -------------- | -------------------------------------------------------------------------------------------------------- |
| `input_method` | `keyboard`\|`handwriting`\|`camera`                                                                      |
| `category`     | `arithmetic`\|`algebra`\|`geometry`\|`trigonometry`\|`calculus`\|`linear_algebra`\|`statistics`\|`other` |
| `status`       | `draft`\|`recognized`\|`ready`\|`solving`\|`solved`\|`failed`                                            |
| `from`, `to`   | date, `to >= from`                                                                                       |
| `sort`         | `newest` (default) \| `oldest`                                                                           |
| `per_page`     | 1–100 (default 15)                                                                                       |
| `page`         | ≥ 1                                                                                                      |

```json
{
    "success": true,
    "message": "Questions retrieved successfully",
    "data": [
        {
            "id": 10,
            "original_expression": "2x + 8 = 20",
            "normalized_expression": "2x + 8 = 20",
            "input_method": "keyboard",
            "mathematical_category": "algebra",
            "recognition_confidence": null,
            "status": "solved",
            "created_at": "...",
            "updated_at": "..."
        }
    ],
    "meta": { "current_page": 1, "per_page": 15, "last_page": 1, "total": 1 }
}
```

### POST /questions

| Field                    | Rules                                                         |
| ------------------------ | ------------------------------------------------------------- |
| `original_expression`    | required, string, max:2000, must be a valid math expression   |
| `normalized_expression`  | optional, string, max:2000, valid math expression             |
| `input_method`           | required: `keyboard`\|`handwriting`\|`camera`                 |
| `mathematical_category`  | optional, one of the category enum values                     |
| `recognition_confidence` | optional, numeric, 0–1                                        |
| `status`                 | optional, one of the status enum values (defaults to `draft`) |
| `user_id`                | **prohibited**                                                |

The expression validator rejects markup, control characters, unsupported symbols, and unbalanced brackets; LaTeX-style input is accepted.

- **Success — 201 Created**: same shape as a list item.
- **Errors**: `422 VALIDATION_ERROR`.

### GET /questions/{id}

- **Success — 200**: single question object.
- **Errors**: `403 FORBIDDEN` (someone else's question), `404 NOT_FOUND`.

### PUT/PATCH /questions/{id}

Same field rules as create, all `sometimes`. `user_id` is still prohibited.

- **Success — 200**, **Errors**: `403`, `404`, `422`.

### DELETE /questions/{id}

- **Success — 200**: `{ "success": true, "message": "Question deleted successfully", "data": {} }`
- **Errors**: `403`, `404`.

---

## 4. Recognition

Recognition is asynchronous: the endpoint stores the image/canvas, creates a `recognition_attempt` record, and queues a job. Poll `GET /recognition/{id}` for the result. All routes require authentication; the image/handwriting endpoints are throttled (`throttle:recognition`, 15/min).

### POST /recognition/image

`multipart/form-data`.

| Field              | Rules                                                                             |
| ------------------ | --------------------------------------------------------------------------------- |
| `image`            | required, file, image, mimes: jpg/jpeg/png/webp, max 8192 KB, 32–8000 px per side |
| `math_question_id` | optional, integer, must belong to the caller                                      |

- **Success — 202 Accepted**

```json
{
    "success": true,
    "message": "Recognition accepted",
    "data": {
        "id": 5,
        "recognition_id": 5,
        "math_question_id": 12,
        "input_method": "camera",
        "provider": "mock",
        "status": "pending",
        "processing_status": "pending",
        "recognized_expression": null,
        "confidence": null,
        "started_at": null,
        "completed_at": null,
        "created_at": "..."
    }
}
```

- **Errors**: `422 VALIDATION_ERROR` (bad file, wrong `math_question_id`).

### POST /recognition/handwriting

Same contract as `/recognition/image`, but the file field is submitted as a rendered handwriting canvas image (PNG/JPG/WEBP, max 4096 KB, 32–8000 px). By default (`HANDWRITING_RETENTION=temporary`) the canvas image is deleted once recognition finishes; `original_expression` and the recognized text are kept regardless.

- **Success — 202 Accepted**: same shape as the image endpoint, `message: "Handwriting recognition accepted"`.

### GET /recognition/{id}

Poll for the outcome.

- **Success — 200**, `processing_status` one of `pending`, `processing`, `completed`, `failed`.

```json
{
    "success": true,
    "message": "Recognition retrieved successfully",
    "data": {
        "id": 5,
        "recognition_id": 5,
        "math_question_id": 12,
        "input_method": "camera",
        "provider": "mock",
        "status": "completed",
        "processing_status": "completed",
        "recognized_expression": "2x + 5 = 15",
        "confidence": 0.95,
        "started_at": "...",
        "completed_at": "...",
        "created_at": "..."
    }
}
```

On failure, an `error` object is included: `"error": { "code": "LOW_CONFIDENCE", "message": "..." }` (also `PROVIDER_ERROR`, `JOB_FAILED`).

- **Errors**: `403 FORBIDDEN`, `404 NOT_FOUND`.

---

## 5. Solutions

Solving is deterministic (`ArithmeticSolver` / `LinearEquationSolver` via `MathSolverManager`) — AI is never used to compute the answer.

### POST /questions/{question}/solve

| Field     | Rules                                                                           |
| --------- | ------------------------------------------------------------------------------- |
| `force`   | optional boolean — re-solve and store a new solution even if one already exists |
| `user_id` | **prohibited**                                                                  |

- **Success — 201 Created** (new solution) or **200 OK** (`"Question already solved"`, existing solution reused):

```json
{
    "success": true,
    "message": "Question solved successfully",
    "data": {
        "question": "2x + 8 = 20",
        "question_id": 12,
        "normalized_expression": "2x + 8 = 20",
        "solution": {
            "id": 7,
            "solver": "linear_equation",
            "status": "completed",
            "error_message": null,
            "solved_at": "...",
            "created_at": "..."
        },
        "steps": [
            {
                "step_number": 1,
                "expression": "2x + 8 - 8 = 20 - 8",
                "operation": "subtract",
                "explanation": "Move every term containing the variable to the left side.",
                "result": "2x = 12"
            },
            {
                "step_number": 2,
                "expression": "2x = 12",
                "operation": "simplify",
                "explanation": "Combine like terms on both sides.",
                "result": "2x = 12"
            },
            {
                "step_number": 3,
                "expression": "2x / 2 = 12 / 2",
                "operation": "divide",
                "explanation": "Divide both sides by the coefficient of the variable.",
                "result": "x = 6"
            }
        ],
        "final_answer": "x = 6",
        "verification_status": "verified"
    }
}
```

- **Errors**:
    - `403 FORBIDDEN` — not your question.
    - `422 QUESTION_NOT_READY` — question has no expression yet (e.g. still awaiting recognition).
    - `409 QUESTION_ALREADY_SOLVING` — a solve is already in progress.
    - `422 UNSUPPORTED_PROBLEM` — no solver supports the expression (e.g. quadratics, multiple variables).
    - `422 DIVISION_BY_ZERO`, `422 INVALID_EXPRESSION` — malformed or invalid math.

### GET /questions/{question}/solution

Returns the latest solution.

- **Success — 200**: same shape as `solve`'s `data`.
- **Errors**: `403 FORBIDDEN`, `404 NOT_FOUND` (`SOLUTION_NOT_FOUND` if never solved, plain `NOT_FOUND` for an unknown question id).

### POST /solutions/{solution}/verify

Re-runs the deterministic solver and compares its answer against the stored one, updating `verification_status`.

- **Success — 200**: same shape, `verification_status` refreshed to `verified` or `failed`.
- **Errors**: `403 FORBIDDEN`, `404 NOT_FOUND`.

---

## 6. AI Explanations

AI only produces wording (explanations, hints, concepts) — it can never change `final_answer`, `solver`, or `verification_status`. A solution must be `completed` **and** `verified` before it can be explained (`throttle:ai`, 20/min).

### POST /solutions/{solution}/explanation

| Field         | Rules                                                                                                                                         |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `difficulty`  | optional: `beginner`\|`intermediate`\|`advanced` (maps to `basic`\|`detailed`\|`step_by_step`; defaults to the user's `preferred_difficulty`) |
| `language`    | optional, must be a supported locale (defaults to the user's `preferred_language`)                                                            |
| `step_number` | optional integer ≥ 1 — focuses the explanation on one step                                                                                    |
| `force`       | optional boolean — regenerate even if a matching explanation exists                                                                           |

- **Success — 201 Created** (new) or **200 OK** (`"Explanation already generated"`, reused):

```json
{
    "success": true,
    "message": "Explanation generated successfully",
    "data": {
        "id": 3,
        "solution_id": 7,
        "solution_step_id": null,
        "kind": "explanation",
        "detail_level": "detailed",
        "language": "en",
        "provider": "mock",
        "model": "mock-model",
        "status": "completed",
        "content": "We solve 2x + 8 = 20 and arrive at x = 6. Step 1: we subtract, so ... The answer x = 6 is confirmed by the solver.",
        "concepts": null,
        "generated_at": "...",
        "final_answer": "x = 6",
        "verification_status": "verified"
    }
}
```

- **Errors**:
    - `403 FORBIDDEN`, `404 NOT_FOUND`.
    - `422 SOLUTION_NOT_EXPLAINABLE` — solution not completed.
    - `422 SOLUTION_NOT_VERIFIED` — solution not verified.
    - `504 AI_TIMEOUT`, `429 AI_RATE_LIMITED`, `503 AI_UNAVAILABLE`, `502 AI_MALFORMED_RESPONSE`, `503 AI_PROVIDER_ERROR` — provider failures (the solution itself is unaffected and remains usable).

### POST /solutions/{solution}/hint

Same request/response shape and error codes as `explanation`, but `kind: "hint"` and the content never reveals the final answer.

### GET /solutions/{solution}/explanation

Returns the latest **completed** explanation for the solution.

- **Success — 200**: same shape as `store`.
- **Errors**: `403`, `404 EXPLANATION_NOT_FOUND` (none generated yet), `404 NOT_FOUND` (unknown solution).

---

## 7. History

Read-only view over the caller's solved/unsolved questions, always scoped to the authenticated user.

### GET /history

Same filters as `GET /questions` plus full-text `search` over `original_expression`/`normalized_expression`.

| Query param                                                          | Rules             |
| -------------------------------------------------------------------- | ----------------- |
| `search`                                                             | string, max:255   |
| `category`, `input_method`, `from`, `to`, `sort`, `per_page`, `page` | same as Questions |

```json
{
    "success": true,
    "message": "History retrieved successfully",
    "data": [
        {
            "id": 12,
            "question": "2x + 8 = 20",
            "normalized_expression": "2x + 8 = 20",
            "input_method": "keyboard",
            "category": "algebra",
            "status": "solved",
            "final_answer": "x = 6",
            "verification_status": "verified",
            "solved_at": "...",
            "created_at": "..."
        }
    ],
    "meta": { "current_page": 1, "per_page": 15, "last_page": 1, "total": 1 }
}
```

### GET /history/{question}

Full detail: question metadata, latest solution, its steps, and completed AI explanations.

- **Success — 200**: includes `steps: [...]` and `explanations: [...]` arrays.
- **Errors**: `403`, `404`.

### DELETE /history/{question}

Deletes the question (cascades to its inputs, recognition attempts, solutions, steps and AI explanations).

- **Success — 200**: `{ "success": true, "message": "History entry deleted successfully", "data": {} }`
- **Errors**: `403`, `404`.

### DELETE /history

Deletes **every** question owned by the caller.

- **Success — 200**: `{ "success": true, "message": "History cleared successfully", "data": { "deleted": 4 } }`

---

## 8. Tutor

Guided, step-by-step practice built on top of an already solved, verified solution. Correctness is always checked against the deterministic `solution_steps` — never by AI. AI is only optionally used to reword a hint (`TUTOR_AI_HINTS`, off by default), with the deterministic step explanation as a guaranteed fallback.

### POST /tutor/sessions

| Field         | Rules                                                                               |
| ------------- | ----------------------------------------------------------------------------------- |
| `question_id` | required, integer, must belong to the caller and have a completed+verified solution |
| `user_id`     | **prohibited**                                                                      |

Resumes an existing active session for the same question instead of creating a duplicate.

- **Success — 201 Created** (new) or **200 OK** (`"Tutor session resumed"`):

```json
{
    "success": true,
    "message": "Tutor session started",
    "data": {
        "id": 4,
        "question_id": 12,
        "question": "2x + 8 = 20",
        "solution_id": 7,
        "title": "2x + 8 = 20",
        "status": "active",
        "current_step": 1,
        "total_steps": 3,
        "score": 0,
        "started_at": "...",
        "last_interaction_at": "...",
        "completed_at": null,
        "current_step_detail": {
            "step_number": 1,
            "expression": "2x + 8 = 20",
            "operation": "subtract",
            "prompt": "Step 1: starting from \"2x + 8 = 20\", apply \"subtract\". What do you get?",
            "result": null
        }
    }
}
```

- **Errors**: `422 VALIDATION_ERROR` (unknown/foreign `question_id`), `422 TUTOR_NOT_AVAILABLE` (no verified step-by-step solution yet).

### GET /tutor/sessions/{session}

- **Success — 200**: same shape as `store`'s `data`.
- **Errors**: `403`, `404`.

### POST /tutor/sessions/{session}/answer

| Field    | Rules                      |
| -------- | -------------------------- |
| `answer` | required, string, max:2000 |

Compared deterministically to the current step's stored result (case/whitespace/unicode-normalized, numeric tolerance). Advances `current_step` and awards points (10, or 5 if a hint was used for that step) only when correct.

- **Success — 200** (`"Correct answer"` or `"Incorrect answer"`):

```json
{
    "success": true,
    "message": "Correct answer",
    "data": {
        "is_correct": true,
        "feedback": "Correct! 2x + 8 - 8 = 20 - 8 gives 2x = 12.",
        "hint": null,
        "next_step": {
            "step_number": 2,
            "expression": "2x = 12",
            "operation": "simplify",
            "prompt": "...",
            "result": null
        },
        "progress": {
            "current_step": 2,
            "total_steps": 3,
            "completed_steps": 1,
            "percentage": 33,
            "score": 10,
            "status": "active"
        },
        "session": {
            "id": 4,
            "current_step": 2,
            "total_steps": 3,
            "score": 10,
            "status": "active",
            "current_step_detail": {
                /* step 2 */
            }
        }
    }
}
```

When the last step is answered correctly, `next_step` is `null` and `progress.status`/`session.status` become `completed`.

- **Errors**: `403`, `404`, `409 TUTOR_SESSION_NOT_ACTIVE` (session already completed), `422 VALIDATION_ERROR`.

### POST /tutor/sessions/{session}/hint

Returns a hint for the current step without revealing its result (`throttle:ai`).

- **Success — 200**: same shape as `answer`, `is_correct: null`, `hint` populated.
- **Errors**: `403`, `404`, `409 TUTOR_SESSION_NOT_ACTIVE`.

### POST /tutor/sessions/{session}/skip

Reveals the current step's result, advances `current_step`, awards no points.

- **Success — 200**: same shape, `feedback` includes the revealed result.
- **Errors**: `403`, `404`, `409 TUTOR_SESSION_NOT_ACTIVE`.

### POST /tutor/sessions/{session}/complete

Ends the session early (idempotent — completing twice is a no-op).

- **Success — 200**: `{ "success": true, "message": "Tutor session completed", "data": { "status": "completed", "current_step_detail": null, ... } }`
- **Errors**: `403`, `404`.

---

## 9. Notifications

In-app (database) notifications; some events also send email (see [Workflows](#11-workflows)). Only the caller's own notifications are ever visible.

### GET /notifications

| Query param | Rules                                 |
| ----------- | ------------------------------------- |
| `filter`    | `all` (default) \| `unread` \| `read` |
| `per_page`  | 1–100                                 |
| `page`      | ≥ 1                                   |

```json
{
    "success": true,
    "message": "Notifications retrieved successfully",
    "data": [
        {
            "id": "9e...uuid",
            "type": "solution.completed",
            "title": "Your solution is ready",
            "message": "We solved \"2x + 8 = 20\" and the answer is x = 6.",
            "data": {
                "solution_id": 7,
                "question_id": 12,
                "final_answer": "x = 6",
                "verification_status": "verified"
            },
            "is_read": false,
            "read_at": null,
            "created_at": "..."
        }
    ],
    "meta": {
        "current_page": 1,
        "per_page": 15,
        "last_page": 1,
        "total": 1,
        "unread_count": 1
    }
}
```

Notification `type` values: `account.registered`, `account.password_reset_requested`, `solution.completed`, `recognition.completed`, `recognition.failed`, `tutor.completed`.

### POST /notifications/{id}/read

- **Success — 200**: the notification with `is_read: true`.
- **Errors**: `404 NOT_FOUND` (also returned, instead of `403`, for another user's notification id — ids are looked up only within the caller's own notifications so they can't be enumerated).

### POST /notifications/read-all

- **Success — 200**: `{ "success": true, "message": "All notifications marked as read", "data": { "updated": 3 } }`

### DELETE /notifications/{id}

- **Success — 200**: `{ "success": true, "message": "Notification deleted successfully", "data": {} }`
- **Errors**: `404 NOT_FOUND` for another user's notification.

---

## 10. Health Check

### GET /health

Public, unauthenticated, unthrottled beyond the general API limiter.

```json
{
    "success": true,
    "message": "Service is healthy",
    "data": {
        "status": "ok",
        "app": "MathTutor",
        "environment": "production",
        "api_version": "v1",
        "database": "connected",
        "timestamp": "2026-09-11T10:00:00+00:00"
    }
}
```

`database` is `"unavailable"` instead of `"connected"` if the database connection fails (the endpoint still returns `200`).

---

## 11. Workflows

### Authentication flow

1. `POST /auth/register` or `POST /auth/login` → returns `data.token`.
2. Store the token securely on the device (e.g. Flutter secure storage).
3. Send `Authorization: Bearer <token>` on every subsequent request.
4. `POST /auth/logout` revokes only that token; other devices/sessions are unaffected.
5. Changing the password (`PUT /profile/password`) revokes every other token.
6. Tokens can be configured to expire (`SANCTUM_TOKEN_EXPIRATION` minutes); an expired or invalid token returns `401 UNAUTHENTICATED`.

### Token usage

- Every protected route requires `Authorization: Bearer <token>`.
- `user_id` is **never** read from the request body anywhere in the API — the owner is always the token's user.
- 403 vs 404: a resource that exists but belongs to someone else returns `403 FORBIDDEN`; a resource that doesn't exist returns `404 NOT_FOUND`. Notifications intentionally always return `404` for foreign ids to avoid confirming they exist.

### Image upload process

1. Client submits `multipart/form-data` to `POST /recognition/image` (photographed problem) or `POST /recognition/handwriting` (drawn canvas), optionally with `math_question_id` to attach to an existing question.
2. The file is validated (type, size, dimensions) and stored on a private disk under a random filename — the client never learns the physical path.
3. The API immediately returns `202 Accepted` with a `recognition_id` and `processing_status: "pending"`.
4. A queued job performs recognition, updating the record to `processing` → `completed`/`failed`.
5. The client polls `GET /recognition/{id}` until `processing_status` is `completed` or `failed`, then reads `recognized_expression`/`confidence` or `error`.
6. On success, the linked question's `original_expression`, `recognition_confidence` and `status` (`recognized`) are updated automatically, and a `recognition.completed` notification is sent; on failure the question becomes `failed` and a `recognition.failed` notification is sent.

### Recognition workflow

`pending → processing → completed | failed`, driven entirely by the queued job; low-confidence results are treated as `failed` (`LOW_CONFIDENCE`) even though an expression was recognized.

### Solving workflow

1. Ensure the question has an `original_expression` (typed directly, or produced by recognition).
2. `POST /questions/{id}/solve`. The request goes: **Controller → Form Request (ownership + validation) → `MathSolverManager` → matching solver (`ArithmeticSolver`/`LinearEquationSolver`) → `SolutionValidator` (independent re-check) → persisted `Solution` + `SolutionStep`s → response.**
3. Re-solving an already-solved question returns the existing solution (`200`) unless `force: true` is sent, in which case a new solution row is added to history.
4. `POST /solutions/{id}/verify` re-runs the solver independently and updates `verification_status`.

### AI explanation workflow

1. Solve and verify the question first (`explanation`/`hint` require `status: completed` and `verification_status: verified`).
2. `POST /solutions/{id}/explanation` (or `/hint`) builds a structured, read-only payload from the stored question/solution/steps and dispatches it to the configured `AIExplanationProvider` through a queued job.
3. The AI response is validated (non-empty, size-capped) and stored as an `AiExplanation` row; it never touches `solutions`/`solution_steps`.
4. If the provider fails (timeout, rate limit, unavailable, malformed response), the explanation record is marked `failed` with a specific error code, but the underlying solution stays fully usable.
5. `GET /solutions/{id}/explanation` retrieves the latest completed explanation.

### Tutor workflow

1. `POST /tutor/sessions` with a `question_id` that already has a verified solution — creates (or resumes) a session at `current_step = 1`.
2. For each step, the client can `answer` (checked deterministically against `solution_steps.result`), request a `hint` (deterministic explanation, optionally reworded by AI), or `skip` (reveals the result, no points).
3. A correct answer advances `current_step`; once every step is passed the session status becomes `completed` automatically and a `tutor.completed` notification is sent. `complete` can also end a session early.
4. `progress` in every response reports `current_step`, `total_steps`, `completed_steps`, `percentage` and `score` so the Flutter client can render a progress bar without extra requests.
