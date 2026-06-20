#!/usr/bin/env python3
"""Generate placeholder SVGs for critical MVP assets that couldn't be fetched."""

from pathlib import Path

BASE = Path("scene_kits/experiment_scenes")

SVGS = {
    # Circuit effects
    "circuit/effects/current_flow.svg": """<svg xmlns="http://www.w3.org/2000/svg" width="200" height="60" viewBox="0 0 200 60">
  <defs><marker id="arrow" markerWidth="10" markerHeight="10" refX="5" refY="3" orient="auto" markerUnits="strokeWidth">
    <path d="M0,0 L0,6 L9,3 z" fill="#0ea5e9"/></marker></defs>
  <line x1="10" y1="30" x2="180" y2="30" stroke="#0ea5e9" stroke-width="4" marker-end="url(#arrow)"/>
  <line x1="10" y1="30" x2="180" y2="30" stroke="#0ea5e9" stroke-width="4" stroke-dasharray="8,6" opacity="0.6"/>
</svg>""",

    "circuit/effects/current_arrows.svg": """<svg xmlns="http://www.w3.org/2000/svg" width="120" height="60" viewBox="0 0 120 60">
  <defs><marker id="a" markerWidth="10" markerHeight="10" refX="5" refY="3" orient="auto" markerUnits="strokeWidth">
    <path d="M0,0 L0,6 L9,3 z" fill="#0ea5e9"/></marker></defs>
  <line x1="10" y1="20" x2="100" y2="20" stroke="#0ea5e9" stroke-width="4" marker-end="url(#a)"/>
  <line x1="10" y1="40" x2="100" y2="40" stroke="#0ea5e9" stroke-width="4" marker-end="url(#a)"/>
</svg>""",

    "circuit/effects/bulb_glow.svg": """<svg xmlns="http://www.w3.org/2000/svg" width="120" height="120" viewBox="0 0 120 120">
  <circle cx="60" cy="60" r="50" fill="none" stroke="#facc15" stroke-width="3" opacity="0.4"/>
  <circle cx="60" cy="60" r="40" fill="none" stroke="#facc15" stroke-width="3" opacity="0.6"/>
  <circle cx="60" cy="60" r="30" fill="#fef08a" opacity="0.9"/>
  <line x1="60" y1="10" x2="60" y2="-10" stroke="#facc15" stroke-width="3"/>
  <line x1="60" y1="110" x2="60" y2="130" stroke="#facc15" stroke-width="3"/>
  <line x1="10" y1="60" x2="-10" y2="60" stroke="#facc15" stroke-width="3"/>
  <line x1="110" y1="60" x2="130" y2="60" stroke="#facc15" stroke-width="3"/>
</svg>""",

    # Plant Growth
    "plant_growth/actors/watering_can.svg": """<svg xmlns="http://www.w3.org/2000/svg" width="120" height="100" viewBox="0 0 120 100">
  <path d="M30,40 L90,40 L90,80 Q90,90 80,90 L40,90 Q30,90 30,80 Z" fill="#64748b" stroke="#475569" stroke-width="2"/>
  <path d="M40,40 L50,20 L80,20 L85,40" fill="none" stroke="#475569" stroke-width="2"/>
  <line x1="90" y1="55" x2="110" y2="45" stroke="#94a3b8" stroke-width="4"/>
  <line x1="92" y1="60" x2="112" y2="50" stroke="#94a3b8" stroke-width="4"/>
</svg>""",

    "plant_growth/effects/water_droplets.svg": """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">
  <circle cx="30" cy="30" r="6" fill="#0ea5e9" opacity="0.8"/>
  <circle cx="60" cy="50" r="8" fill="#0ea5e9" opacity="0.8"/>
  <circle cx="40" cy="70" r="5" fill="#0ea5e9" opacity="0.8"/>
  <circle cx="70" cy="25" r="4" fill="#0ea5e9" opacity="0.8"/>
  <circle cx="20" cy="60" r="7" fill="#0ea5e9" opacity="0.8"/>
</svg>""",

    # Heart Rate
    "heart_rate/effects/pulse_ring.svg": """<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
  <circle cx="100" cy="100" r="80" fill="none" stroke="#ef4444" stroke-width="2" opacity="0.3"/>
  <circle cx="100" cy="100" r="60" fill="none" stroke="#ef4444" stroke-width="3" opacity="0.5"/>
  <circle cx="100" cy="100" r="40" fill="none" stroke="#ef4444" stroke-width="4" opacity="0.7"/>
  <circle cx="100" cy="100" r="20" fill="#fecaca" stroke="#ef4444" stroke-width="2"/>
</svg>""",

    # Matter
    "matter/actors/heater_plate.svg": """<svg xmlns="http://www.w3.org/2000/svg" width="160" height="100" viewBox="0 0 160 100">
  <rect x="10" y="30" width="140" height="40" rx="4" fill="#334155" stroke="#1e293b" stroke-width="2"/>
  <line x1="30" y1="40" x2="130" y2="40" stroke="#ef4444" stroke-width="3" opacity="0.8"/>
  <line x1="30" y1="50" x2="130" y2="50" stroke="#ef4444" stroke-width="3" opacity="0.8"/>
  <line x1="30" y1="60" x2="130" y2="60" stroke="#ef4444" stroke-width="3" opacity="0.8"/>
  <rect x="10" y="70" width="140" height="10" fill="#1e293b"/>
</svg>""",

    "matter/actors/thermometer.svg": """<svg xmlns="http://www.w3.org/2000/svg" width="60" height="160" viewBox="0 0 60 160">
  <rect x="18" y="10" width="24" height="110" rx="12" fill="#e2e8f0" stroke="#475569" stroke-width="2"/>
  <circle cx="30" cy="130" r="14" fill="#ef4444" stroke="#475569" stroke-width="2"/>
  <rect x="24" y="50" width="12" height="80" rx="6" fill="#ef4444"/>
  <line x1="30" y1="40" x2="40" y2="40" stroke="#475569" stroke-width="2"/>
  <line x1="30" y1="60" x2="40" y2="60" stroke="#475569" stroke-width="2"/>
  <line x1="30" y1="80" x2="40" y2="80" stroke="#475569" stroke-width="2"/>
</svg>""",

    "matter/effects/phase_transition.svg": """<svg xmlns="http://www.w3.org/2000/svg" width="240" height="100" viewBox="0 0 240 100">
  <rect x="10" y="50" width="40" height="40" fill="#94a3b8" stroke="#475569" stroke-width="2"/>
  <text x="30" y="40" text-anchor="middle" font-size="12" fill="#475569">Solid</text>
  <line x1="55" y1="70" x2="85" y2="70" stroke="#475569" stroke-width="2" marker-end="url(#a)"/>
  <rect x="90" y="30" width="40" height="40" fill="#38bdf8" stroke="#0ea5e9" stroke-width="2" opacity="0.6"/>
  <text x="110" y="20" text-anchor="middle" font-size="12" fill="#0ea5e9">Liquid</text>
  <line x1="140" y1="50" x2="165" y2="50" stroke="#475569" stroke-width="2" marker-end="url(#a)"/>
  <circle cx="185" cy="40" r="20" fill="none" stroke="#94a3b8" stroke-width="2" opacity="0.5"/>
  <text x="185" y="46" text-anchor="middle" font-size="12" fill="#475569">Gas</text>
  <defs><marker id="a" markerWidth="10" markerHeight="10" refX="5" refY="3" orient="auto" markerUnits="strokeWidth">
    <path d="M0,0 L0,6 L9,3 z" fill="#475569"/></marker></defs>
</svg>""",

    # Lens
    "lens/actors/screen.svg": """<svg xmlns="http://www.w3.org/2000/svg" width="200" height="140" viewBox="0 0 200 140">
  <rect x="10" y="10" width="180" height="120" fill="#f8fafc" stroke="#475569" stroke-width="3"/>
  <rect x="20" y="20" width="160" height="100" fill="#ffffff"/>
  <line x1="30" y1="70" x2="170" y2="70" stroke="#cbd5e1" stroke-width="1"/>
  <line x1="100" y1="30" x2="100" y2="110" stroke="#cbd5e1" stroke-width="1"/>
</svg>""",

    "lens/effects/light_beam.svg": """<svg xmlns="http://www.w3.org/2000/svg" width="200" height="60" viewBox="0 0 200 60">
  <line x1="0" y1="30" x2="190" y2="30" stroke="#facc15" stroke-width="4" opacity="0.8"/>
  <polygon points="190,30 180,25 180,35" fill="#facc15"/>
</svg>""",

    # Mirror
    "mirror/actors/curved_mirror.svg": """<svg xmlns="http://www.w3.org/2000/svg" width="120" height="160" viewBox="0 0 120 160">
  <path d="M60,10 Q10,80 60,150" fill="none" stroke="#94a3b8" stroke-width="6"/>
  <path d="M60,10 Q10,80 60,150" fill="none" stroke="#cbd5e1" stroke-width="2" opacity="0.5"/>
  <line x1="60" y1="10" x2="60" y2="150" stroke="#475569" stroke-width="2"/>
</svg>""",

    "mirror/effects/reflected_light_beam.svg": """<svg xmlns="http://www.w3.org/2000/svg" width="200" height="100" viewBox="0 0 200 100">
  <line x1="10" y1="70" x2="90" y2="30" stroke="#facc15" stroke-width="3"/>
  <polygon points="90,30 80,35 80,25" fill="#facc15"/>
  <line x1="90" y1="30" x2="190" y2="70" stroke="#facc15" stroke-width="3" opacity="0.7"/>
  <polygon points="190,70 180,65 180,75" fill="#facc15" opacity="0.7"/>
  <line x1="90" y1="10" x2="90" y2="90" stroke="#94a3b8" stroke-width="4"/>
</svg>""",

    # Water Cycle
    "water_cycle/background/lake.svg": """<svg xmlns="http://www.w3.org/2000/svg" width="300" height="100" viewBox="0 0 300 100">
  <path d="M0,60 Q50,40 100,60 T200,60 T300,60 L300,100 L0,100 Z" fill="#0ea5e9" opacity="0.7"/>
  <path d="M0,70 Q50,50 100,70 T200,70 T300,70" fill="none" stroke="#38bdf8" stroke-width="2" opacity="0.5"/>
</svg>""",

    "water_cycle/background/water_body.svg": """<svg xmlns="http://www.w3.org/2000/svg" width="300" height="120" viewBox="0 0 300 120">
  <path d="M0,80 Q60,60 120,80 T240,80 T300,80 L300,120 L0,120 Z" fill="#0ea5e9" opacity="0.8"/>
  <path d="M0,95 Q60,75 120,95 T240,95 T300,95" fill="none" stroke="#38bdf8" stroke-width="2" opacity="0.5"/>
</svg>""",

    "water_cycle/effects/evaporation.svg": """<svg xmlns="http://www.w3.org/2000/svg" width="100" height="120" viewBox="0 0 100 120">
  <path d="M20,80 Q30,60 20,40" fill="none" stroke="#94a3b8" stroke-width="3" opacity="0.6" stroke-linecap="round"/>
  <path d="M40,90 Q50,65 40,30" fill="none" stroke="#94a3b8" stroke-width="3" opacity="0.6" stroke-linecap="round"/>
  <path d="M60,85 Q70,60 60,35" fill="none" stroke="#94a3b8" stroke-width="3" opacity="0.6" stroke-linecap="round"/>
  <path d="M80,80 Q90,55 80,45" fill="none" stroke="#94a3b8" stroke-width="3" opacity="0.6" stroke-linecap="round"/>
</svg>""",

    "water_cycle/effects/ripple.svg": """<svg xmlns="http://www.w3.org/2000/svg" width="120" height="120" viewBox="0 0 120 120">
  <circle cx="60" cy="60" r="10" fill="none" stroke="#0ea5e9" stroke-width="2" opacity="0.8"/>
  <circle cx="60" cy="60" r="25" fill="none" stroke="#0ea5e9" stroke-width="2" opacity="0.6"/>
  <circle cx="60" cy="60" r="40" fill="none" stroke="#0ea5e9" stroke-width="2" opacity="0.4"/>
  <circle cx="60" cy="60" r="55" fill="none" stroke="#0ea5e9" stroke-width="2" opacity="0.2"/>
</svg>""",
}


def main():
    for rel_path, svg_content in SVGS.items():
        dest = BASE / rel_path
        dest.parent.mkdir(parents=True, exist_ok=True)
        with open(dest, "w", encoding="utf-8") as f:
            f.write(svg_content)
        print(f"  [GEN] {rel_path}")

    print(f"\nGenerated {len(SVGS)} placeholder SVGs.")


if __name__ == "__main__":
    main()
