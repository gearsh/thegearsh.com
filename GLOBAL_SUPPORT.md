# Gearsh Global Support Documentation

## Overview

Gearsh is now a **global marketplace** for booking artists and gigs worldwide. This document outlines the international features and configuration.

---

## 🌍 Supported Regions

### Africa
| Country | Code | Currency | Symbol |
|---------|------|----------|--------|
| South Africa | ZA | ZAR | R |
| Nigeria | NG | NGN | ₦ |
| Kenya | KE | KES | KSh |
| Ghana | GH | GHS | GH₵ |
| Botswana | BW | BWP | P |
| Namibia | NA | NAD | N$ |
| Zimbabwe | ZW | USD | $ |
| Tanzania | TZ | TZS | TSh |
| Uganda | UG | UGX | USh |
| Rwanda | RW | RWF | FRw |

### Americas
| Country | Code | Currency | Symbol |
|---------|------|----------|--------|
| United States | US | USD | $ |
| Canada | CA | CAD | C$ |
| Brazil | BR | BRL | R$ |

### Europe
| Country | Code | Currency | Symbol |
|---------|------|----------|--------|
| United Kingdom | GB | GBP | £ |
| Germany | DE | EUR | € |
| France | FR | EUR | € |

### Asia Pacific
| Country | Code | Currency | Symbol |
|---------|------|----------|--------|
| Australia | AU | AUD | A$ |
| India | IN | INR | ₹ |
| UAE | AE | AED | د.إ |
| Japan | JP | JPY | ¥ |

---

## 💰 Currency Handling

### How Prices Work

1. **Artists set prices in their local currency**
   - Each artist has a `currencyCode` field (e.g., 'ZAR', 'USD', 'NGN')
   - Prices are stored in their native currency

2. **Users see prices in their selected currency**
   - Users select their region in Profile Settings
   - All prices are automatically converted
   - Exchange rates are updated periodically

3. **Conversion Example**
   ```
   Artist: DJ Maphorisa (South Africa)
   Service Price: R50,000 (ZAR)
   
   User in USA sees: $2,703 (USD)
   User in UK sees: £2,135 (GBP)
   User in Nigeria sees: ₦4,189,189 (NGN)
   ```

### Service Fee
- **12.6%** service fee on all bookings
- Fee is calculated in the user's currency
- Displayed transparently at checkout

---

## 💳 Payment Providers by Region

| Region | Payment Providers |
|--------|-------------------|
| South Africa | PayFast, PayStack, Card |
| Nigeria, Ghana, Kenya | Flutterwave, PayStack, M-Pesa |
| USA, Canada | Stripe, PayPal, Card |
| UK, Europe | Stripe, PayPal, Card |
| Australia | Stripe, PayPal, Card |
| India | Razorpay, PayTM, UPI |
| UAE | Stripe, PayTabs, Card |
| Brazil | PagSeguro, MercadoPago, PIX |

---

## 🛠️ Implementation Details

### Key Files

```
lib/
├── services/
│   └── global_config_service.dart    # Core global configuration
├── providers/
│   └── global_config_providers.dart  # Riverpod providers
├── widgets/
│   ├── region_selector.dart          # Region selection UI
│   └── price_display.dart            # Currency-aware price widgets
└── data/
    └── gearsh_artists.dart           # Artist model with countryCode
```

### Using Price Widgets

```dart
// Display a price in user's currency
PriceText(
  amount: 5000,
  fromCurrency: 'ZAR', // Artist's currency
)

// Display "From R5,000" style
PriceFromText(
  minAmount: 5000,
  fromCurrency: 'ZAR',
)

// Display booking breakdown
ServiceFeeDisplay(
  bookingAmount: 5000,
  fromCurrency: 'ZAR',
)

// Currency badge
CurrencyBadge(currencyCode: 'ZAR')
```

### Accessing Global Config

```dart
// In a widget
final config = ref.read(globalConfigProvider);
final formattedPrice = config.formatPrice(5000);
final shortPrice = config.formatPriceShort(87000); // "R87k"

// Get current region
final region = config.currentRegion;
print(region.flag); // "🇿🇦"
print(region.currencySymbol); // "R"

// Convert currencies
final usdAmount = config.convertToUSD(5000); // ZAR to USD
final localAmount = config.convertFromUSD(100); // USD to current
```

---

## 📱 User Experience

### Region Selection
1. Users can select their region in **Profile Settings**
2. Region preference is persisted locally
3. All prices throughout the app update automatically

### For Artists
- Artists set prices in their local currency
- International clients see converted prices
- `availableWorldwide` flag for international bookings

### For Clients
- See all prices in their preferred currency
- Original currency shown optionally
- Transparent fee breakdown at checkout

---

## 🔒 Legal Compliance

### Data Protection Laws Supported

| Region | Law | Key Requirements |
|--------|-----|------------------|
| European Union | GDPR | Consent, data portability, right to erasure, 72h breach notification |
| California, USA | CCPA | Right to know, delete, opt-out of sale |
| South Africa | POPIA | Consent, purpose limitation, Information Regulator compliance |
| Nigeria | NDPR | Consent, data minimisation, breach notification |
| Brazil | LGPD | Similar to GDPR, DPO requirement |
| UK | UK GDPR | Post-Brexit GDPR equivalent |
| Australia | Privacy Act | APP compliance, cross-border disclosure rules |

### Privacy Policy Features
- Global compliance notice mentioning GDPR, CCPA, POPIA
- Regional user rights section
- International data transfer safeguards (SCCs)
- Contact information for privacy requests

### Terms of Service Features
- Dynamic jurisdiction based on user's region (`globalConfigService.getTermsJurisdiction()`)
- Multi-currency payment terms
- International dispute resolution options
- EU ODR platform reference for EU users

### Terms of Service
- Jurisdiction adapts based on user's region
- Uses `globalConfigService.getTermsJurisdiction()`

---

## 🚀 Adding New Regions

To add a new region:

1. Add to `SupportedRegions` in `global_config_service.dart`:
```dart
static const RegionConfig newCountry = RegionConfig(
  code: 'XX',
  name: 'New Country',
  currencyCode: 'XXX',
  currencySymbol: '¤',
  locale: 'en_XX',
  flag: '🏳️',
  phoneCode: '+XX',
  exchangeRateToUSD: 1.0,
);
```

2. Add to the `all` list and appropriate regional list

3. Update payment providers in `getPaymentProviders()` if needed

---

## 📊 Exchange Rates

Exchange rates are stored statically but should be updated periodically. Consider implementing:

1. **API Integration** - Fetch rates from a currency API
2. **Backend Service** - Store rates in Firebase/backend
3. **Manual Updates** - Update rates with app releases

Current rates are approximate and should be updated regularly.

---

## 🎯 Future Enhancements

- [ ] Real-time currency conversion API
- [ ] Multi-language support (i18n)
- [ ] Region-specific artist recommendations
- [ ] Local payment method integration
- [ ] Tax calculation by region
- [ ] Regional marketing campaigns

---

*Last Updated: December 2025*

