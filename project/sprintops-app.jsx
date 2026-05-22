/* SprintOps Console — App Root
   Wires all pages, layout chrome, theme, and Tweaks panel.
*/

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "theme": "light",
  "accentColor": "#2563eb",
  "demoConnection": "success"
}/*EDITMODE-END*/;

function App() {
  const data = window.SPRINTOPS_DATA;

  // ── Tweaks (persisted via TweaksPanel protocol) ──
  const [tweaks, setTweak] = useTweaks(TWEAK_DEFAULTS);

  // ── Core state ──
  const [page, setPage] = React.useState('readiness');
  const [collapsed, setCollapsed] = React.useState(() => window.innerWidth < 1100);
  const [sprint, setSprint] = React.useState(data.iteration.name);
  const [connection, setConnection] = React.useState(tweaks.demoConnection || 'success');

  // ── Theme ──
  React.useEffect(() => {
    document.documentElement.classList.toggle('dark', tweaks.theme === 'dark');
    try { localStorage.setItem('sprintops_theme', tweaks.theme); } catch (_) {}
  }, [tweaks.theme]);

  // ── Accent color ──
  React.useEffect(() => {
    const root = document.documentElement;
    if (tweaks.accentColor) {
      root.style.setProperty('--color-primary', tweaks.accentColor);
      root.style.setProperty('--color-progress-fill', tweaks.accentColor);
      // rough hover: darken slightly via mix
      root.style.setProperty('--color-primary-hover', `color-mix(in srgb,${tweaks.accentColor} 80%,#000)`);
    }
  }, [tweaks.accentColor]);

  // ── Demo connection sync ──
  React.useEffect(() => {
    setConnection(tweaks.demoConnection || 'success');
  }, [tweaks.demoConnection]);

  // ── Connection test (simulated) ──
  const handleTestConnection = () => {
    setConnection('testing');
    setTimeout(() => {
      setConnection('success');
      setTweak('demoConnection', 'success');
    }, 1400);
  };

  // ── Sidebar width ──
  const sidebarW = collapsed ? 80 : 256;

  // ── Page render ──
  const renderPage = () => {
    switch (page) {
      case 'estimation': return <EstimationPlannerPage sprintName={sprint} />;
      case 'release':    return <ReleaseReadinessPage sprintName={sprint} onNavigate={setPage} />;
      case 'config':     return <ConfigurationPage connection={connection} onTestConnection={handleTestConnection} />;
      default:           return <ReadinessTrackerPage sprintName={sprint} onNavigate={setPage} />;
    }
  };

  return (
    <ToastProvider>
      <div style={{ minHeight:'100vh', background:'var(--color-bg-base)', color:'var(--color-text-primary)', fontFamily:'var(--font-sans)' }}>

        <TopAppBar
          theme={tweaks.theme}
          onToggleTheme={() => setTweak('theme', tweaks.theme === 'light' ? 'dark' : 'light')}
          sprint={sprint}
          iterations={data.iterations}
          onChangeSprint={setSprint}
          connection={connection}
          onCheckConnection={handleTestConnection}
        />

        <div style={{ display:'flex', paddingTop:64 }}>
          <Sidebar
            active={page}
            onChange={setPage}
            collapsed={collapsed}
            onToggle={() => setCollapsed(c => !c)}
          />

          <main style={{ flex:1, paddingLeft:sidebarW, paddingBottom:80, transition:'padding-left .3s', minWidth:0 }}>
            <div style={{ maxWidth:1600, margin:'0 auto', padding:'32px 32px' }}>
              {renderPage()}
            </div>
          </main>
        </div>

        <BottomNav active={page} onChange={setPage} />

        {/* Tweaks Panel */}
        <TweaksPanel>
          <TweakSection label="Appearance">
            <TweakRadio id="theme" label="Theme"
              options={['light','dark']}
              value={tweaks.theme}
              onChange={v => setTweak('theme', v)} />
            <TweakColor id="accentColor" label="Accent Color"
              options={['#2563eb','#7c3aed','#0891b2','#059669','#dc2626']}
              value={tweaks.accentColor}
              onChange={v => setTweak('accentColor', v)} />
          </TweakSection>
          <TweakSection label="Demo Controls">
            <TweakSelect id="demoConnection" label="Connection Status"
              options={[
                { value:'success', label:'ADO Connected' },
                { value:'failure', label:'ADO Disconnected' },
                { value:'idle',    label:'Not Tested' },
              ]}
              value={tweaks.demoConnection}
              onChange={v => { setTweak('demoConnection', v); setConnection(v); }} />
          </TweakSection>
        </TweaksPanel>

      </div>
    </ToastProvider>
  );
}

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App />);
