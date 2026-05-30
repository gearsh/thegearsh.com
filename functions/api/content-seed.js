// Default Content Engine copy & theme (Gearsh brand)

export const DEFAULT_COPY = {
  app: {
    name: 'Gearsh',
    tagline: 'Book creative talent. Get paid to perform.',
  },
  onboarding: {
    welcome_title: 'Welcome to Gearsh',
    welcome_subtitle: 'Discover artists, book gigs, and grow your creative career.',
    role_client: 'Book talent',
    role_artist: 'List my services',
    role_fan: 'Follow artists',
  },
  auth: {
    login_title: 'Sign in',
    signup_title: 'Create your account',
    forgot_password: 'Forgot password?',
  },
  discover: {
    title: 'Discover',
    search_placeholder: 'Search DJs, photographers, MCs…',
    featured_label: 'Featured artists',
  },
  booking: {
    flow_title: 'Book an artist',
    confirm_title: 'Confirm booking',
    service_fee_label: 'Platform fee (12.6%)',
  },
  cart: {
    title: 'Your cart',
    checkout: 'Proceed to checkout',
    empty: 'Your cart is empty',
  },
  dashboard: {
    artist_title: 'Artist dashboard',
    requests: 'Booking requests',
    earnings: 'Earnings',
  },
  help: {
    title: 'Help Centre',
    dispute_cta: 'Submit a dispute',
  },
};

export const DEFAULT_THEME = {
  colors: {
    background: '#020617',
    surface: '#0F172A',
    card: '#111827',
    primary: '#0EA5E9',
    primaryLight: '#38BDF8',
    accent: '#06B6D4',
    textPrimary: '#FFFFFF',
    textSecondary: '#94A3B8',
    border: '#FFFFFF12',
  },
  typography: {
    fontHeading: 'Syne',
    fontBody: 'DM Sans',
    scale: { sm: 12, md: 14, lg: 16, xl: 20, display: 32 },
  },
  spacing: { xs: 4, sm: 8, md: 16, lg: 24, xl: 32 },
  radii: { sm: 8, md: 12, lg: 16, full: 999 },
};

export async function ensureContentSeeded(db) {
  const live = await db.prepare(`SELECT id FROM content_live WHERE id = 'live'`).first();
  if (live) return;

  const now = new Date().toISOString();
  const copyJson = JSON.stringify(DEFAULT_COPY);
  const themeJson = JSON.stringify(DEFAULT_THEME);

  await db.prepare(`
    INSERT INTO content_live (id, copy_json, theme_json, version, published_at, updated_at)
    VALUES ('live', ?, ?, 1, ?, ?)
  `).bind(copyJson, themeJson, now, now).run();

  await db.prepare(`
    INSERT INTO content_draft (id, copy_json, theme_json, updated_at)
    VALUES ('draft', ?, ?, ?)
  `).bind(copyJson, themeJson, now).run();
}
