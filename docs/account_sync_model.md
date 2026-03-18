# Account and Cloud Sync Model

This document describes the intended behavior of anonymous accounts, provider sign-in, cloud sync, and logout flows.

## Goals

- Keep the app usable without requiring sign-in.
- Allow a player to upgrade an anonymous profile to a provider-backed account.
- Preserve cloud data under a stable Firebase Auth `uid`.
- Avoid silent merges that can corrupt or confuse session history.

## Terms

- Anonymous account: a temporary Firebase Auth user created with `signInAnonymously()`.
- Provider account: a Firebase Auth user linked to or signed in with an identity provider such as Google or Apple.
- Local data: session and history data stored on the current device.
- Cloud data: data stored in Firestore under `users/{uid}/...`.

## Core Rules

1. Every device can start in anonymous mode.
2. Cloud data is always keyed by Firebase Auth `uid`.
3. Linking an anonymous user to Google is preferred over creating a second account.
4. Automatic merging of two existing profiles is not supported.
5. If a provider-backed account already exists, switching to it may replace the current device-local anonymous profile.

## Expected Flows

### 1. Anonymous user on first device upgrades to a provider account

Initial state:

- Device A starts with anonymous `uid = A`.
- Local and cloud data are stored under `A`.

Upgrade:

- The user signs in with Google or Apple.
- The app links the current anonymous user with that provider credential.

Result:

- The Firebase Auth user keeps the same `uid = A`.
- `isAnonymous` becomes `false`.
- Existing data under `users/A/...` remains valid.

### 2. The same provider account is used on a second device

Initial state:

- Device B starts with a new anonymous `uid = B`.
- The same human user signs in with the provider account already linked to `uid = A`.

Important constraint:

- That provider credential is already attached to `uid = A`.
- It cannot be linked to anonymous `uid = B` as a second permanent provider-backed account.

Expected behavior:

- The app warns the user that this provider account already exists.
- The app explains that switching to this account may discard or replace current local anonymous data on Device B.
- If the user confirms, the app signs in to the existing provider-backed account `uid = A`.

Result:

- The user ends up on the existing cloud profile `uid = A`.
- The temporary anonymous account `uid = B` is not treated as the user's long-term identity.
- Local anonymous-only data on Device B may be cleared or archived instead of merged.

## Why automatic merge is avoided

Automatic merge sounds convenient, but it is risky for this app:

- session history can diverge across devices
- timestamps and progress can conflict
- duplicate solved sessions can be created
- users may not understand which state won

Because of this, the safer product decision is:

- keep linking simple when the provider account is new
- require explicit confirmation when the provider account already exists elsewhere
- prefer replacing the current local anonymous profile over hidden merge logic

## Logout Model

Logout should be treated as leaving the current cloud-backed identity on this device.

Recommended behavior:

1. Sign out from the provider-backed user.
2. Start a fresh anonymous session on the current device.
3. Do not restore the previous anonymous `uid` that existed before Google sign-in.

Example:

- Device A signs in as provider-backed `uid = A`.
- The user logs out.
- The app creates a new anonymous account, for example `uid = C`.

This keeps the model simple:

- `uid = A` remains the cloud profile
- `uid = C` is just a new local anonymous profile on this device

The same rule applies on any other device.

## User-Facing Messaging

When a provider account already exists and the current device is using a different anonymous profile, the confirmation dialog should explain:

- this account is already linked to another profile
- switching to it will load that cloud profile on this device
- current local anonymous data on this device may be lost if it was not synced elsewhere

Recommended tone:

- explicit
- non-technical
- no promise of automatic merge

## Implementation Guidance

- Anonymous sign-in is acceptable as the default app entry.
- Linking should be attempted only when the current user is anonymous and the selected provider credential is not already in use.
- If the credential is already in use, the app should offer a controlled account switch instead of a merge.
- Logout should create a new anonymous profile instead of trying to resurrect an older anonymous identity.

## Summary

The intended mental model is:

- anonymous profile = temporary local identity
- provider-backed profile = primary cloud identity
- switching to an existing provider-backed profile replaces the current anonymous device context
- logout starts a new anonymous context
