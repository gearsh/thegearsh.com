# Gearsh Booking Infrastructure

## Overview

Gearsh implements a comprehensive booking infrastructure designed to:
- **Record facts** without judgement
- **Prevent disputes** before they escalate publicly
- **Protect all parties** (artists, clients, and audiences)
- **Provide an audit trail** for resolution

> **Core Principle**: Gearsh does not decide who is right. Gearsh records what happened.

---

## Architecture

```
lib/
├── models/
│   ├── booking_agreement.dart    # Immutable booking contracts
│   ├── escrow_payment.dart       # Conditional payment holds
│   ├── booking_lifecycle.dart    # Status tracking & verification
│   ├── incident_report.dart      # Private incident logging
│   ├── communication_log.dart    # Auditable communication threads
│   ├── reliability_index.dart    # Private reliability metrics
│   └── models.dart               # Export file
│
└── services/
    ├── booking_agreement_service.dart
    ├── escrow_service.dart
    ├── booking_lifecycle_service.dart
    ├── incident_report_service.dart
    ├── communication_log_service.dart
    ├── reliability_index_service.dart
    └── booking_infrastructure_service.dart  # Central orchestration
```

---

## 1. Booking Agreement Logic

### Purpose
Structured, immutable agreements that lock all terms before confirmation.

### Key Features
- **Performance Details**: Date, time, duration, arrival deadline, grace period
- **Financial Terms**: Fee structure, deposits, service fee, travel/accommodation
- **Hospitality Rider**: Items, quantities, brands, inclusions/exclusions
- **Digital Signatures**: Both parties must sign
- **Amendment Process**: Changes require explicit approval

### Agreement Lifecycle
```
Draft → Pending Artist Signature → Pending Client Signature → Confirmed (Locked)
                                                                    ↓
                                              Amendment Requested → Approved/Rejected
```

### Usage
```dart
// Create agreement
final agreement = await bookingAgreementService.createAgreement(
  bookingId: 'booking_123',
  artistId: 'artist_456',
  clientId: 'client_789',
  performance: performanceDetails,
  financialTerms: financialTerms,
  rider: hospitalityRider,
);

// Sign agreement
await bookingAgreementService.signAgreement(
  agreementId: agreement.id,
  userId: artistId,
  isArtist: true,
  signature: 'digital_signature',
);

// Request amendment (after locked)
await bookingAgreementService.requestAmendment(
  agreementId: agreement.id,
  requestedBy: clientId,
  fieldChanged: 'performanceStartTime',
  previousValue: '20:00',
  newValue: '21:00',
  reason: 'Venue opening delayed',
);
```

---

## 2. Escrow & Conditional Payments

### Purpose
Hold funds until predefined conditions are met, with automatic resolution paths.

### Release Conditions
| Condition | Description | Release % |
|-----------|-------------|-----------|
| Artist Checked In | Verified arrival at venue | 0% (record only) |
| Performance Started | Confirmed by client | 50% |
| Performance Completed | Both parties confirm | 50% |

### Escrow Statuses
- `pending` - Awaiting payment
- `funded` - Funds received and held
- `partialRelease` - Some conditions met
- `released` - Full release to artist
- `refunded` - Full return to client
- `disputed` - Under dispute resolution

### Resolution Types
- Full release to artist
- Full refund to client
- Partial split
- Credit for reschedule

### Usage
```dart
// Create escrow
final escrow = await escrowService.createEscrow(
  bookingId: 'booking_123',
  agreementId: 'agreement_456',
  payerId: clientId,
  payeeId: artistId,
  amount: 5000.00,
  currencyCode: 'ZAR',
);

// Mark condition met (triggers partial release)
await escrowService.markConditionMet(
  escrowId: escrow.id,
  conditionId: 'booking_123_started',
  verifiedBy: 'system',
);
```

---

## 3. Arrival & Performance Status Tracking

### Purpose
Time-stamped, verifiable lifecycle states that remove ambiguity.

### Status Flow
```
Scheduled → En Route → Arrived → Checked In → Preparing → Performing → Completed
                                                              ↓
                                                          On Break
                                                              ↓
                                                     Did Not Perform
```

### Each Status Contains
- Timestamp (immutable)
- Who updated it
- Verification method
- Location data (if applicable)
- Notes

### Verification Types
- `selfReported` - User reported
- `locationBased` - GPS verified
- `photoVerified` - Photo evidence
- `qrCodeScan` - QR check-in
- `otherPartyConfirmed` - Other party verified
- `systemAutomatic` - System triggered

### Usage
```dart
// Mark artist as en route
await bookingLifecycleService.markEnRoute(
  bookingId: 'booking_123',
  artistId: 'artist_456',
  currentLocation: GeoLocation(lat: -26.2041, long: 28.0473),
);

// Mark checked in with verification
await bookingLifecycleService.markCheckedIn(
  bookingId: 'booking_123',
  artistId: 'artist_456',
  location: venueLocation,
  verifiedBy: clientId,
);
```

---

## 4. Locked Rider Enforcement

### Purpose
Prevent informal rider changes that cause disputes.

### Rules
- Riders are finalised before agreement confirmation
- Once locked, riders cannot be altered without amendment
- Any changes must be submitted and approved in-app
- Unapproved changes are logged

### Rider Contents
- Items with quantities and brands
- Inclusions (what IS provided)
- Exclusions (what is NOT provided)
- Dressing room requirements
- Guest list spots
- Catering requirements
- Transport requirements

---

## 5. Incident Reporting (Private)

### Purpose
Private logging of issues without public visibility.

### Incident Types (Neutral Language)
| Type | Display Name | Description |
|------|--------------|-------------|
| unsafeEnvironment | Environment Concern | Venue safety issues |
| verbalConflict | Communication Issue | Verbal disagreements |
| hostileEnvironment | Environment Concern | Uncomfortable environment |
| agreementBreach | Agreement Discrepancy | Terms differ from actual |
| unableToProceed | Unable to Proceed | Cannot continue |
| technicalIssue | Technical Issue | Equipment problems |
| riderIssue | Rider Discrepancy | Rider items not provided |
| paymentDispute | Payment Query | Financial concerns |

### Rules
- **Private only** - Never public
- **No comments or feeds** - Not social
- **Audit trail only** - Used for resolution
- **Auto-escalation** - Critical incidents flagged

### Usage
```dart
final incident = await incidentReportService.submitReport(
  bookingId: 'booking_123',
  reporterId: artistId,
  reporterRole: 'artist',
  type: IncidentType.riderIssue,
  description: 'Requested items were not available in dressing room',
  severity: IncidentSeverity.medium,
);
```

---

## 6. Booking-Scoped Communication Log

### Purpose
Auditable communication thread eliminating "we tried contacting them" ambiguity.

### Features
- **All parties included** (artist, client, manager)
- **Read receipts** - Who read, when
- **Timestamps** - Immutable
- **No deletion** - Marked but preserved
- **Silence logging** - Periods of no communication tracked

### Metrics Tracked
- Total messages
- Messages by role
- Average response time
- Longest silence period

### System Messages
Automatic notifications for:
- Status changes
- Payment updates
- Agreement amendments
- Rider changes

### Usage
```dart
// Send message
await communicationLogService.sendMessage(
  threadId: thread.id,
  senderId: artistId,
  senderRole: 'artist',
  senderName: 'DJ Example',
  content: 'Confirming arrival at 6 PM',
);

// Mark read
await communicationLogService.markMessageRead(
  threadId: thread.id,
  messageId: message.id,
  userId: clientId,
  userName: 'Event Organiser',
);
```

---

## 7. Reliability Index (Private, Non-Punitive)

### Purpose
Internal context for booking decisions. **NEVER PUBLIC**.

### Metrics Tracked
| Metric | For | Description |
|--------|-----|-------------|
| Completion Rate | Both | % of bookings completed |
| Cancellation Rate | Both | % of bookings cancelled |
| On-Time Rate | Artists | % of on-time arrivals |
| Response Rate | Both | % of messages responded to |
| Incident Count | Both | Number of incidents |
| Payment Reliability | Clients | % of on-time payments |

### Key Rules
- **Never public** - No badges or labels
- **No "good" or "bad"** - Just factual context
- **Non-punitive** - Information only
- **For internal use** - Support and system decisions

### Context Summaries (Example)
```
"Established booking history" - 20+ bookings
"Very high completion rate" - 95%+ completion
"Usually arrives on time" - 90%+ on-time
"Very responsive communicator" - 90%+ response rate
```

---

## Central Orchestration

The `BookingInfrastructureService` coordinates all services:

```dart
// Initialize all infrastructure for a booking
final infrastructure = await bookingInfrastructureService.initializeBooking(
  bookingId: 'booking_123',
  artistId: 'artist_456',
  clientId: 'client_789',
  performance: performanceDetails,
  financialTerms: financialTerms,
  rider: hospitalityRider,
);

// Process check-in (updates lifecycle, escrow, reliability, communication)
await bookingInfrastructureService.processArtistCheckIn(
  bookingId: 'booking_123',
  artistId: 'artist_456',
  location: venueLocation,
);

// Get complete audit trail
final audit = await bookingInfrastructureService.getAuditTrail('booking_123');
```

---

## API Contracts (Backend Integration)

### Agreement Endpoints
```
POST   /api/agreements                    Create agreement
GET    /api/agreements/:id                Get agreement
POST   /api/agreements/:id/sign           Sign agreement
POST   /api/agreements/:id/amendments     Request amendment
PUT    /api/agreements/:id/amendments/:id Resolve amendment
```

### Escrow Endpoints
```
POST   /api/escrow                        Create escrow
GET    /api/escrow/:id                    Get escrow status
POST   /api/escrow/:id/fund               Mark funded
POST   /api/escrow/:id/conditions/:id     Mark condition met
POST   /api/escrow/:id/release            Release funds
POST   /api/escrow/:id/refund             Refund funds
POST   /api/escrow/:id/dispute            Place under dispute
```

### Lifecycle Endpoints
```
POST   /api/bookings/:id/status           Update status
GET    /api/bookings/:id/status/history   Get status history
POST   /api/bookings/:id/checkin          Process check-in
```

### Communication Endpoints
```
POST   /api/threads                       Create thread
GET    /api/threads/:id/messages          Get messages
POST   /api/threads/:id/messages          Send message
POST   /api/threads/:id/messages/:id/read Mark read
```

### Incident Endpoints
```
POST   /api/incidents                     Submit report
GET    /api/incidents/:id                 Get report
PUT    /api/incidents/:id/status          Update status
POST   /api/incidents/:id/resolve         Resolve incident
```

---

## Language & Copy Guidelines

### Use These Verbs
- record
- confirm
- log
- resolve
- protect
- structure
- verify
- document

### Avoid These Words
- scam
- fraud
- steal
- blame
- accuse
- guilty
- fault
- bad/good

### Example Messages
❌ "Artist failed to arrive"
✅ "Arrival not recorded within grace period"

❌ "Client didn't pay on time"
✅ "Payment received after scheduled date"

❌ "Dispute filed against artist"
✅ "Incident report submitted for booking"

---

## Success Criteria

Gearsh is successful when:
1. Disputes are resolved within the system
2. No public statements needed
3. No screenshots shared
4. No apology letters required
5. Facts speak for themselves

---

*Last Updated: December 2025*

