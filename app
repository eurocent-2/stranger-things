import React, { useState, useEffect, useRef } from 'react';
import { initializeApp } from 'firebase/app';
import { 
  getAuth, 
  signInAnonymously, 
  signInWithCustomToken, 
  onAuthStateChanged,
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signInWithPopup,
  GoogleAuthProvider,
  signOut
} from 'firebase/auth';
import { 
  getFirestore, 
  doc, 
  setDoc, 
  onSnapshot, 
  updateDoc, 
  arrayUnion,
  getDoc
} from 'firebase/firestore';
import { 
  Ghost, 
  Loader2, 
  CheckCircle2, 
  Flame,
  Camera,
  X,
  Sparkles,
  Search,
  Skull,
  Star,
  Zap,
  Moon,
  ScanFace,
  LogOut,
  Mail,
  Lock,
  UserPlus,
  LogIn,
  Share2,
  BarChart3,
  Volume2,
  VolumeX
} from 'lucide-react';

// --- Firebase & API Constants ---
const apiKey = ""; 
const firebaseConfig = JSON.parse(__firebase_config);
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const googleProvider = new GoogleAuthProvider();
const appId = typeof __app_id !== 'undefined' ? __app_id : 'kinder-stranger-things-v4';

// --- Comprehensive VC Character Data ---
const STRANGER_THINGS_TOYS = [
  { id: 'VC259', name: 'Will Byers', group: 'Normal' },
  { id: 'VC261', name: 'Dustin Henderson', group: 'Normal' },
  { id: 'VC263', name: 'Jim Hopper', group: 'Normal' },
  { id: 'VC265', name: 'Max Mayfield', group: 'Normal' },
  { id: 'VC267', name: 'Steve Harrington', group: 'Normal' },
  { id: 'VC269', name: 'Eleven', group: 'Normal' },
  { id: 'VC271', name: 'Demogorgon', group: 'Normal' },
  { id: 'VC273', name: 'Lucas Sinclair', group: 'Normal' },
  { id: 'VC274', name: 'Mike Wheeler', group: 'Normal' },
  { id: 'VC275', name: 'Demogorgon', group: 'Normal' },
  { id: 'VC276', name: 'Eleven', group: 'Normal' },
  { id: 'VC277', name: 'Vecna', group: 'Normal' },
  { id: 'VC283', name: 'Nancy Wheeler', group: 'Normal' },
  { id: 'VC285', name: 'Erica Sinclair', group: 'Normal' },
  { id: 'VC286', name: 'Steve Harrington', group: 'Normal' },
  { id: 'VC287', name: 'Demogorgon', group: 'Normal' },
  { id: 'VC356', name: 'Eleven', group: 'Normal' },
  { id: 'VC260', name: 'Will Byers UD', group: 'UD' },
  { id: 'VC262', name: 'Dustin Henderson UD', group: 'UD' },
  { id: 'VC264', name: 'Jim Hopper UD', group: 'UD' },
  { id: 'VC266', name: 'Max Mayfield UD', group: 'UD' },
  { id: 'VC268', name: 'Steve Harrington UD', group: 'UD' },
  { id: 'VC284', name: 'Eddie Munson UD', group: 'UD' },
  { id: 'VC288', name: 'Robin Buckley UD', group: 'UD' },
];

export default function App() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [authMode, setAuthMode] = useState('login'); // 'login' or 'signup'
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  
  const [collectionData, setCollectionData] = useState([]);
  const [isScanning, setIsScanning] = useState(false);
  const [scanMode, setScanMode] = useState('code');
  const [analyzing, setAnalyzing] = useState(false);
  const [message, setMessage] = useState({ text: '', type: '' });
  const [showStats, setShowStats] = useState(false);
  const [soundEnabled, setSoundEnabled] = useState(true);
  
  const fileInputRef = useRef(null);

  // Audio effects
  const playSound = (type) => {
    if (!soundEnabled) return;
    const synth = window.speechSynthesis;
    
    if (type === 'success') {
      const utterance = new SpeechSynthesisUtterance("Subject identified.");
      utterance.pitch = 0.5;
      utterance.rate = 0.8;
      synth.speak(utterance);
    } else if (type === 'error') {
      const utterance = new SpeechSynthesisUtterance("Signal lost.");
      utterance.pitch = 0.1;
      synth.speak(utterance);
    }
  };

  useEffect(() => {
    const initAuth = async () => {
      try {
        if (typeof __initial_auth_token !== 'undefined' && __initial_auth_token) {
          await signInWithCustomToken(auth, __initial_auth_token);
        }
      } catch (error) { console.error("Auth error:", error); }
    };
    initAuth();
    const unsubscribe = onAuthStateChanged(auth, (u) => {
      setUser(u);
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  useEffect(() => {
    if (!user) return;
    const userDocRef = doc(db, 'artifacts', appId, 'users', user.uid, 'settings', 'collection');
    const unsubscribe = onSnapshot(userDocRef, (snapshot) => {
      if (snapshot.exists()) {
        setCollectionData(snapshot.data().ownedIds || []);
      } else {
        setDoc(userDocRef, { ownedIds: [] });
      }
    }, (error) => console.error("Firestore error:", error));
    return () => unsubscribe();
  }, [user]);

  const handleAuth = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      if (authMode === 'signup') {
        await createUserWithEmailAndPassword(auth, email, password);
        showToast("Welcome to Hawkins Lab", "success");
      } else {
        await signInWithEmailAndPassword(auth, email, password);
        showToast("Signal re-established", "success");
      }
    } catch (err) {
      showToast(err.message.replace('Firebase:', ''), "error");
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleSignIn = async () => {
    setLoading(true);
    try {
      await signInWithPopup(auth, googleProvider);
      showToast("Access granted via Google", "success");
    } catch (err) {
      showToast("Google Authentication Failed", "error");
    } finally {
      setLoading(false);
    }
  };

  const analyzeImage = async (base64Image) => {
    setAnalyzing(true);
    const cleanBase64 = base64Image.split(',')[1];
    
    let systemPrompt = "";
    if (scanMode === 'code') {
      systemPrompt = `Identify the Kinder Joy Stranger Things code. Look for VC###. Return ONLY the code. If not found, return 'UNKNOWN'.`;
    } else {
      systemPrompt = `Identify this Stranger Things toy. List: ${STRANGER_THINGS_TOYS.map(t => `${t.name} (${t.id})`).join(', ')}. Return ONLY the VC code. If not sure, return 'UNKNOWN'.`;
    }

    try {
      const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent?key=${apiKey}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{
            role: "user",
            parts: [
              { text: scanMode === 'code' ? "Code extract:" : "Toy identify:" },
              { inlineData: { mimeType: "image/png", data: cleanBase64 } }
            ]
          }],
          systemInstruction: { parts: [{ text: systemPrompt }] }
        })
      });

      const result = await response.json();
      const detectedCode = result.candidates?.[0]?.content?.parts?.[0]?.text?.trim().toUpperCase();
      const toy = STRANGER_THINGS_TOYS.find(t => detectedCode?.includes(t.id));

      if (toy) {
        await addToCollection(toy);
      } else {
        playSound('error');
        showToast("Unknown Entity Detected", "error");
      }
    } catch (err) {
      showToast("Portal Interference", "error");
    } finally {
      setAnalyzing(false);
      setIsScanning(false);
    }
  };

  const addToCollection = async (toy) => {
    if (collectionData.includes(toy.id)) {
      showToast(`${toy.name} already secured.`, "info");
      return;
    }
    try {
      const userDocRef = doc(db, 'artifacts', appId, 'users', user.uid, 'settings', 'collection');
      await updateDoc(userDocRef, { ownedIds: arrayUnion(toy.id) });
      playSound('success');
      showToast(`Subject: ${toy.name} Captured`, "success");
    } catch (error) {
      showToast("Database error.", "error");
    }
  };

  const copyShareLink = () => {
    const text = `I've collected ${collectionData.length}/${STRANGER_THINGS_TOYS.length} Stranger Things Kinder toys! Currently missing: ${STRANGER_THINGS_TOYS.length - collectionData.length} characters.`;
    const tempInput = document.createElement("input");
    tempInput.value = text;
    document.body.appendChild(tempInput);
    tempInput.select();
    document.execCommand("copy");
    document.body.removeChild(tempInput);
    showToast("Progress copied to clipboard!", "success");
  };

  const showToast = (text, type) => {
    setMessage({ text, type });
    setTimeout(() => setMessage({ text: '', type: '' }), 3000);
  };

  if (loading) return (
    <div className="min-h-screen bg-black flex items-center justify-center">
      <Loader2 className="w-12 h-12 text-red-600 animate-spin" />
    </div>
  );

  if (!user) return (
    <div className="min-h-screen bg-black flex items-center justify-center p-6 bg-[radial-gradient(circle_at_center,_#220000_0%,_#000000_100%)]">
      <div className="w-full max-w-md space-y-8 bg-slate-900/50 p-10 rounded-[2.5rem] border border-red-900/30 backdrop-blur-xl shadow-2xl">
        <div className="text-center space-y-4">
          <Flame className="w-16 h-16 text-red-600 mx-auto animate-pulse" />
          <h1 className="text-4xl font-black italic uppercase tracking-tighter text-white">Hawkins <span className="text-red-600">Lab</span></h1>
          <p className="text-xs font-bold text-slate-500 uppercase tracking-widest">Authorized Personnel Only</p>
        </div>

        <div className="space-y-4">
          <button 
            onClick={handleGoogleSignIn}
            className="w-full bg-white text-black font-black uppercase italic py-4 rounded-2xl flex items-center justify-center gap-3 transition-all active:scale-95 shadow-lg"
          >
            <svg className="w-5 h-5" viewBox="0 0 24 24">
              <path fill="currentColor" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
              <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
              <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" />
              <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
            </svg>
            Continue with Google
          </button>

          <div className="flex items-center gap-4 py-2">
            <div className="flex-1 h-px bg-white/10" />
            <span className="text-[10px] font-bold text-slate-500 uppercase">OR</span>
            <div className="flex-1 h-px bg-white/10" />
          </div>

          <form onSubmit={handleAuth} className="space-y-4">
            <div className="relative">
              <Mail className="absolute left-4 top-4 w-5 h-5 text-slate-500" />
              <input 
                type="email" 
                placeholder="Lab Email"
                className="w-full bg-black/40 border border-white/10 rounded-2xl py-4 pl-12 pr-4 text-white focus:border-red-600 focus:outline-none transition-all"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>
            <div className="relative">
              <Lock className="absolute left-4 top-4 w-5 h-5 text-slate-500" />
              <input 
                type="password" 
                placeholder="Access Key"
                className="w-full bg-black/40 border border-white/10 rounded-2xl py-4 pl-12 pr-4 text-white focus:border-red-600 focus:outline-none transition-all"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>
            <button className="w-full bg-red-600 hover:bg-red-700 text-white font-black uppercase italic py-4 rounded-2xl flex items-center justify-center gap-3 transition-all active:scale-95 shadow-lg shadow-red-900/20">
              {authMode === 'login' ? <LogIn className="w-5 h-5" /> : <UserPlus className="w-5 h-5" />}
              {authMode === 'login' ? 'Login' : 'Create Account'}
            </button>
          </form>
        </div>

        <button 
          onClick={() => setAuthMode(authMode === 'login' ? 'signup' : 'login')}
          className="w-full text-slate-500 text-xs font-bold uppercase hover:text-white transition-colors"
        >
          {authMode === 'login' ? "Need a lab account? Sign Up" : "Already registered? Login"}
        </button>
      </div>
    </div>
  );

  const stats = {
    normal: collectionData.filter(id => STRANGER_THINGS_TOYS.find(t => t.id === id)?.group === 'Normal').length,
    ud: collectionData.filter(id => STRANGER_THINGS_TOYS.find(t => t.id === id)?.group === 'UD').length,
    total: collectionData.length,
    percent: Math.round((collectionData.length / STRANGER_THINGS_TOYS.length) * 100)
  };

  return (
    <div className="min-h-screen bg-black text-slate-100 font-sans pb-24 selection:bg-red-600/30">
      {/* Header */}
      <nav className="border-b border-white/10 bg-black/80 backdrop-blur-xl sticky top-0 z-50 px-6 py-4 flex justify-between items-center">
        <div className="flex items-center gap-3">
          <Flame className="w-6 h-6 text-red-600 fill-red-600" />
          <h1 className="text-xl font-black tracking-tighter uppercase italic">ST <span className="text-red-600 underline underline-offset-4">Tracker</span></h1>
        </div>
        <div className="flex items-center gap-2">
          <button 
            onClick={() => setSoundEnabled(!soundEnabled)}
            className="p-2 rounded-full bg-white/5 border border-white/10 text-slate-400 hover:text-white"
          >
            {soundEnabled ? <Volume2 className="w-4 h-4" /> : <VolumeX className="w-4 h-4" />}
          </button>
          <button 
            onClick={() => signOut(auth)}
            className="p-2 rounded-full bg-white/5 border border-white/10 text-slate-400 hover:text-white"
          >
            <LogOut className="w-4 h-4" />
          </button>
          <div className="bg-red-600 px-4 py-1.5 rounded-full flex items-center gap-2 shadow-lg shadow-red-900/20">
            <span className="text-xs font-black italic">{stats.percent}%</span>
          </div>
        </div>
      </nav>

      <main className="max-w-4xl mx-auto p-6 space-y-12">
        {/* Quick Stats & Actions */}
        <section className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="bg-slate-900/50 p-6 rounded-3xl border border-white/5 flex items-center justify-between">
            <div className="flex items-center gap-4">
              <BarChart3 className="w-8 h-8 text-red-500" />
              <div>
                <p className="text-[10px] font-black uppercase text-slate-500 tracking-widest">Progress</p>
                <p className="text-xl font-black italic">{collectionData.length} / {STRANGER_THINGS_TOYS.length}</p>
              </div>
            </div>
            <button onClick={() => setShowStats(!showStats)} className="text-[10px] font-black uppercase text-red-500 underline underline-offset-4">View Detail</button>
          </div>
          <button 
            onClick={copyShareLink}
            className="bg-white/5 p-6 rounded-3xl border border-white/5 flex items-center gap-4 hover:bg-white/10 transition-all text-left"
          >
            <Share2 className="w-8 h-8 text-blue-500" />
            <div>
              <p className="text-[10px] font-black uppercase text-slate-500 tracking-widest">Share</p>
              <p className="text-xl font-black italic">Copy Progress Link</p>
            </div>
          </button>
        </section>

        {showStats && (
          <div className="bg-slate-900/80 p-8 rounded-[2rem] border-2 border-red-900/20 animate-in slide-in-from-top-4">
            <h3 className="text-2xl font-black italic uppercase mb-6 flex items-center gap-3">
              <BarChart3 className="w-6 h-6 text-red-600" /> Collection Analytics
            </h3>
            <div className="grid grid-cols-2 gap-6">
              <div className="space-y-2">
                <p className="text-xs font-bold text-slate-500 uppercase">Normal World</p>
                <div className="h-4 bg-white/5 rounded-full overflow-hidden">
                  <div className="h-full bg-yellow-500" style={{ width: `${(stats.normal / 17) * 100}%` }} />
                </div>
                <p className="text-right text-xs font-black italic">{stats.normal} / 17</p>
              </div>
              <div className="space-y-2">
                <p className="text-xs font-bold text-slate-500 uppercase">Upside Down</p>
                <div className="h-4 bg-white/5 rounded-full overflow-hidden">
                  <div className="h-full bg-blue-600" style={{ width: `${(stats.ud / 7) * 100}%` }} />
                </div>
                <p className="text-right text-xs font-black italic">{stats.ud} / 7</p>
              </div>
            </div>
          </div>
        )}

        {/* Scanner */}
        <section className="flex flex-col items-center py-4">
          {!isScanning ? (
            <div className="flex gap-4 w-full">
              <button 
                onClick={() => { setScanMode('code'); setIsScanning(true); }}
                className="flex-1 bg-red-600 p-8 rounded-[2rem] font-black uppercase italic text-lg flex flex-col items-center gap-3 shadow-2xl transition-all hover:scale-105"
              >
                <Camera className="w-8 h-8" /> Scan Code
              </button>
              <button 
                onClick={() => { setScanMode('visual'); setIsScanning(true); }}
                className="flex-1 bg-slate-900 p-8 rounded-[2rem] font-black uppercase italic text-lg flex flex-col items-center gap-3 shadow-xl transition-all hover:scale-105 border border-white/5"
              >
                <ScanFace className="w-8 h-8 text-red-500" /> Visual ID
              </button>
            </div>
          ) : (
            <div className="w-full max-w-md bg-slate-900 border-2 border-white/10 p-10 rounded-[3rem] text-center relative overflow-hidden shadow-2xl">
              {analyzing ? (
                <div className="py-14 space-y-6">
                  <Loader2 className="w-16 h-16 text-red-600 animate-spin mx-auto" />
                  <h3 className="text-xl font-black italic text-red-500 uppercase tracking-tighter">Analyzing Subject...</h3>
                </div>
              ) : (
                <>
                  <button onClick={() => setIsScanning(false)} className="absolute top-6 right-6 text-slate-500">
                    <X className="w-6 h-6" />
                  </button>
                  <Camera className="w-12 h-12 text-white mx-auto mb-4" />
                  <h3 className="text-2xl font-black italic uppercase mb-2">{scanMode === 'code' ? 'Code Decoder' : 'Toy Vision'}</h3>
                  <input 
                    type="file" 
                    accept="image/*" 
                    capture="environment"
                    className="hidden" 
                    ref={fileInputRef}
                    onChange={(e) => {
                      const file = e.target.files[0];
                      if (file) {
                        const reader = new FileReader();
                        reader.onloadend = () => analyzeImage(reader.result);
                        reader.readAsDataURL(file);
                      }
                    }}
                  />
                  <button 
                    onClick={() => fileInputRef.current.click()}
                    className="w-full bg-white text-black font-black uppercase italic py-5 rounded-2xl mt-4"
                  >
                    Open Camera
                  </button>
                </>
              )}
            </div>
          )}
        </section>

        {/* Collection Display */}
        {[
          { title: "Normal World", filter: 'Normal', icon: <Star className="w-5 h-5 text-yellow-500" /> },
          { title: "Upside Down", filter: 'UD', icon: <Moon className="w-5 h-5 text-blue-500" /> }
        ].map(cat => (
          <section key={cat.title} className="space-y-6">
            <div className="flex items-center gap-3 px-2">
              {cat.icon}
              <h2 className="text-lg font-black uppercase italic tracking-widest text-slate-400">{cat.title}</h2>
              <div className="flex-1 h-px bg-white/10" />
            </div>
            
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-4">
              {STRANGER_THINGS_TOYS.filter(t => t.group === cat.filter).map((toy) => {
                const isOwned = collectionData.includes(toy.id);
                return (
                  <div key={toy.id} className={`aspect-[3/4] rounded-3xl border-2 transition-all duration-500 flex flex-col items-center justify-center p-4 text-center
                        ${isOwned ? 'bg-slate-900 border-red-600/50 shadow-xl' : 'bg-black border-white/5 opacity-40 grayscale'}`}>
                    {isOwned ? (
                      <CheckCircle2 className="w-10 h-10 text-red-500 mb-3" />
                    ) : (
                      <Ghost className="w-10 h-10 text-slate-800 mb-3" />
                    )}
                    <p className="text-[10px] font-black uppercase leading-tight">{toy.name}</p>
                    <p className="text-[8px] font-bold mt-1 text-slate-600">{toy.id}</p>
                  </div>
                );
              })}
            </div>
          </section>
        ))}
      </main>

      {/* Toast Notification */}
      {message.text && (
        <div className="fixed bottom-10 left-1/2 -translate-x-1/2 z-[100] animate-in slide-in-from-bottom-5">
          <div className={`px-8 py-4 rounded-full border shadow-2xl backdrop-blur-xl bg-black/90 ${
            message.type === 'success' ? 'border-green-500/50 text-green-400' : 'border-red-500/50 text-red-400'
          }`}>
            <span className="font-black uppercase italic text-sm tracking-wide">{message.text}</span>
          </div>
        </div>
      )}
    </div>
  );
}
