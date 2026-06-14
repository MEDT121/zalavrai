import React from 'react';
import {
  AbsoluteFill,
  interpolate,
  useCurrentFrame,
  useVideoConfig,
  Easing,
  Sequence,
} from 'remotion';

// ── PALETTE ──
const SKIN   = '#C68642';
const HAIR   = '#1a0a00';
const SHIRT  = '#4a90d9';
const SKIRT  = '#1e3a6e';
const SHOE   = '#22c55e'; // chaussures vertes
const SOCK   = '#ffffff';
const CARD_W = 210;
const CARD_H = 270;

const f = (s: number) => Math.round(s * 30);

// ──────────────────────────────────────────────
// BACKGROUND
// ──────────────────────────────────────────────
const Background: React.FC = () => {
  const frame = useCurrentFrame();
  const hue = interpolate(frame, [0, 300], [230, 260], { extrapolateRight: 'clamp' });
  return (
    <AbsoluteFill style={{
      background: `linear-gradient(170deg, hsl(${hue},55%,12%) 0%, hsl(${hue+25},45%,7%) 100%)`,
    }}>
      {Array.from({ length: 28 }, (_, i) => {
        const t = interpolate(Math.sin(frame * 0.04 + i * 0.9), [-1, 1], [0.15, 0.75]);
        return (
          <div key={i} style={{
            position: 'absolute',
            width: 1 + (i % 3),
            height: 1 + (i % 3),
            borderRadius: '50%',
            background: '#fff',
            opacity: t,
            left: `${(i * 43 + 7) % 94}%`,
            top:  `${(i * 67 + 11) % 44}%`,
          }} />
        );
      })}
    </AbsoluteFill>
  );
};

// ──────────────────────────────────────────────
// CARTE DE CONNEXION
// ──────────────────────────────────────────────
const LoginCard: React.FC<{
  x: number; y: number; rot: number; opacity: number;
}> = ({ x, y, rot, opacity }) => (
  <div style={{
    position: 'absolute',
    left: x,
    top: y,
    width: CARD_W,
    transform: `rotate(${rot}deg)`,
    opacity,
    background: 'rgba(255,255,255,0.97)',
    borderRadius: 20,
    padding: '22px 16px',
    boxShadow: '0 20px 60px rgba(0,0,0,0.45)',
    zIndex: 2,
  }}>
    <div style={{ textAlign: 'center', marginBottom: 14 }}>
      <div style={{
        width: 44, height: 44, borderRadius: '50%',
        background: '#243a6b', margin: '0 auto 8px',
        display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18,
      }}>🏫</div>
      <div style={{ fontSize: 16, fontWeight: 800, color: '#243a6b', fontFamily: 'sans-serif' }}>SchoolSafe</div>
      <div style={{ fontSize: 10, color: '#999', marginTop: 2, fontFamily: 'sans-serif' }}>Connexion sécurisée</div>
    </div>
    <div style={{ background: '#f4f4f4', borderRadius: 9, padding: '9px 11px', marginBottom: 8, fontFamily: 'sans-serif', fontSize: 11, color: '#bbb' }}>👤 Votre nom</div>
    <div style={{ background: '#f4f4f4', borderRadius: 9, padding: '9px 11px', marginBottom: 13, fontFamily: 'sans-serif', fontSize: 11, color: '#bbb' }}>🔒 Code PIN</div>
    <div style={{ background: '#243a6b', borderRadius: 9, padding: '10px', textAlign: 'center', fontFamily: 'sans-serif', fontWeight: 700, fontSize: 12, color: '#fff' }}>
      Se connecter →
    </div>
  </div>
);

// ──────────────────────────────────────────────
// CORDE (lien main droite → carte)
// ──────────────────────────────────────────────
const Rope: React.FC<{
  fromX: number; fromY: number; toX: number; toY: number; opacity: number;
}> = ({ fromX, fromY, toX, toY, opacity }) => {
  const cx = (fromX + toX) / 2;
  const cy = Math.max(fromY, toY) + 30;
  return (
    <svg style={{ position: 'absolute', inset: 0, pointerEvents: 'none', zIndex: 3 }}
         width="390" height="844">
      <path
        d={`M${fromX},${fromY} Q${cx},${cy} ${toX},${toY}`}
        stroke="#d4a017"
        strokeWidth="3"
        strokeDasharray="6 4"
        fill="none"
        opacity={opacity}
        strokeLinecap="round"
      />
    </svg>
  );
};

// ──────────────────────────────────────────────
// PERSONNAGE — SVG dessiné en code
// ──────────────────────────────────────────────
const Girl: React.FC<{
  legL: number; legR: number;
  armL: number; armR: number;
  hipX: number; bob: number;
  lean: number; headTilt: number;
  smileSize: number; showJoy: boolean;
  pigtailB: number; showWatch: boolean;
}> = ({ legL, legR, armL, armR, hipX, bob, lean, headTilt, smileSize, showJoy, pigtailB, showWatch }) => (
  <svg width="90" height="370" viewBox="0 0 90 370">
    {/* ── Ombre ── */}
    <ellipse cx="45" cy="365" rx={32 * (1 - Math.abs(bob) / 90)} ry="5" fill="rgba(0,0,0,0.28)" />

    {/* ── JAMBE DROITE (derrière) ── */}
    <g transform={`rotate(${legR}, 52, 210)`}>
      <rect x="46" y="210" width="13" height="65" rx="4" fill={SKIRT} />
      <rect x="46" y="275" width="13" height="13" rx="2" fill={SOCK} />
      <rect x="43" y="288" width="19" height="11" rx="5" fill={SHOE} />
    </g>

    {/* ── JAMBE GAUCHE (devant) ── */}
    <g transform={`rotate(${legL}, 38, 210)`}>
      <rect x="31" y="210" width="13" height="65" rx="4" fill={SKIRT} />
      <rect x="31" y="275" width="13" height="13" rx="2" fill={SOCK} />
      <rect x="28" y="288" width="19" height="11" rx="5" fill={SHOE} />
    </g>

    {/* ── JUPE ── */}
    <g transform={`translate(${hipX}, 0)`}>
      <polygon points="12,205 78,205 84,278 6,278" fill={SKIRT} />
    </g>

    {/* ── BRAS DROIT (derrière le corps) ── */}
    <g transform={`rotate(${armR}, 72, 130)`}>
      <rect x="67" y="130" width="12" height="48" rx="6" fill={SHIRT} />
      <circle cx="73" cy="181" r="7" fill={SKIN} />
    </g>

    {/* ── CORPS / CHEMISE ── */}
    <rect x="22" y="122" width="46" height="85" rx="9" fill={SHIRT} />

    {/* ── BRAS GAUCHE (devant) ── */}
    <g transform={`rotate(${armL}, 18, 130)`}>
      <rect x="11" y="130" width="12" height="48" rx="6" fill={SHIRT} />
      <circle cx="17" cy="181" r="7" fill={SKIN} />
      {showWatch && (
        <rect x="9" y="168" width="16" height="9" rx="3" fill="#d4a017" />
      )}
    </g>

    {/* ── COU ── */}
    <rect x="35" y="106" width="20" height="17" rx="4" fill={SKIN} />

    {/* ── TÊTE + CHEVEUX ── */}
    <g transform={`rotate(${headTilt}, 45, 120)`}>
      {/* Cheveux arrière */}
      <ellipse cx="45" cy="62" rx="28" ry="32" fill={HAIR} />

      {/* Natte gauche */}
      <g transform={`rotate(${-18 + pigtailB * 9}, 16, 52)`}>
        <rect x="9" y="52" width="13" height="42" rx="6" fill={HAIR} />
        <circle cx="15" cy="95" r="6" fill={HAIR} />
      </g>

      {/* Natte droite */}
      <g transform={`rotate(${18 - pigtailB * 9}, 74, 52)`}>
        <rect x="68" y="52" width="13" height="42" rx="6" fill={HAIR} />
        <circle cx="75" cy="95" r="6" fill={HAIR} />
      </g>

      {/* Visage */}
      <ellipse cx="45" cy="68" rx="25" ry="28" fill={SKIN} />

      {/* Cheveux avant */}
      <ellipse cx="45" cy="40" rx="25" ry="17" fill={HAIR} />

      {/* Rubans */}
      <circle cx="17" cy="48" r="5" fill="#4a90d9" />
      <circle cx="73" cy="48" r="5" fill="#4a90d9" />

      {/* Sourcils */}
      <path d="M28,57 Q33,54 38,57" stroke={HAIR} strokeWidth="2" fill="none" strokeLinecap="round" />
      <path d="M52,57 Q57,54 62,57" stroke={HAIR} strokeWidth="2" fill="none" strokeLinecap="round" />

      {/* Yeux */}
      <ellipse cx="34" cy="67" rx="5.5" ry="6.5" fill="#1a1a1a" />
      <ellipse cx="56" cy="67" rx="5.5" ry="6.5" fill="#1a1a1a" />
      <circle cx="36" cy="64" r="2" fill="#fff" />
      <circle cx="58" cy="64" r="2" fill="#fff" />

      {/* Sourire */}
      <path
        d={`M31,${82 - smileSize} Q45,${82 + smileSize * 9} 59,${82 - smileSize}`}
        stroke="#8B2500"
        strokeWidth="2.5"
        fill={smileSize > 0.3 ? 'rgba(139,37,0,0.12)' : 'none'}
        strokeLinecap="round"
      />
      {smileSize > 0.6 && (
        <rect x="36" y="82" width="18" height="5" rx="2" fill="#fff" opacity={(smileSize - 0.6) * 2.5} />
      )}

      {/* Joues joie */}
      {showJoy && (
        <>
          <ellipse cx="27" cy="76" rx="8" ry="5.5" fill="rgba(255,110,70,0.38)" />
          <ellipse cx="63" cy="76" rx="8" ry="5.5" fill="rgba(255,110,70,0.38)" />
        </>
      )}
    </g>
  </svg>
);

// ──────────────────────────────────────────────
// ÉTINCELLES JOIE
// ──────────────────────────────────────────────
const Sparkles: React.FC = () => {
  const frame = useCurrentFrame();
  const items = ['⭐','✨','💫','🌟','🎉','💛','⚡','🎊'];
  return (
    <>
      {items.map((s, i) => {
        const angle = (i / items.length) * Math.PI * 2;
        const dist  = interpolate(frame, [0, 22], [0, 85], { extrapolateRight: 'clamp', easing: Easing.out(Easing.cubic) });
        const op    = interpolate(frame, [0, 5, 20, 32], [0, 1, 1, 0], { extrapolateRight: 'clamp' });
        return (
          <div key={i} style={{
            position: 'absolute', bottom: 370, left: '50%',
            transform: `translate(calc(-50% + ${Math.cos(angle) * dist}px), ${Math.sin(angle) * dist}px)`,
            opacity: op, fontSize: 20,
          }}>{s}</div>
        );
      })}
    </>
  );
};

// ──────────────────────────────────────────────
// COMPOSITION PRINCIPALE
// ──────────────────────────────────────────────
export const SchoolSafeLogin: React.FC = () => {
  const frame = useCurrentFrame();
  const W = 390;
  const H = 844;
  const GROUND = H - 70; // ligne du sol

  // ── Cycles ──
  const walkSpeed  = 0.30;
  const walkCycle  = frame * walkSpeed;
  const isWalking  = frame < f(3.2);
  const isJumping  = frame >= f(3.8) && frame < f(4.8);
  const isLean     = frame >= f(5);
  const isWatch    = frame >= f(6.5);

  // ── Position X fille ──
  const girlX = interpolate(frame,
    [0,         f(3.2)],
    [-100,       95],
    { extrapolateRight: 'clamp', easing: Easing.bezier(0.25, 0.1, 0.25, 1) }
  );

  // ── Oscillations marche ──
  const legSwing  = isWalking ? Math.sin(walkCycle) * 28 : 0;
  const legL      = legSwing;
  const legR      = -legSwing;
  const armSwing  = isWalking ? Math.sin(walkCycle) * 20 : 0;

  // Bras gauche : balance pendant marche, monte pour montre
  const armL = isWalking
    ? armSwing
    : isWatch
    ? interpolate(frame, [f(6.5), f(7)], [0, -78], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: Easing.out(Easing.cubic) })
    : 0;

  // Bras droit : tire la carte en marchant, s'appuie après
  const armR = isWalking
    ? -armSwing + 25    // tendu en arrière (tire la corde)
    : isLean
    ? interpolate(frame, [f(5), f(5.5)], [0, -35], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: Easing.out(Easing.back(1.2)) })
    : 0;

  const hipX       = isWalking ? Math.sin(walkCycle) * 5 : 0;
  const bob        = isWalking ? Math.abs(Math.sin(walkCycle * 2)) * -9 : 0;
  const pigtailB   = Math.sin(walkCycle * 1.4);

  // ── Inclinaison (lean) ──
  const lean = isLean
    ? interpolate(frame, [f(5), f(5.6)], [0, 14], {
        extrapolateLeft: 'clamp', extrapolateRight: 'clamp',
        easing: Easing.out(Easing.back(1.3)),
      })
    : 0;

  // ── Tête ──
  const headTilt = isWatch
    ? interpolate(frame, [f(6.5), f(7)], [lean, lean + 22], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' })
    : lean;

  // ── Sourire ──
  const smileSize = interpolate(frame, [f(3.5), f(4.5)], [0, 1], {
    extrapolateLeft: 'clamp', extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

  const showJoy = frame > f(3.8);

  // ── Saut ──
  const jumpY = isJumping
    ? -Math.sin(((frame - f(3.8)) / (f(4.8) - f(3.8))) * Math.PI) * 75
    : 0;

  // ── Respiration (idle) ──
  const breathe = frame > f(7.5) ? Math.sin((frame - f(7.5)) / 20) * 2.5 : 0;

  // ── Carte : suit la fille avec lag, puis rebondit au centre ──
  const CARD_FINAL_X = (W - CARD_W) / 2;  // centre horizontal
  const CARD_FINAL_Y = (H - CARD_H) / 2 - 10;

  const cardX = frame < f(3.2)
    ? interpolate(frame, [0, f(3.2)], [-230, girlX + 55], {
        extrapolateRight: 'clamp',
        easing: Easing.bezier(0.25, 0.1, 0.25, 1),
      })
    : interpolate(frame, [f(3.2), f(4)], [girlX + 55, CARD_FINAL_X], {
        extrapolateLeft: 'clamp', extrapolateRight: 'clamp',
        easing: Easing.out(Easing.back(1.6)),
      });

  const cardY = frame < f(3.2)
    ? CARD_FINAL_Y + 40
    : interpolate(frame, [f(3.2), f(4)], [CARD_FINAL_Y + 40, CARD_FINAL_Y], {
        extrapolateLeft: 'clamp', extrapolateRight: 'clamp',
        easing: Easing.out(Easing.back(1.4)),
      });

  const cardRot = frame < f(3.2)
    ? interpolate(frame, [0, f(3.2)], [-7, -2], { extrapolateRight: 'clamp' })
    : interpolate(frame, [f(3.2), f(4)], [-2, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  const cardOpacity = interpolate(frame, [0, f(0.4)], [0, 1], { extrapolateRight: 'clamp' });

  // ── Corde : de la main droite → coin gauche de la carte ──
  // Main droite en composition: girlX + 80 (right arm extended back)
  const ropeVisible = frame < f(3.5);
  const handX = girlX + 82;
  const handY = GROUND - 175 + bob;
  const ropeToX = cardX + 10;
  const ropeToY = cardY + CARD_H / 2;
  const ropeOpacity = interpolate(frame, [0, f(0.3), f(3.2), f(3.5)], [0, 0.85, 0.85, 0], {
    extrapolateLeft: 'clamp', extrapolateRight: 'clamp',
  });

  // ── Position Y fille dans la composition ──
  const girlTop = GROUND - 370 + jumpY + bob + breathe;

  return (
    <AbsoluteFill>
      {/* Fond */}
      <Sequence><Background /></Sequence>

      {/* Carte */}
      <LoginCard x={cardX} y={cardY} rot={cardRot} opacity={cardOpacity} />

      {/* Corde fille → carte */}
      {ropeVisible && (
        <Rope fromX={handX} fromY={handY} toX={ropeToX} toY={ropeToY} opacity={ropeOpacity} />
      )}

      {/* Fille */}
      <div style={{
        position: 'absolute',
        left: girlX,
        top: girlTop,
        transform: `rotate(${lean}deg)`,
        transformOrigin: 'bottom center',
        zIndex: 4,
      }}>
        <Girl
          legL={legL} legR={legR}
          armL={armL} armR={armR}
          hipX={hipX} bob={bob}
          lean={0} headTilt={headTilt}
          smileSize={smileSize}
          showJoy={showJoy}
          pigtailB={pigtailB}
          showWatch={isWatch}
        />
      </div>

      {/* Étincelles joie */}
      <Sequence from={f(3.9)} durationInFrames={f(1.5)}>
        <Sparkles />
      </Sequence>
    </AbsoluteFill>
  );
};
