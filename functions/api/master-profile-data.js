// Default content for @gearsh Master Profile

export const GEARSH_USERNAME = 'gearsh';

export const GEARSH_DEFAULT = {
  username: 'gearsh',
  name: 'Nhlanhla Collins Mahlangu',
  tagline: 'Founder of The Gearsh | IT Support & Business Technology',
  category: 'IT Support & Digital Services',
  location: 'Louis Trichardt, Limpopo',
  country: 'South Africa',
  is_verified: true,
  profile_type: 'master',
  cover_image_url: '/assets/images/gearsh-cover.jpg',
  image: '/assets/images/gearsh-founder-avatar.svg',
  bio: 'I help small businesses solve technology problems, maintain their IT systems, improve connectivity and build a stronger digital presence.',
  long_bio: `I'm Nhlanhla Collins Mahlangu, founder of The Gearsh (Pty) Ltd. I work with small businesses on practical technology problems, from computer and network troubleshooting to websites and Google Business Profile setup.

I also build The Gearsh, a platform designed to connect creative professionals with opportunities and clients. I understand what it takes to keep a small business running, and I focus on solutions that make technology useful rather than complicated.

Tell me what your business needs. We can discuss the scope, timeline and a quote before any work begins.`,
  stats: {},
  skills: [
    'Small business IT support',
    'Computer troubleshooting',
    'Wi-Fi & network support',
    'Business technology setup',
    'Website development',
    'Google Business Profiles',
    'Software & systems support',
  ],
  social_links: {
    website: 'https://thegearsh.com',
    twitter: 'https://x.com/thegearsh',
    github: 'https://github.com/gearsh',
  },
  services: [
    {
      id: 'svc_gearsh_it',
      name: 'Small Business IT Support',
      description: 'Computer, software and day-to-day IT troubleshooting for small businesses. Tell me what is not working and I will assess the job.',
      price: null,
      is_featured: 1,
      deliverables: ['Issue assessment', 'Troubleshooting', 'Recommended next steps'],
    },
    {
      id: 'svc_gearsh_network',
      name: 'Wi-Fi & Network Support',
      description: 'Help with office Wi-Fi, connectivity problems, equipment setup and small-business networks.',
      price: null,
      is_featured: 1,
      deliverables: ['Network assessment', 'Connectivity troubleshooting', 'Setup assistance'],
    },
    {
      id: 'svc_gearsh_maintenance',
      name: 'Business IT Maintenance',
      description: 'Discuss planned computer maintenance and ongoing IT support for your business. Monthly arrangements are quoted by scope.',
      price: null,
      is_featured: 0,
      deliverables: ['Needs assessment', 'Support scope', 'Custom proposal'],
    },
    {
      id: 'svc_gearsh_web',
      name: 'Website Creation',
      description: 'Websites for businesses that need a professional online presence. Scope and pricing depend on requirements.',
      price: null,
      is_featured: 0,
      deliverables: ['Project discussion', 'Website scope', 'Custom quotation'],
    },
    {
      id: 'svc_gearsh_business_profile',
      name: 'Google Business Profile Setup',
      description: 'Assistance setting up or improving business information on Google, subject to Google verification and eligibility rules.',
      price: null,
      is_featured: 0,
      deliverables: ['Profile assessment', 'Business information setup', 'Verification guidance'],
    },
  ],
  portfolio_projects: [],
  testimonials: [],
};
export function buildAvailabilitySlots() {
  const slots = [];
  const now = new Date();
  for (let d = 1; d <= 21; d += 1) {
    const date = new Date(now);
    date.setDate(date.getDate() + d);
    if (date.getDay() === 0) continue;
    const iso = date.toISOString().slice(0, 10);
    slots.push({ date: iso, slots: ['10:00', '14:00', '18:00'] });
  }
  return slots;
}

export function mapMasterProfileResponse(row, services, overrides) {
  const base = overrides || {};
  let stats = base.stats || {};
  let testimonials = base.testimonials || [];
  let portfolio = base.portfolio_projects || [];
  let availability = base.availability || buildAvailabilitySlots();

  if (row) {
    try { stats = JSON.parse(row.stats_json || '{}'); } catch (_) {}
    try { testimonials = JSON.parse(row.testimonials_json || '[]'); } catch (_) {}
    try { portfolio = JSON.parse(row.portfolio_projects_json || '[]'); } catch (_) {}
    try {
      const avail = JSON.parse(row.availability_json || '{}');
      availability = avail.slots || buildAvailabilitySlots();
    } catch (_) {}
  }

  return {
    username: row?.username || base.username || GEARSH_USERNAME,
    name: row?.name || row?.display_name || base.name || 'The Gearsh',
    tagline: row?.tagline || base.tagline,
    category: row?.category || base.category,
    location: row?.location || base.location,
    country: row?.country || base.country,
    image: row?.image || base.image || GEARSH_DEFAULT.image,
    cover_image_url: row?.cover_image_url || base.cover_image_url,
    bio: row?.bio || base.bio,
    long_bio: row?.long_bio || base.long_bio,
    is_verified: true,
    profile_type: 'master',
    is_master: true,
    artist_id: row?.artist_id,
    user_id: row?.user_id,
    stats: Object.keys(stats).length ? stats : GEARSH_DEFAULT.stats,
    skills: base.skills || GEARSH_DEFAULT.skills,
    social_links: base.social_links || GEARSH_DEFAULT.social_links,
    services: (services && services.length) ? services : GEARSH_DEFAULT.services,
    portfolio_projects: portfolio,
    testimonials: testimonials,
    availability: availability,
    profile_url: '/gearsh',
    book_url: '/gearsh#book',
    rating: row?.rating == null ? null : Number(row.rating),
    review_count: Number(row?.review_count || 0),
    total_bookings: Number(row?.total_bookings || 0),
  };
}
