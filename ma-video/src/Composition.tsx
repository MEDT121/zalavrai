import {AbsoluteFill} from 'remotion';

export const MyComposition: React.FC = () => {
  return (
    <AbsoluteFill style={{backgroundColor: '#1a1a2e', display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
      <h1 style={{color: '#fff', fontSize: 80, fontFamily: 'sans-serif'}}>Hello!</h1>
    </AbsoluteFill>
  );
};
