import 'package:flutter/material.dart';

class StoryBehindGearshPage extends StatelessWidget {
  const StoryBehindGearshPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(72),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushReplacementNamed('/'),
                    child: Row(
                      children: [
                        Image.asset('assets/images/gearsh_logo.png', height: 48),
                        const SizedBox(width: 8),
                        const Text('Gearsh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/about'),
                    child: const Text('About', style: TextStyle(color: Colors.tealAccent)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: StadiumBorder(),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/waitlist_form'),
                    child: const Text('Join Waitlist'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.10,
              child: Image.asset(
                'assets/images/allthestars.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 0),
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                constraints: BoxConstraints(maxWidth: 800),
                decoration: BoxDecoration(
                  color: const Color(0xFF181a20),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/'),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Image.asset('assets/images/gearsh_logo.png', height: 96),
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (rect) => LinearGradient(
                        colors: [Color(0xFF00d2ff), Color(0xFF3a7bd5)],
                      ).createShader(rect),
                      child: const Text(
                        'The Story Behind the Name Gearsh',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'People often ask where the word “Gearsh” comes from and what it means. In short, Gearsh is a fusion of “gear” and “share/sharing”, embodying the original vision of a platform for sharing gear (equipment) much like how Uber enables sharing rides. The name reflects both the problem that inspired the company’s founding and the innovative solution that followed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    _sectionTitle('From DJ Dreams to a New Idea'),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset('assets/images/blackcoffee.png', fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Black Coffee at Hï Ibiza – a DJ performing on professional gear, the kind of setup that sparked the idea for Gearsh, and a big finish for the superclub’s first resident DJ.',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF6b7280)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'The story of Gearsh begins with a personal passion and a challenge. In the beginning, our founder aspired to be a DJ, but professional DJ equipment – the turntables, mixers, speakers, and more – was prohibitively expensive for a student. As a computer science student with an entrepreneurial spirit, he looked at this problem and saw an opportunity: what if there were a way to share gear? Musicians and creators often have equipment that sits unused, while others (like aspiring DJs) need that gear temporarily. This gap sparked an idea – a community-driven gear-sharing platform where people could hire or share equipment instead of everyone needing to buy their own.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This innovative idea was rooted in the notion of the sharing economy, where underutilised assets can be shared to benefit others. Just as homeowners share rooms on Airbnb or drivers share rides via Uber, why not let people share their musical or creative gear? It was a win-win: owners could earn money from idle equipment, and borrowers could access expensive gear affordably.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    _sectionTitle('Inspired by Ride‑Sharing and the Sharing Economy'),
                    const SizedBox(height: 8),
                    const Text(
                      'The mid-2010s were a time when “Uber for X” became a buzzworthy concept in tech start-ups. Uber’s success in ride-sharing – connecting riders with drivers through a seamless app – proved that peer-to-peer sharing models could revolutionise industries. In fact, Uber quickly became the poster child of the sharing economy, inspiring entrepreneurs to apply similar models to other fields. Our founder was inspired by this trend and asked: “What if there was an Uber, but for gear?” This meant creating an on-demand network where someone who needs DJ decks, cameras, musical instruments, or any creative equipment could find someone willing to share or hire theirs out.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Armed with his tech background and inspired by these successful platforms, the founder set out to build a peer-to-peer gear-sharing platform. The goal was to make it as easy to borrow a guitar or a DJ mixer as it is to catch a ride across town. The idea wasn’t just about rentals – it was about building a creative community where resources could be shared, lowering the barrier to entry for aspiring artists and creators. This community-driven approach aligns with the broader principles of the sharing economy (sometimes called the peer economy or collaborative consumption), which focuses on access over ownership and making better use of idle resources.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    _sectionTitle('Gear + Sharing = Gearsh'),
                    const SizedBox(height: 8),
                    const Text(
                      'Every start-up needs a memorable name, and our founder wanted a one-word name that captured the essence of the idea. The brainstorming led to a simple combination: “gear” + “share”. By blending these words and trimming a few letters, “Gearsh” was born. This unique name encapsulates the platform’s core purpose – sharing gear – in a concise way. It’s short, catchy, and original, making it easy to remember while still hinting at its meaning.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Creating names by merging or respelling words is a common trend in the tech world. (For example, Lyft tweaks the word “lift” for a ride service, and Shyp respells “ship” for a delivery service.) Similarly, Gearsh invents a new term from familiar parts. It carries the vibe of the word “gear” (equipment and tools) and the spirit of sharing, without being a generic term. The result is a name that feels both invented and meaningful – unique to our brand, but intuitive once you know the story.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Our founder also deliberately sought a name that was short and brandable. In the tech industry, having a snappy one-word name helps a company stand out and gives it room to grow. (Uber and Amazon are great examples of one-word names that became verbs or symbols of entire services.) Gearsh follows this pattern. It’s not a dictionary word, which means we got to define what it stands for. Over time, as the platform evolved, Gearsh became not just a description of gear-sharing, but a brand symbolising innovation in the creative industry.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    _sectionTitle('What “Gearsh” Means Today'),
                    const SizedBox(height: 8),
                    const Text(
                      'Although Gearsh’s origin lies in gear-sharing, the platform has grown and evolved since its founding in 2016. Today, Gearsh is the ultimate artist e-booking service – a digital marketplace that connects musicians, dancers, actors, and other artists with those who want to book them. You might wonder: does the name Gearsh still fit? Absolutely. At its heart, Gearsh has always been about connecting people with the resources and opportunities they need. Whether that resource was a DJ rig or a live gig, Gearsh stands for accessibility and community in the creative space.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'In essence, “Gearsh” means innovation born from necessity. It’s a name that reminds us of our founding story – a student with a dream, an unmet need, and a clever solution. Gearsh represents the idea that with creativity, we can bridge gaps: we can turn “I wish I had this” into “now I can share or get this.” It’s about empowering individuals – be it by sharing equipment or sharing opportunities – and doing so through a seamless, modern platform.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gearsh is more than just a mash-up of words; it’s a testament to our mission. It embodies the DIY spirit and collaborative ethos that kicked off the journey. From the humble beginnings of trying to solve a personal hurdle, to building a community for artists and fans, the name Gearsh carries our history in its 6 letters. Now, when you see the word Gearsh, you know it’s rooted in the concept of gear-sharing and has grown into a platform that helps creators shine. That’s the story behind the name – a story of passion, innovation, and the power of sharing.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Footer
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Color(0xFF222222),
              padding: EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 16,
                    children: [
                      _footerSection('Gearsh', ['Visit Help Center']),
                      _footerSection('Company', ['About us', 'Our offerings', 'Newsroom', 'Investors', 'Blog', 'Careers']),
                      _footerSection('Products', ['Book an Artist', 'Gear Sharing', 'Events', 'Merchandise', 'Gearsh for Business', 'Gift Cards']),
                      _footerSection('Global Citizenship', ['Safety', 'Sustainability', 'Travel']),
                      _footerSection('Reserve', ['Book Talent', 'Venues', 'Cities']),
                    ],
                  ),
                  Divider(color: Colors.grey[700], height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('English', style: TextStyle(color: Colors.grey[400])),
                          SizedBox(width: 16),
                          Text('Makhado, Limpopo', style: TextStyle(color: Colors.grey[400])),
                        ],
                      ),
                      Row(
                        children: [
                          Text('© 2025 Gearsh Inc.', style: TextStyle(color: Colors.grey[400])),
                          SizedBox(width: 16),
                          Text('Privacy', style: TextStyle(color: Colors.grey[400])),
                          SizedBox(width: 16),
                          Text('Accessibility', style: TextStyle(color: Colors.grey[400])),
                          SizedBox(width: 16),
                          Text('Terms', style: TextStyle(color: Colors.grey[400])),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return ShaderMask(
      shaderCallback: (rect) => LinearGradient(
        colors: [Color(0xFF00d2ff), Color(0xFF3a7bd5)],
      ).createShader(rect),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _footerSection(String heading, List<String> items) {
    return Container(
      margin: EdgeInsets.only(right: 32, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          ...items.map((e) => Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(e, style: TextStyle(color: Colors.grey[400])),
          )),
        ],
      ),
    );
  }
}
