# Account Recovery

## Goal
- Implement email-based account recovery using a 6-digit code and Resend.

## Backend
- Add a Prisma model to persist recovery codes with timestamps and metadata.
- Add Zod DTOs for request, verify, and reset flows.
- Add use cases for requesting a code, verifying it, and resetting the password.
- Add a Resend email service.
- Expose new auth endpoints.

## Frontend
- Wire the login screen recovery link.
- Add recovery screens and route entries.
- Add repository/usecase methods for the recovery flow.

## Progress
- [x] Business rules defined
- [x] Project pattern mapped
- [x] Backend implementation
- [x] Frontend implementation
- [x] Validation/build checks

## Notes
- Backend build could not be executed in this environment because the local Nest CLI is not installed (`node_modules` is missing in `nest-backend`).
- Flutter analysis passed with no issues.
