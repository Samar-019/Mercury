import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mercury/app/theme/design_tokens.dart';
import 'package:mercury/app/theme/glass_theme.dart';
import 'package:mercury/core/widgets/artwork.dart';

/// The canvas behind every screen: near-black with soft light falloff, and —
/// when Liquid Glass is on in Balanced mode — a faint monochrome wash of the
/// current artwork so glass surfaces have something to refract.
///
/// The artwork is decoded at 24 px and upscaled; bilinear filtering produces
/// the blur for free instead of running a full-screen blur filter.
class MercuryBackdrop extends StatelessWidget {
  const MercuryBackdrop({this.artworkPath, super.key});

  final String? artworkPath;

  static const _grayscale = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final c = context.mercury;
    final fx = MercuryEffects.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: c.background),
          // Rainbow & Aurora Borealis Ambient Canvas Flow
          if (dark) ...[
            // Aurora Orb 1: Cyan-Blue electric flow
            Positioned(
              top: -100,
              left: -80,
              width: 500,
              height: 500,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF06B6D4).withValues(alpha: 0.12),
                      const Color(0xFF3B82F6).withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Aurora Orb 2: Neon Purple-Pink flow
            Positioned(
              top: 140,
              right: -100,
              width: 550,
              height: 550,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFA855F7).withValues(alpha: 0.10),
                      const Color(0xFFEC4899).withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Aurora Orb 3: Emerald Ambient shimmer
            Positioned(
              bottom: -60,
              left: 120,
              width: 480,
              height: 480,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF10B981).withValues(alpha: 0.08),
                      const Color(0xFF06B6D4).withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (fx.highlights)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.7, -0.9),
                  radius: 1.3,
                  colors: [
                    (dark ? Colors.white : Colors.black).withValues(
                      alpha: dark ? 0.06 : 0.03,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          if (fx.ambient && artworkPath != null)
            AnimatedSwitcher(
              duration: fx.motion(MercuryMotion.slow * 2),
              // The switcher lays its children out loosely: without this
              // the 24 px image would sit small in the middle.
              layoutBuilder: (current, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, ?current],
              ),
              child: Opacity(
                key: ValueKey(artworkPath),
                opacity: dark ? 0.18 : 0.12,
                child: ColorFiltered(
                  colorFilter: _grayscale,
                  child: isRemoteImage(artworkPath!)
                      ? Image.network(
                          artworkPath!,
                          fit: BoxFit.cover,
                          cacheWidth: 24,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        )
                      : Image.file(
                          File(artworkPath!),
                          fit: BoxFit.cover,
                          cacheWidth: 24,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
