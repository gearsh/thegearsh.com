import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GearshFooter extends StatelessWidget {
  const GearshFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A202C), // bg-gray-900
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          // Main grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isLarge = constraints.maxWidth >= 1024;
              final isMedium = constraints.maxWidth >= 768;
              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 32,
                children: [
                  _footerColumn(
                    title: 'Gearsh',
                    items: [
                      _FooterLink('Visit Help Center'),
                    ],
                    span: isMedium ? 2 : 1,
                  ),
                  _footerColumn(
                    title: 'Company',
                    items: [
                      _FooterLink('About us'),
                      _FooterLink('Our offerings'),
                      _FooterLink('Newsroom'),
                      _FooterLink('Investors'),
                      _FooterLink('Blog'),
                      _FooterLink('Careers'),
                    ],
                  ),
                  _footerColumn(
                    title: 'Products',
                    items: [
                      _FooterLink('Book an Artist'),
                      _FooterLink('Gear Sharing'),
                      _FooterLink('Events'),
                      _FooterLink('Merchandise'),
                      _FooterLink('Gearsh for Business'),
                      _FooterLink('Gift Cards'),
                    ],
                  ),
                  _footerColumn(
                    title: 'Global Citizenship',
                    items: [
                      _FooterLink('Safety'),
                      _FooterLink('Sustainability'),
                      _FooterLink('Travel'),
                    ],
                  ),
                  if (isLarge)
                    _footerColumn(
                      title: 'Reserve',
                      items: [
                        _FooterLink('Book Talent'),
                        _FooterLink('Venues'),
                        _FooterLink('Cities'),
                      ],
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          Divider(color: const Color(0xFF374151)), // border-gray-700
          const SizedBox(height: 24),
          // Bottom row
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 640;
              return isSmall
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('English', style: _footerTextStyle),
                            SizedBox(width: 16),
                            _FooterLink('Thohoyandou, Limpopo'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('© 2025 Gearsh Inc.', style: _footerTextStyle),
                            SizedBox(width: 16),
                            _FooterLink('Privacy'),
                            SizedBox(width: 16),
                            _FooterLink('Accessibility'),
                            SizedBox(width: 16),
                            _FooterLink('Terms'),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('English', style: _footerTextStyle),
                            SizedBox(width: 16),
                            _FooterLink('Thohoyandou, Limpopo'),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('© 2025 Gearsh Inc.', style: _footerTextStyle),
                            SizedBox(width: 16),
                            _FooterLink('Privacy'),
                            SizedBox(width: 16),
                            _FooterLink('Accessibility'),
                            SizedBox(width: 16),
                            _FooterLink('Terms'),
                          ],
                        ),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _footerColumn({
    required String title,
    required List<Widget> items,
    int span = 1,
  }) {
    return Container(
      width: 180.0 * span,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  const _FooterLink(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            // Simple internal navigation mapping
            final routes = {
              'About us': '/about',
              'Visit Help Center': '/help',
              'Book an Artist': '/signup',
              'Privacy': '/privacy',
              'Terms': '/terms',
              'Accessibility': '/accessibility',
              'Blog': '/blog',
              'Careers': '/careers',
              'Our offerings': '/offerings',
              'Newsroom': '/newsroom',
              'Investors': '/investors',
              'Gear Sharing': '/gear-sharing',
              'Events': '/events',
              'Merchandise': '/merch',
              'Gearsh for Business': '/business',
              'Gift Cards': '/gift-cards',
              'Safety': '/safety',
              'Sustainability': '/sustainability',
              'Travel': '/travel',
              'Book Talent': '/book-talent',
              'Venues': '/venues',
              'Cities': '/cities',
              'Thohoyandou, Limpopo': '/location',
            };
            final route = routes[text];
            if (route != null) {
              // Normalize and use GoRouter for navigation to avoid missing leading slash
              final normalized = route.startsWith('/') ? route : '/$route';
              // ignore: use_build_context_synchronously
              GoRouter.of(context).go(normalized);
            } else {
              // For unknown or external links, do nothing or open in new tab
              // Optionally, use url_launcher for external URLs
            }
          },
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF9CA3AF), // text-gray-400
              fontSize: 15,
              decoration: TextDecoration.underline,
              decorationColor: Colors.transparent,
              decorationThickness: 2,
            ),
          ),
        ),
      ),
    );
  }
}

const _footerTextStyle = TextStyle(
  color: Color(0xFF9CA3AF),
  fontSize: 15,
);
