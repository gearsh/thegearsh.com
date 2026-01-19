# Gearsh Backend Setup - Ready for Launch v1.0.0

## Role-Specific Features

### 👤 CLIENT (Book Artists)
- **Explore**: Browse and discover artists
- **Messages**: Chat with artists about bookings
- **Bookings**: View and manage your event bookings
- **Profile**: My Bookings, Saved Artists, Cart, Payment Methods
- **Artist Profile Actions**: "Book Now" button + Message

### 🎨 ARTIST (Get Booked)
- **Explore**: Browse other artists, see competitors
- **Dashboard**: Manage bookings, earnings, calendar, services
- **Messages**: Receive booking inquiries from clients
- **Profile**: Artist Dashboard, Manage Services, Portfolio, Earnings
- **Other Artist Profile Actions**: "Connect" button (networking) + Message

### 🎵 FAN (Follow Artists & Gigs)
- **Explore**: Discover favorite artists
- **Messages**: Chat with artists
- **Gigs**: Browse upcoming events and concerts
- **Profile**: Artists I Follow, Upcoming Gigs, Event Alerts
- **Artist Profile Actions**: "Follow" button + View Gigs

---

## Backend Infrastructure (Cloudflare Workers + D1)

### API Endpoints Available

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/artists` | GET | List/search artists with filters |
| `/api/artists/:id` | GET | Get artist by ID |
| `/api/bookings` | POST | Create new booking |
| `/api/bookings` | GET | Get user's bookings |
| `/api/bookings/:id` | PATCH | Update booking status |
| `/api/reviews` | POST | Submit review |
| `/api/reviews` | GET | Get artist reviews |
| `/api/signup` | POST | User registration |
| `/api/update-profile` | POST | Update user profile |
| `/api/upload-profile-photo` | POST | Upload profile photo |
| `/api/health` | GET | Health check |

### Database Schema (D1)

Tables:
- `users` - User accounts (artists, clients, admins)
- `artist_profiles` - Extended artist info
- `services` - Services offered by artists
- `bookings` - Booking records
- `reviews` - Artist reviews
- `messages` - Chat messages
- `signups` - Registration queue
- `password_resets` - Password reset tokens

### Dart Services Implemented

1. **BookingService** (`lib/services/booking_service.dart`)
   - `createBooking()` - Create new booking
   - `getBookings()` - Fetch user bookings
   - `cancelBooking()` - Cancel a booking
   - `confirmBooking()` - Confirm a booking (artist)
   - `completeBooking()` - Mark booking complete

2. **ArtistService** (`lib/services/artist_service.dart`)
   - `fetchArtists()` - Search/filter artists
   - `getArtistById()` - Get single artist
   - `getTrendingArtists()` - Get trending artists
   - `getArtistsByCategory()` - Filter by category
   - Falls back to local data if API unavailable

3. **ReviewsService** (`lib/services/reviews_service.dart`)
   - `submitReview()` - Submit artist review
   - `getArtistReviews()` - Get artist's reviews
   - `getArtistAverageRating()` - Calculate rating

4. **BookingProvider** (`lib/providers/booking_provider.dart`)
   - Full state management for bookings
   - Separates upcoming/past bookings
   - Loading and error states

### Deployment

```bash
# Deploy to Cloudflare Pages
cd C:\Users\admin\StudioProjects\thegearsh.com
wrangler pages deploy . --project-name=thegearsh-com

# Or use the deploy script
.\deploy_cloudflare.ps1
```

### Environment Variables (Cloudflare Dashboard)

Required secrets:
- `DB` - D1 database binding
- `PROFILE_IMAGES` - R2 bucket for profile photos (optional)

### Testing

```bash
# Test health endpoint
curl https://thegearsh-com.pages.dev/api/health

# Test artists endpoint
curl https://thegearsh-com.pages.dev/api/artists
```

## Status: ✅ Ready for Launch

All backend services are implemented and ready. The app will:
1. Try to fetch from the API first
2. Fall back to local data (gearsh_artists.dart) if API unavailable
3. Handle errors gracefully with user-friendly messages
