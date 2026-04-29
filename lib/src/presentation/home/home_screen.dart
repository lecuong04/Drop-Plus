import "dart:math";

import "package:flutter/material.dart";
import "package:material_symbols_icons/material_symbols_icons.dart";
import "package:particles_flutter/engine.dart";
import "views/settings_view.dart";
import "views/receive_view.dart";
import "views/send_view.dart";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final List<Particle> _particles;

  int _selectedIndex = 0;

  @override
  void initState() {
    _particles = _createParticles();
    super.initState();
  }

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  List<Particle> _createParticles() {
    double randomSign() {
      var rng = Random();
      return rng.nextBool() ? 1 : -1;
    }

    var rng = Random();
    List<Particle> particles = [];
    for (int i = 0; i < 32; i++) {
      particles.add(
        CircularParticle(
          color: _randomColor(rng),
          radius: rng.nextDouble() * 20,
          velocity: Offset(
            rng.nextDouble() * 200 * randomSign(),
            rng.nextDouble() * 200 * randomSign(),
          ),
        ),
      );
    }
    return particles;
  }

  Color _randomColor(Random rng) {
    return Color.from(
      red: rng.nextDouble(),
      green: rng.nextDouble(),
      blue: rng.nextDouble(),
      alpha: 0.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => Particles(
              particles: _particles,
              height: constraints.maxHeight,
              width: constraints.maxWidth,
              interaction: .none(),
              boundType: .Bounce,
            ),
          ),
          IndexedStack(
            index: _selectedIndex,
            children: const [SendView(), ReceiveView(), SettingsView()],
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Symbols.upload),
            selectedIcon: Icon(Symbols.upload),
            label: "Send",
          ),
          NavigationDestination(
            icon: Icon(Symbols.download),
            selectedIcon: Icon(Symbols.download),
            label: "Receive",
          ),
          NavigationDestination(
            icon: Icon(Symbols.settings),
            selectedIcon: Icon(Symbols.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
