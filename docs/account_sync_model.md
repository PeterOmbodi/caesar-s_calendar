# Account and Cloud Sync Model

This document describes the intended behavior of local guest mode, provider sign-in, cloud sync, and logout flows.

## Goals

- Keep the app fully usable without requiring sign-in.
- Treat guest progress as purely local device data.
- Use cloud sync only for provider-backed accounts such as Google or Apple.
- Avoid silent merges that can corrupt or confuse session history.
- Keep the migration rule simple and intentionally lossy outside the first-login case.

## Terms

- Guest profile: local-only session and history data stored on the current device. No Firebase Auth user is required.
- Provider account: a Firebase Auth user signed in with an identity provider such as Google or Apple.
- Local data: session and history data stored in the local database on the current device.
- Cloud data: data stored in Firestore under `users/{uid}/...`.

## Core Rules

1. The app starts in local guest mode by default.
2. Guest data is stored only on the device.
3. Cloud data exists only for provider-backed accounts.
4. Cloud data is always keyed by Firebase Auth `uid`.
5. Automatic merging of two existing profiles is not supported.
6. Guest sessions are uploaded to cloud only in one case: the first sign-in of a new provider-backed account.
7. All other account transitions may discard current local sessions.

## Expected Flows

### 1. First launch in guest mode

Initial state:

- The app starts without a signed-in Firebase user.
- Sessions and history are stored only in the local database.
- No cloud sync runs.

Result:

- The user can play normally as a guest.
- If the app is removed or the device is changed before sign-in, guest data is lost.

### 2. Guest upgrades to a new provider-backed account

Initial state:

- The device has local guest data.
- The user signs in with Google or Apple.
- The provider credential is not yet linked to any existing Firebase Auth user.

Expected behavior:

- The app signs in to a new provider-backed Firebase Auth account.
- The app checks whether cloud data already exists under the new `uid`.
- If the cloud profile is empty, local guest data is uploaded to the cloud.

Result:

- Local guest data becomes the initial cloud profile for that provider-backed account.
- Future sync uses the provider-backed `uid`.

### 3. Guest signs in to an existing provider-backed account

Initial state:

- The device has local guest data.
- The user signs in to a provider-backed account whose cloud profile already has data.

Expected behavior:

- The app signs in successfully.
- The app detects that cloud data already exists for the signed-in `uid`.
- The app clears current local data and replaces it with cloud data.

Result:

- The user ends up on the existing cloud profile.
- Current local guest data on the device is discarded instead of merged.

## Required Check After Sign-In

After successful provider sign-in, the app must determine whether the signed-in `uid` already has cloud data.

Expected behavior:

- If the signed-in `uid` has no cloud data, treat it as a new cloud account.
- If this is also the device's first provider sign-in, upload current local guest data.
- If the signed-in `uid` already has cloud data, clear local data and replace it with cloud data.

## Why automatic merge is avoided

Automatic merge sounds convenient, but it is risky for this app:

- session history can diverge across devices
- timestamps and progress can conflict
- duplicate solved sessions can be created
- users may not understand which state won

Because of this, the chosen product decision is:

- upload local guest data only when the cloud profile is new or empty
- do not merge local guest data into an existing cloud profile
- accept that non-first-login transitions may lose current local sessions

## Logout Model

Logout should be treated as leaving the current provider-backed cloud identity on this device.

Intended behavior:

1. Sign out from the current provider-backed Firebase user.
2. Keep the local database unchanged.
3. Store the last signed-in cloud `uid` on the device.
4. Return the app to local guest mode.

On the next provider sign-in:

- if the new signed-in `uid` differs from the stored last cloud `uid`, clear the local database before sync
- if the signed-in `uid` already has cloud data, clear the local database before sync
- only the first sign-in of a new cloud account may upload current local guest data

This intentionally allows local session loss in exchange for a simpler and safer model.

## User-Facing Messaging

When a user signs in, the app may replace current local sessions with cloud data if the account already has a cloud profile.

Recommended tone:

- explicit
- non-technical
- no promise of automatic merge

## Implementation Guidance

- Do not create Firebase anonymous users by default.
- Guest mode should work with `FirebaseAuth.currentUser == null`.
- Provider sign-in should be the point where cloud identity begins.
- After successful sign-in, check whether the signed-in `uid` already has cloud data.
- Persist the last signed-in cloud `uid` on the device.
- Clear local data before sync when switching between different cloud accounts.
- Upload local guest data only on the first sign-in of a new cloud account.

## Summary

The intended mental model is:

- guest profile = local-only device data
- provider-backed profile = primary cloud identity
- sign-in with a new provider account uploads local guest data into cloud
- sign-in with an existing provider account replaces local data with cloud data
- logout returns to guest mode without creating a new Firebase anonymous user
- switching between cloud accounts may discard current local sessions
