import * as functions from 'firebase-functions';

// Replace this with your Firebase Auth UID before deploying.
export const SUPER_ADMIN_UID = 'lEKb46CXYpRJAc11ppEbYjYAQdN2';


export function requireAuth(
  context: functions.https.CallableContext
): NonNullable<functions.https.CallableContext['auth']> {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  return context.auth;
}

export function hasAdminRole(
  context: functions.https.CallableContext
): boolean {
  return context.auth?.token?.role === 'admin';
}

export function requireAdmin(
  context: functions.https.CallableContext
): NonNullable<functions.https.CallableContext['auth']> {
  const auth = requireAuth(context);

  if (!hasAdminRole(context)) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Admin role is required'
    );
  }

  return auth;
}

export function requireSuperAdmin(
  context: functions.https.CallableContext
): NonNullable<functions.https.CallableContext['auth']> {
  const auth = requireAuth(context);

  if (auth.uid !== SUPER_ADMIN_UID) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only the super-admin can assign admin roles'
    );
  }

  return auth;
}
