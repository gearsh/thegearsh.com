// Default content for @gearsh Master Profile

export const GEARSH_USERNAME = 'gearsh';

export const GEARSH_DEFAULT = {
  username: 'gearsh',
  name: 'The Gearsh',
  tagline: 'Building Africa\'s next tech empires from the home office',
  category: 'Tech & Product',
  location: 'South Africa',
  country: 'South Africa',
  is_verified: true,
  profile_type: 'master',
  cover_image_url: '/assets/images/gearsh-cover.jpg',
  image: '/icons/Icon-512.png',
  bio: 'Founder and lead builder at Gearsh. I ship websites, mobile apps, AI automations, and full platforms for artists, brands, and ambitious founders across Africa.',
  long_bio: `The Gearsh is the founder and lead tech builder behind Gearsh — the platform connecting South African artists, fans, and bookers.

From late nights in the home office to production deployments before sunrise, The Gearsh builds the digital infrastructure that powers modern African entertainment and business. Rooted in South Africa, driven by a vision to become one of the biggest names in African tech.

Whether you need a custom website, a mobile app, an AI-powered automation, or a full platform MVP — The Gearsh delivers with precision, speed, and a founder's obsession for quality.

This is not agency fluff. This is hands-on building from someone who ships their own product every day.`,
  stats: {
    projects_completed: 52,
    clients_served: 38,
    hours_coded: 12400,
    response_time: '< 24 hrs',
    satisfaction: '98%',
  },
  skills: [
    'Full-stack development',
    'Mobile apps (iOS & Android)',
    'AI integrations',
    'Platform architecture',
    'Product strategy',
    'Web apps & MVPs',
  ],
  social_links: {
    website: 'https://thegearsh.com',
    twitter: 'https://x.com/thegearsh',
    github: 'https://github.com/thegearsh',
  },
  services: [
    {
      id: 'svc_gearsh_web',
      name: 'Custom Website & Web App',
      description: 'Premium responsive website or web application — design, build, deploy, and handover with documentation.',
      price: 15000,
      duration_hours: 40,
      delivery_days: 14,
      is_featured: 1,
      deliverables: ['Responsive design', 'CMS or admin panel', 'SEO setup', 'Deployment & hosting guide', '30-day support'],
    },
    {
      id: 'svc_gearsh_mobile',
      name: 'Mobile App (iOS & Android)',
      description: 'Cross-platform mobile app with polished UI, auth, payments, and App Store / Play Store readiness.',
      price: 35000,
      duration_hours: 120,
      delivery_days: 42,
      is_featured: 1,
      deliverables: ['Flutter or React Native app', 'Backend API integration', 'Push notifications', 'Store submission support', 'Source code handover'],
    },
    {
      id: 'svc_gearsh_mvp',
      name: 'Full Tech Product / MVP',
      description: 'End-to-end product build — from idea to launch-ready platform with auth, payments, and admin dashboard.',
      price: 75000,
      duration_hours: 200,
      delivery_days: 60,
      is_featured: 1,
      deliverables: ['Product architecture', 'Full-stack build', 'Payment integration', 'Admin dashboard', 'Launch support'],
    },
    {
      id: 'svc_gearsh_ai',
      name: 'AI Integrations & Automations',
      description: 'Chatbots, workflow automations, AI agents, and custom integrations that save hours every week.',
      price: 12000,
      duration_hours: 24,
      delivery_days: 10,
      is_featured: 0,
      deliverables: ['AI workflow design', 'Integration build', 'Testing & documentation', 'Training session'],
    },
    {
      id: 'svc_gearsh_consult',
      name: 'Tech Consulting & Strategy',
      description: '1-on-1 strategy session — architecture review, tech stack decisions, roadmap planning, and honest advice.',
      price: 2500,
      duration_hours: 2,
      delivery_days: 1,
      is_featured: 0,
      deliverables: ['60-90 min session', 'Written summary', 'Action plan', 'Follow-up email support'],
    },
    {
      id: 'svc_gearsh_roadmap',
      name: 'Product Roadmapping',
      description: 'Structured product roadmap with milestones, tech specs, timeline, and budget estimates for your build.',
      price: 8500,
      duration_hours: 16,
      delivery_days: 7,
      is_featured: 0,
      deliverables: ['Discovery call', 'Feature prioritisation', 'Technical spec', 'Timeline & milestones', 'Budget breakdown'],
    },
    {
      id: 'svc_gearsh_audit',
      name: 'Tech Audit',
      description: 'Deep review of your existing codebase, infrastructure, or product — with a clear improvement plan.',
      price: 6500,
      duration_hours: 12,
      delivery_days: 5,
      is_featured: 0,
      deliverables: ['Code/infrastructure review', 'Security checklist', 'Performance report', 'Priority fix list'],
    },
    {
      id: 'svc_gearsh_platform',
      name: 'Platform Build',
      description: 'Scalable multi-user platform with bookings, payments, dashboards, and the works — built to grow.',
      price: 50000,
      duration_hours: 160,
      delivery_days: 45,
      is_featured: 0,
      deliverables: ['Platform architecture', 'User auth & roles', 'Payment gateway', 'Admin panel', 'Deployment pipeline'],
    },
  ],
  portfolio_projects: [
    {
      title: 'Gearsh Platform',
      description: 'The full artist booking, ticketing, and discovery platform you are using right now.',
      image: '/icons/Icon-512.png',
      url: 'https://thegearsh.com',
      tags: ['Platform', 'Full-stack', 'Payments'],
      result: 'Live production platform serving artists across South Africa',
    },
    {
      title: 'Artist Booking System',
      description: 'Secure direct booking with PayFast payments, escrow, and real-time dashboards.',
      image: '/icons/og-image.png',
      url: 'https://thegearsh.com',
      tags: ['Web App', 'PayFast', 'Cloudflare'],
      result: 'Zero middleman booking flow with 12.6% platform fee model',
    },
    {
      title: 'Ticket Purchase Engine',
      description: 'Full event ticketing with inventory management, QR codes, and instant digital tickets.',
      image: '/icons/Icon-512.png',
      url: 'https://thegearsh.com/gig',
      tags: ['Ticketing', 'QR', 'E-commerce'],
      result: 'End-to-end ticket flow from gig creation to door check-in',
    },
  ],
  testimonials: [
    {
      name: 'Thabo M.',
      role: 'Artist Manager, Johannesburg',
      quote: 'The Gearsh built our booking page in days. Clean, fast, and clients actually pay through the platform. Game changer.',
      rating: 5,
    },
    {
      name: 'Lerato K.',
      role: 'Startup Founder, Cape Town',
      quote: 'Needed an MVP fast. Got a full platform with auth, payments, and admin — shipped in 6 weeks. Exactly what we needed.',
      rating: 5,
    },
    {
      name: 'David N.',
      role: 'Event Promoter, Durban',
      quote: 'The ticketing system works flawlessly. Sold out our first event with zero payment issues. Professional from start to finish.',
      rating: 5,
    },
    {
      name: 'Amanda S.',
      role: 'Brand Director',
      quote: 'Tech audit saved us from a security disaster. Clear report, fixed the critical issues, and gave us a roadmap. Worth every rand.',
      rating: 5,
    },
  ],
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
    image: row?.image || row?.profile_picture_url || base.image,
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
    portfolio_projects: portfolio.length ? portfolio : GEARSH_DEFAULT.portfolio_projects,
    testimonials: testimonials.length ? testimonials : GEARSH_DEFAULT.testimonials,
    availability: availability,
    profile_url: '/gearsh',
    book_url: '/gearsh#book',
    rating: Number(row?.rating || 5),
    review_count: Number(row?.review_count || GEARSH_DEFAULT.testimonials.length),
    total_bookings: Number(row?.total_bookings || 0),
  };
}
