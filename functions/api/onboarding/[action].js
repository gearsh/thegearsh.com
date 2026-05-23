import { corsPreflightResponse, jsonResponse } from '../auth-utils.js';
import {
  ensureOnboardingTables,
  registerArtist,
  verifyEmail,
  sendPhoneCode,
  verifyPhone,
  saveProfile,
  getPreview,
  submitForReview,
  resendEmailCode,
} from '../onboarding-utils.js';

export async function onRequestPost(context) {
  try {
    await ensureOnboardingTables(context.env.DB);
    const action = context.params.action;
    const body = await context.request.json();

    switch (action) {
      case 'register':
        return registerArtist(context, body);
      case 'verify-email':
        return verifyEmail(context, body);
      case 'resend-email':
        return resendEmailCode(context);
      case 'send-phone':
        return sendPhoneCode(context, body);
      case 'verify-phone':
        return verifyPhone(context, body);
      case 'save':
        return saveProfile(context, body);
      case 'submit':
        return submitForReview(context);
      default:
        return jsonResponse({ success: false, error: 'Unknown onboarding action' }, 400);
    }
  } catch (err) {
    console.error('Onboarding error:', err);
    return jsonResponse({ success: false, error: 'Onboarding request failed' }, 500);
  }
}

export async function onRequestGet(context) {
  try {
    await ensureOnboardingTables(context.env.DB);
    if (context.params.action === 'preview') {
      return getPreview(context);
    }
    return jsonResponse({ success: false, error: 'Unknown action' }, 404);
  } catch (err) {
    console.error('Onboarding GET error:', err);
    return jsonResponse({ success: false, error: 'Failed to load preview' }, 500);
  }
}

export async function onRequestOptions() {
  return corsPreflightResponse();
}
