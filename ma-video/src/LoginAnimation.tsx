import {AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig, Img, staticFile, Easing} from 'remotion';

const W = 390;
const H = 844;

// Easing helpers
const easeOut = Easing.out(Easing.cubic);
const easeInOut = Easing.inOut(Easing.cubic);
const spring = Easing.out(Easing.back(1.5));

export const LoginAnimation: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const f = (s: number) => s * fps; // seconds to frames

  // ── PHASE 1 (0–2s): Enter from left, side view, hip sway ──
  const walkX = interpolate(frame, [0, f(2.5)], [-180, 30], {
    extrapolateRight: 'clamp',
    easing: easeOut,
  });

  // Hip sway: oscillation laterale
  const hipSway = interpolate(
    Math.sin((frame / fps) * Math.PI * 3),
    [-1, 1], [-6, 6]
  );

  // Vertical bob (marche)
  const vertBob = interpolate(
    Math.abs(Math.sin((frame / fps) * Math.PI * 3)),
    [0, 1], [0, -8]
  );

  // ── PHASE 2 (2–4s): She drags the login card ──
  const cardX = interpolate(frame, [f(1.5), f(3.5)], [-W, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: easeOut,
  });

  const cardOpacity = interpolate(frame, [f(1.5), f(2)], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  // ── PHASE 3 (3.5–4.5s): Pivot to front view ──
  const pivotProgress = interpolate(frame, [f(3.5), f(4.5)], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: easeInOut,
  });

  // scaleX: side→front via scaleX flip (side=1, mid=0, front=1)
  const scaleXFlip = frame < f(4)
    ? interpolate(frame, [f(3.5), f(4)], [1, 0], {extrapolateLeft:'clamp', extrapolateRight:'clamp', easing: easeInOut})
    : interpolate(frame, [f(4), f(4.5)], [0, 1], {extrapolateLeft:'clamp', extrapolateRight:'clamp', easing: easeInOut});

  const showFront = frame >= f(4);

  // ── Joy wiggle after pivot ──
  const joyWiggle = frame > f(4.5) && frame < f(5.5)
    ? interpolate(Math.sin((frame - f(4.5)) / fps * Math.PI * 6), [-1, 1], [-8, 8])
    : 0;

  // ── PHASE 4 (5–7s): Jump ──
  const jumpY = (() => {
    if (frame < f(5) || frame > f(7)) return 0;
    // Two jumps
    const t = frame - f(5);
    const jumpDur = f(1);
    const jumpPhase = t % jumpDur;
    const arc = Math.sin((jumpPhase / jumpDur) * Math.PI);
    return -arc * 90;
  })();

  // ── PHASE 5 (7–9s): Spin 360° ──
  const spinDeg = interpolate(frame, [f(7), f(8.5)], [0, 360], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: easeInOut,
  });

  // ── PHASE 6 (9–10s): Final pose, lean on card ──
  const finalLean = interpolate(frame, [f(9), f(9.5)], [0, -10], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: spring,
  });

  // Combine girl X (stays at center after arrival)
  const girlX = frame < f(3.5) ? walkX : interpolate(frame, [f(3.5), f(4)], [30, 10], {extrapolateLeft:'clamp', extrapolateRight:'clamp'});

  // Girl Y (vertical position + bob + jump)
  const girlY = (frame < f(4.5) ? vertBob : 0) + jumpY;

  // Girl rotation (hip sway + joy wiggle + spin + final lean)
  const girlRot = frame < f(3.5)
    ? hipSway
    : frame < f(5)
    ? joyWiggle
    : frame < f(7)
    ? 0
    : frame < f(9)
    ? spinDeg
    : finalLean;

  return (
    <AbsoluteFill style={{
      background: 'linear-gradient(160deg, #1a1a3e 0%, #0d2137 50%, #0a1520 100%)',
      overflow: 'hidden',
      display: 'flex',
      alignItems: 'flex-end',
      justifyContent: 'center',
    }}>

      {/* Stars background */}
      {[...Array(18)].map((_, i) => (
        <div key={i} style={{
          position: 'absolute',
          width: 3 + (i % 3),
          height: 3 + (i % 3),
          borderRadius: '50%',
          background: '#fff',
          opacity: 0.3 + (i % 4) * 0.15,
          left: `${(i * 37 + 11) % 95}%`,
          top: `${(i * 53 + 7) % 45}%`,
          animation: 'none',
        }} />
      ))}

      {/* Login Card */}
      <div style={{
        position: 'absolute',
        bottom: 80,
        left: '50%',
        transform: `translateX(calc(-50% + ${cardX * 0.3}px))`,
        opacity: cardOpacity,
        width: 300,
        background: 'rgba(255,255,255,0.96)',
        borderRadius: 24,
        padding: '32px 24px',
        boxShadow: '0 24px 60px rgba(0,0,0,0.4)',
        zIndex: 1,
      }}>
        <div style={{textAlign:'center', marginBottom: 20}}>
          <div style={{width:52, height:52, borderRadius:'50%', background:'#243a6b', margin:'0 auto 12px', display:'flex', alignItems:'center', justifyContent:'center', fontSize:24}}>🏫</div>
          <div style={{fontSize:20, fontWeight:800, color:'#243a6b', fontFamily:'sans-serif'}}>SchoolSafe</div>
          <div style={{fontSize:12, color:'#888', marginTop:4, fontFamily:'sans-serif'}}>Connexion sécurisée</div>
        </div>
        <div style={{background:'#f5f5f5', borderRadius:12, padding:'12px 14px', marginBottom:12, fontFamily:'sans-serif', fontSize:13, color:'#999'}}>👤 Votre nom</div>
        <div style={{background:'#f5f5f5', borderRadius:12, padding:'12px 14px', marginBottom:20, fontFamily:'sans-serif', fontSize:13, color:'#999'}}>🔒 Code PIN</div>
        <div style={{background:'#243a6b', borderRadius:12, padding:'13px', textAlign:'center', fontFamily:'sans-serif', fontWeight:700, fontSize:14, color:'#fff'}}>Se connecter</div>
      </div>

      {/* Girl */}
      <div style={{
        position: 'absolute',
        bottom: 60,
        left: '50%',
        transform: `translateX(calc(-50% + ${girlX}px)) translateY(${girlY}px) rotate(${girlRot}deg)`,
        zIndex: 2,
        transformOrigin: 'bottom center',
      }}>
        <Img
          src={staticFile(showFront ? 'girl-front.png' : 'girl-side.png')}
          style={{
            height: 320,
            width: 'auto',
            display: 'block',
            transform: `scaleX(${frame < f(4.5) ? scaleXFlip * (showFront ? 1 : 1) : 1})`,
            transformOrigin: 'center',
          }}
        />
      </div>

      {/* Joy stars burst */}
      {frame > f(4.5) && frame < f(5.5) && [0,60,120,180,240,300].map((deg, i) => (
        <div key={i} style={{
          position: 'absolute',
          bottom: 380,
          left: '50%',
          width: 8,
          height: 8,
          borderRadius: '50%',
          background: ['#ffd700','#ff6b6b','#4ecdc4','#45b7d1','#96ceb4','#ffeaa7'][i],
          transform: `rotate(${deg}deg) translateY(${-interpolate(frame,[f(4.5),f(5.5)],[0,80],{extrapolateLeft:'clamp',extrapolateRight:'clamp'})}px)`,
          opacity: interpolate(frame,[f(4.5),f(5.5)],[1,0],{extrapolateLeft:'clamp',extrapolateRight:'clamp'}),
        }} />
      ))}

      {/* School Safe watermark */}
      <div style={{
        position: 'absolute',
        top: 40,
        width: '100%',
        textAlign: 'center',
        fontFamily: 'sans-serif',
        fontSize: 13,
        color: 'rgba(255,255,255,0.35)',
        letterSpacing: 2,
        textTransform: 'uppercase',
      }}>
        SchoolSafe v3.0
      </div>
    </AbsoluteFill>
  );
};
