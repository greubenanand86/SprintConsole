/* SprintOps Console — Layout Chrome
   TopAppBar, Sidebar, BottomNav
*/

const NAV_ITEMS = [
  { id: 'readiness',  label: 'Readiness Tracker',  icon: 'layout-dashboard' },
  { id: 'estimation', label: 'Estimation Planner',  icon: 'calculator' },
  { id: 'release',    label: 'Release Readiness',   icon: 'rocket' },
  { id: 'config',     label: 'Configuration',       icon: 'settings' },
];

// ─── TopAppBar ────────────────────────────────────────────────────────────────
function TopAppBar({ theme, onToggleTheme, sprint, iterations, onChangeSprint, connection, onCheckConnection }) {
  const [sprintOpen, setSprintOpen] = React.useState(false);
  const sprintRef = React.useRef(null);

  React.useEffect(() => {
    const onDown = e => { if (sprintRef.current && !sprintRef.current.contains(e.target)) setSprintOpen(false); };
    document.addEventListener('mousedown', onDown);
    return () => document.removeEventListener('mousedown', onDown);
  }, []);

  const connBadge = (() => {
    const map = {
      testing: { bg:'color-mix(in srgb,var(--color-info-bg) 35%,transparent)', border:'color-mix(in srgb,var(--color-info) 20%,transparent)', fg:'var(--color-info-fg)',    icon:'loader-2',      label:'Connecting\u2026', spin:true, pulse:true },
      success: { bg:'color-mix(in srgb,var(--color-success-bg) 35%,transparent)', border:'color-mix(in srgb,var(--color-success) 20%,transparent)', fg:'var(--color-success)', icon:'check-circle-2', label:'ADO Connected' },
      failure: { bg:'color-mix(in srgb,var(--color-danger-bg) 35%,transparent)',  border:'color-mix(in srgb,var(--color-danger) 20%,transparent)',  fg:'var(--color-danger-fg)', icon:'alert-circle', label:'ADO Disconnected' },
      idle:    { bg:'var(--color-bg-muted)', border:'var(--color-border)', fg:'var(--color-text-secondary)', icon:'refresh-cw', label:'Check Connection' },
    };
    const c = map[connection] || map.idle;
    return (
      <button onClick={onCheckConnection} title="Click to re-test connection"
        style={{ display:'inline-flex',alignItems:'center',gap:8,padding:'6px 12px',borderRadius:9999,background:c.bg,border:`1px solid ${c.border}`,color:c.fg,fontSize:11,fontWeight:700,letterSpacing:'0.05em',textTransform:'uppercase',cursor:'pointer',animation:c.pulse?'pulse 1.6s infinite':'none' }}>
        <Icon name={c.icon} size={14} className={c.spin?'spin':''} />
        <span style={{ display:'none' }} className="sm-show">{c.label}</span>
        <span className="sm-hide">{c.label}</span>
      </button>
    );
  })();

  const [themHov, setThemHov] = React.useState(false);

  return (
    <header style={{ position:'fixed',top:0,left:0,right:0,height:64,background:'var(--color-bg-surface)',borderBottom:'1px solid var(--color-border)',zIndex:30,display:'flex',alignItems:'center',justifyContent:'space-between',padding:'0 20px',gap:16 }}>
      {/* Left: Logo + sprint */}
      <div style={{ display:'flex',alignItems:'center',gap:16,minWidth:0 }}>
        {/* Logo */}
        <div style={{ display:'flex',alignItems:'center',gap:10,flexShrink:0 }}>
          <div style={{ width:32,height:32,borderRadius:8,background:'var(--color-primary)',color:'var(--color-primary-fg)',display:'flex',alignItems:'center',justifyContent:'center',boxShadow:'0 1px 2px 0 rgba(0,0,0,.05)' }}>
            <Icon name="activity" size={20} strokeWidth={2.5} />
          </div>
          <span style={{ fontSize:18,fontWeight:700,letterSpacing:'-0.01em',color:'var(--color-text-primary)',whiteSpace:'nowrap' }}>SprintOps Console</span>
        </div>

        {/* Sprint selector */}
        <div ref={sprintRef} style={{ position:'relative' }}>
          <button onClick={() => setSprintOpen(o => !o)}
            style={{ display:'inline-flex',alignItems:'center',gap:6,padding:'6px 10px',borderRadius:8,background:sprintOpen?'var(--color-bg-base)':'transparent',border:`1px solid ${sprintOpen?'var(--color-border)':'transparent'}`,cursor:'pointer',fontSize:13,fontWeight:500,color:'var(--color-text-primary)',fontFamily:'inherit',transition:'all .15s' }}>
            {sprint}
            <Icon name="chevron-down" size={15} style={{ color:'var(--color-text-secondary)',transition:'transform .2s',transform:sprintOpen?'rotate(180deg)':'none' }} />
          </button>
          {sprintOpen && (
            <div style={{ position:'absolute',top:'calc(100% + 4px)',left:0,minWidth:220,background:'var(--color-bg-surface)',border:'1px solid var(--color-border)',borderRadius:12,boxShadow:'0 10px 15px -3px rgba(0,0,0,.1),0 4px 6px -2px rgba(0,0,0,.05)',zIndex:50,padding:'4px 0',overflow:'hidden' }}>
              {iterations.map(it => {
                const name = it.split('\\').pop();
                const active = name === sprint;
                return (
                  <button key={it} onClick={() => { onChangeSprint(name); setSprintOpen(false); }}
                    style={{ width:'100%',textAlign:'left',padding:'8px 16px',display:'flex',alignItems:'center',justifyContent:'space-between',fontSize:13,border:'none',background:active?'color-mix(in srgb,var(--color-primary) 8%,transparent)':'transparent',cursor:'pointer',color:active?'var(--color-primary)':'var(--color-text-primary)',fontWeight:active?500:400,fontFamily:'inherit' }}>
                    <span>{name}</span>
                    {active && <Icon name="check" size={15} />}
                  </button>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* Right: connection + theme */}
      <div style={{ display:'flex',alignItems:'center',gap:10,flexShrink:0 }}>
        {connBadge}
        <button onClick={onToggleTheme} title={`Switch to ${theme==='light'?'dark':'light'} mode`}
          onMouseEnter={() => setThemHov(true)} onMouseLeave={() => setThemHov(false)}
          style={{ width:36,height:36,borderRadius:9999,border:'none',background:themHov?'var(--color-bg-base)':'transparent',cursor:'pointer',color:themHov?'var(--color-text-primary)':'var(--color-text-secondary)',display:'inline-flex',alignItems:'center',justifyContent:'center',transition:'all .15s' }}>
          <Icon name={theme==='light'?'moon':'sun'} size={20} />
        </button>
      </div>
    </header>
  );
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────
function Sidebar({ active, onChange, collapsed, onToggle }) {
  const width = collapsed ? 80 : 256;
  return (
    <aside className="ds-sidebar-desktop"
      style={{ position:'fixed',left:0,top:64,bottom:0,width,padding:12,background:'var(--color-bg-surface)',borderRight:'1px solid var(--color-border)',display:'flex',flexDirection:'column',transition:'width .3s',zIndex:20,overflow:'hidden' }}>
      <nav style={{ display:'flex',flexDirection:'column',gap:2,flex:1 }}>
        {NAV_ITEMS.map(item => {
          const isActive = item.id === active;
          return (
            <NavButton key={item.id} item={item} isActive={isActive} collapsed={collapsed} onChange={onChange} />
          );
        })}
      </nav>
      <div style={{ borderTop:'1px solid var(--color-border)',paddingTop:8,marginTop:8 }}>
        <CollapseButton collapsed={collapsed} onToggle={onToggle} />
      </div>
    </aside>
  );
}

function NavButton({ item, isActive, collapsed, onChange }) {
  const [hov, setHov] = React.useState(false);
  return (
    <button onClick={() => onChange(item.id)} title={collapsed?item.label:undefined}
      onMouseEnter={() => setHov(true)} onMouseLeave={() => setHov(false)}
      style={{ display:'flex',alignItems:'center',gap:10,padding:collapsed?'10px':'10px 12px',justifyContent:collapsed?'center':'flex-start',borderRadius:12,fontSize:13,fontWeight:500,fontFamily:'inherit',background:isActive?'color-mix(in srgb,var(--color-primary) 10%,transparent)':hov?'var(--color-bg-base)':'transparent',color:isActive?'var(--color-primary)':hov?'var(--color-text-primary)':'var(--color-text-secondary)',border:'none',cursor:'pointer',textAlign:'left',transition:'all .15s',whiteSpace:'nowrap',overflow:'hidden' }}>
      <Icon name={item.icon} size={20} style={{ flexShrink:0 }} />
      {!collapsed && <span style={{ overflow:'hidden',textOverflow:'ellipsis' }}>{item.label}</span>}
    </button>
  );
}

function CollapseButton({ collapsed, onToggle }) {
  const [hov, setHov] = React.useState(false);
  return (
    <button onClick={onToggle} title={collapsed?'Expand Navigation':'Collapse Navigation'}
      onMouseEnter={() => setHov(true)} onMouseLeave={() => setHov(false)}
      style={{ display:'flex',alignItems:'center',justifyContent:collapsed?'center':'flex-start',gap:10,padding:collapsed?'10px':'10px 12px',width:'100%',borderRadius:12,background:hov?'var(--color-bg-base)':'transparent',border:'none',color:hov?'var(--color-text-primary)':'var(--color-text-secondary)',cursor:'pointer',fontSize:13,fontWeight:500,fontFamily:'inherit',transition:'all .15s',whiteSpace:'nowrap',overflow:'hidden' }}>
      <Icon name={collapsed?'chevron-right':'chevron-left'} size={20} style={{ flexShrink:0 }} />
      {!collapsed && <span>Collapse</span>}
    </button>
  );
}

// ─── BottomNav ────────────────────────────────────────────────────────────────
function BottomNav({ active, onChange }) {
  return (
    <nav className="ds-bottom-nav"
      style={{ position:'fixed',left:0,right:0,bottom:0,height:64,zIndex:30,background:'var(--color-bg-surface)',borderTop:'1px solid var(--color-border)',alignItems:'center',justifyContent:'space-around',padding:'0 4px' }}>
      {NAV_ITEMS.map(item => {
        const isActive = item.id === active;
        return (
          <button key={item.id} onClick={() => onChange(item.id)}
            style={{ flex:1,height:'100%',border:'none',background:'transparent',display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',gap:3,fontSize:10,fontWeight:500,cursor:'pointer',color:isActive?'var(--color-primary)':'var(--color-text-secondary)',fontFamily:'inherit',transition:'color .15s',padding:'0 4px' }}>
            <Icon name={item.icon} size={20} />
            <span style={{ textAlign:'center',overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap',maxWidth:'100%' }}>{item.label}</span>
          </button>
        );
      })}
    </nav>
  );
}

Object.assign(window, { NAV_ITEMS, TopAppBar, Sidebar, BottomNav });
