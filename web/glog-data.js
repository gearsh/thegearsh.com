/**
 * G-Log: Gearsh Blog post registry
 *
 * To publish a new article:
 * 1. Add an object to GLOG_POSTS (newest first helps the index).
 * 2. Set slug, title, excerpt, featuredImage, categories, tags, and content (Markdown).
 * 3. Optionally set featured: true for the hero slot (only one should be featured).
 * 4. Add the URL to web/sitemap.xml.
 */
(function (global) {
  'use strict';

  var GLOG_CATEGORIES = [
    'All',
    'News',
    'Amapiano',
    'Hip Hop',
    'Afro House',
    'Gospel',
    'Artist Spotlight',
    'International Breakthrough',
    'Industry Tips',
  ];

  var GLOG_POSTS = [
    {
      slug: 'tyla-water-and-the-new-sa-export-playbook',
      title: 'Tyla, Water, and the New SA Export Playbook',
      excerpt: 'How South African pop went from local stardom to Grammy stages, and what it means for every artist building a global career from Mzansi.',
      featuredImage: 'assets/images/artists/tyla.jpg',
      author: 'Gearsh',
      publishedAt: '2026-05-22',
      readTimeMinutes: 7,
      featured: true,
      categories: ['News', 'International Breakthrough', 'Artist Spotlight'],
      tags: ['Tyla', 'Afropop', 'Global', 'Export'],
      content: [
        'South Africa has always exported culture. But 2024 and 2025 felt different. When **Tyla** turned *Water* into a global chant, she didn\'t just win awards. She rewrote the playbook for how Mzansi artists think about international careers.',
        '',
        '## The shift is structural, not accidental',
        '',
        'Three forces collided:',
        '',
        '- **Streaming discovery:** TikTok and Spotify can surface a Pretoria demo to São Paulo overnight.',
        '- **Genre fusion:** Afropop, amapiano log drums, and R&B hooks travel further than pure local formats ever did.',
        '- **Professional infrastructure:** managers, publishers, and booking agents now treat Johannesburg and Cape Town like Lagos or London on the routing map.',
        '',
        '> "The world isn\'t waiting for you to be ready. They\'re waiting for you to be *findable*." Every A&R in 2026.',
        '',
        '## What artists can learn from Tyla\'s arc',
        '',
        '1. **Own one unmistakable song** before you chase an album cycle.',
        '2. **Invest in visuals early.** Your press photo is your business card.',
        '3. **Make booking frictionless.** Festivals and brands book artists who respond fast with clear fees.',
        '',
        'On Gearsh, artists like Tyla appear as discoverable, bookable profiles. When the call comes, you need a link ready. Not a DM thread.',
        '',
        '## The Mzansi advantage',
        '',
        'South African artists carry multilingual fluency, dance culture, and genre-blending instincts that global audiences crave. The artists who win internationally still **show up locally**: club sets, corporate gigs, and township festivals keep the craft sharp.',
        '',
        'The next wave won\'t come from one viral moment. It\'ll come from hundreds of artists treating their careers like businesses: great music, clear branding, and professional booking.',
      ].join('\n'),
    },
    {
      slug: 'amapiano-2026-what-bookers-are-paying-for',
      title: 'Amapiano in 2026: What Bookers Are Actually Paying For',
      excerpt: 'From log drum festivals to private yacht parties. A practical look at amapiano booking fees, set lengths, and what promoters expect.',
      featuredImage: 'assets/images/artists/P9-Kabza-de-Small.webp',
      author: 'Gearsh',
      publishedAt: '2026-05-18',
      readTimeMinutes: 6,
      categories: ['Amapiano', 'Industry Tips', 'News'],
      tags: ['Amapiano', 'Kabza De Small', 'Booking fees', 'Festivals'],
      content: [
        'Amapiano isn\'t a trend anymore. It\'s the **default dance language** of South African nightlife. But if you\'re an artist or DJ trying to price your sets, the market can feel opaque.',
        '',
        '## The fee ladder (approximate, 2026)',
        '',
        '| Tier | Example profile | Typical club/festival fee |',
        '| --- | --- | --- |',
        '| Headline | Kabza De Small, DJ Maphorisa | R250k to R500k+ |',
        '| Established | Major League DJz, Felo Le Tee | R80k to R180k |',
        '| Rising | Breakout producers with streaming heat | R25k to R60k |',
        '',
        '*Fees vary by city, season, production rider, and exclusivity.*',
        '',
        '## What promoters actually buy',
        '',
        '- **Energy management:** piano sets build; the best DJs read the room.',
        '- **Visual identity:** merch, styling, and social presence matter as much as the tracklist.',
        '- **Reliability:** showing up on time with USB backups still wins repeat bookings.',
        '',
        '## Gearsh tip',
        '',
        'List three service tiers on your profile: **club set (1hr)**, **festival headline (90 min)**, and **private event (full show)**. Bookers compare quotes in seconds. Make theirs easy.',
      ].join('\n'),
    },
    {
      slug: 'a-reece-and-the-pretoria-hip-hop-machine',
      title: 'A-Reece and the Pretoria Hip Hop Machine',
      excerpt: 'Why Pretoria keeps producing hip hop leaders, and how independent artists are bypassing traditional label gatekeepers.',
      featuredImage: 'assets/images/artists/a-reece.png',
      author: 'Gearsh',
      publishedAt: '2026-05-14',
      readTimeMinutes: 5,
      categories: ['Hip Hop', 'Artist Spotlight'],
      tags: ['A-Reece', 'Pretoria', 'Hip Hop', 'Independent'],
      content: [
        'Pretoria hip hop has its own temperature: slower beats, sharper bars, and a culture of **long-form projects** over quick singles. **A-Reece** sits at the centre of that ecosystem, but he\'s not alone.',
        '',
        '## The blueprint',
        '',
        'Independent artists in Tshwane built audiences by:',
        '',
        '1. Releasing consistently (mixtapes still matter).',
        '2. Owning their narrative on social media.',
        '3. Performing anywhere, from campus halls to sneaker pop-ups.',
        '',
        '## Booking hip hop in 2026',
        '',
        'Corporate clients want **clean sets**. Clubs want **energy**. Festivals want **crowd control**. The artists who book the most gigs package their show for each room.',
        '',
        'Gearsh profiles let hip hop artists publish **set lengths, rider notes, and verified fees** so bookers know exactly what they\'re getting before the first WhatsApp.',
      ].join('\n'),
    },
    {
      slug: 'afro-house-wednesday-why-deep-is-winning',
      title: 'Afro House Wednesday: Why Deep Is Winning Nightlife',
      excerpt: 'Deep house and Afro house dominate midweek dance floors. We break down the sound, the cities, and the artists headlining Gearsh tonight.',
      featuredImage: 'assets/images/artists/coffee.png',
      author: 'Gearsh',
      publishedAt: '2026-05-12',
      readTimeMinutes: 4,
      categories: ['Afro House', 'News'],
      tags: ['Black Coffee', 'Shimza', 'Deep House', 'Afro House'],
      content: [
        'Wednesday used to be the quiet night. Not anymore. **Deep House Wednesday** on Gearsh reflects what clubs from Johannesburg to Durban already know: midweek is for **serious dancers**.',
        '',
        '## The sound',
        '',
        'Afro house blends:',
        '',
        '- Soulful vocals and African percussion',
        '- Four-on-the-floor grooves with township swing',
        '- Melodic peaks designed for 2 AM, not 2 PM',
        '',
        '## Artists to watch',
        '',
        'From **Black Coffee**\'s international residency model to **Shimza**\'s Afro-tech crossovers, SA house artists are among the most toured on the continent.',
        '',
        '## For bookers',
        '',
        'Need a Wednesday headline? Filter Gearsh by **House & Afro House**, check verified fees, and send a booking request. No middleman markup.',
      ].join('\n'),
    },
    {
      slug: 'gospel-sunday-the-business-of-worship-music',
      title: 'Gospel Sunday: The Business of Worship Music',
      excerpt: 'Gospel artists fill stadiums and churches alike. Here\'s how choirs, soloists, and producers price events in South Africa.',
      featuredImage: 'assets/images/artists/artists.png',
      author: 'Gearsh',
      publishedAt: '2026-05-08',
      readTimeMinutes: 5,
      categories: ['Gospel', 'Industry Tips'],
      tags: ['Gospel', 'Joyous Celebration', 'Booking', 'Events'],
      content: [
        'Gospel is South Africa\'s **Sunday national language**. From mass choirs to solo worship leaders, the genre powers conferences, church anniversaries, and corporate year-end functions.',
        '',
        '## What clients book',
        '',
        '- **30-minute praise set** for conferences and corporate openings',
        '- **Full worship experience** for church events and crusades',
        '- **Festival slot** on gospel stages at multi-genre events',
        '',
        '## Pricing reality',
        '',
        'Fees range from community love offerings to **six-figure stadium bookings** for established names. Transparency helps ministries and brands budget honestly.',
        '',
        'List your gospel services on Gearsh with **clear durations and travel notes**, especially for artists serving multiple provinces in one weekend.',
      ].join('\n'),
    },
    {
      slug: 'list-your-gig-5-steps-to-more-bookings',
      title: 'List Your Gig: 5 Steps to More Bookings in 2026',
      excerpt: 'A practical Gearsh guide for SA artists: photos, fees, services, and response time. The details that convert profile views into paid gigs.',
      featuredImage: 'assets/images/artists/shimza.jpg',
      author: 'Gearsh',
      publishedAt: '2026-05-05',
      readTimeMinutes: 6,
      categories: ['Industry Tips'],
      tags: ['Gearsh', 'Booking', 'Artists', 'Guide'],
      content: [
        'Your music opens the door. Your **booking profile** closes the deal. On Gearsh, bookers compare dozens of artists in minutes. The profiles that convert are clear, professional, and fast to quote.',
        '',
        'These five steps are what separate artists who get booked from artists who get scrolled past.',
        '',
        '## 1. Use a solo press photo',
        '',
        'Bookers scroll fast. A sharp, well-lit headshot beats a crowd shot or blurry stage pic every time. Profiles with real solo portraits get more clicks and more booking requests on Gearsh.',
        '',
        '**Pro tip:** Use the same photo across Instagram, Spotify, and Gearsh so bookers recognise you instantly.',
        '',
        '## 2. Publish real fees',
        '',
        'Ranges are fine. Silence is not. Corporate clients, festivals, and event planners need a starting point before they reach out. Verified rates build trust and filter out time-wasters.',
        '',
        'List at least one clear package: *from R15,000* for a club set, for example. You can always negotiate up. You can\'t negotiate from nothing.',
        '',
        '## 3. Offer three services',
        '',
        'Most bookers search with a specific event in mind. Give them options that match real gigs:',
        '',
        '- **Club set** (60 to 90 min)',
        '- **Festival headline** (90 min + rider)',
        '- **Private / corporate event** (custom duration)',
        '',
        'Three tiers = three reasons to message you.',
        '',
        '## 4. Fill your bio with credentials',
        '',
        'Awards, streaming numbers, cities played, collabs, TV appearances. Proof reduces negotiation friction. Bookers want to know you\'ve done this before.',
        '',
        'Write like you\'re pitching a festival, not texting a friend. Short, confident, factual.',
        '',
        '## 5. Respond within 24 hours',
        '',
        'The fastest artist to quote often wins the gig, even if they\'re not the cheapest. Enable notifications, keep your calendar updated, and treat every inquiry like money on the table. Because it is.',
        '',
        '**Ready to get booked?** [List your gig on Gearsh](/join-gig.html). It\'s free to start, and your profile goes live in minutes.',
      ].join('\n'),
    },
  ];

  function getPostBySlug(slug) {
    var key = String(slug || '').trim().toLowerCase();
    if (!key) return null;
    for (var i = 0; i < GLOG_POSTS.length; i++) {
      if (GLOG_POSTS[i].slug === key) return GLOG_POSTS[i];
    }
    return null;
  }

  function getFeaturedPost() {
    for (var i = 0; i < GLOG_POSTS.length; i++) {
      if (GLOG_POSTS[i].featured) return GLOG_POSTS[i];
    }
    return GLOG_POSTS[0] || null;
  }

  function sortPostsNewest(posts) {
    return posts.slice().sort(function (a, b) {
      return String(b.publishedAt).localeCompare(String(a.publishedAt));
    });
  }

  function estimateReadTime(text) {
    var words = String(text || '').trim().split(/\s+/).filter(Boolean).length;
    return Math.max(1, Math.round(words / 220));
  }

  global.GLOG_CATEGORIES = GLOG_CATEGORIES;
  global.GLOG_POSTS = GLOG_POSTS;
  global.getGlogPostBySlug = getPostBySlug;
  global.getGlogFeaturedPost = getFeaturedPost;
  global.sortGlogPostsNewest = sortPostsNewest;
  global.estimateGlogReadTime = estimateReadTime;
})(typeof window !== 'undefined' ? window : globalThis);
