/* SprintOps Console — Shared Components
   Icon, statePill, Toast, Button, Cards, FormControls, PageHeader, SecondaryTabBar, EmptyState
   Exports everything to window for cross-file access.
*/

// ─── Icon ────────────────────────────────────────────────────────────────────
function Icon({ name, size = 16, className = '', strokeWidth = 2, style }) {
  React.useLayoutEffect(() => {
    if (window.lucide) {
      window.lucide.createIcons({ nameAttr: 'data-lucide', attrs: { width: size, height: size, 'stroke-width': strokeWidth } });
    }
  });
  return (
    <i data-lucide={name} className={className}
      style={{ width: size, height: size, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, ...style }}
      aria-hidden="true" />
  );
}

// ─── State color helpers ──────────────────────────────────────────────────────
function statePill(state) {
  if (!state) return { bg: 'var(--color-bg-base)', fg: 'var(--color-text-secondary)', border: 'var(--color-border)' };
  const s = state.toLowerCase().trim();
  const blue   = ['ready for development','development in progress','active','code review','resolved'];
  const amber  = ['ready for testing','ready for uat','test in progress','uat in progress'];
  const green  = ['ready for production','production deployed','closed'];
  const purple = ['under refinement','design in progress'];
  if (blue.includes(s))   return { bg: 'var(--color-info-bg)',    fg: 'var(--color-info-fg)',    border: 'color-mix(in srgb,var(--color-info) 20%,transparent)' };
  if (amber.includes(s))  return { bg: 'var(--color-warning-bg)', fg: 'var(--color-warning-fg)', border: 'color-mix(in srgb,var(--color-warning) 20%,transparent)' };
  if (green.includes(s))  return { bg: 'var(--color-success-bg)', fg: 'var(--color-success-fg)', border: 'color-mix(in srgb,var(--color-success) 20%,transparent)' };
  if (purple.includes(s)) return { bg: 'var(--color-secondary)',  fg: 'var(--color-secondary-fg)', border: 'var(--color-border)' };
  return { bg: 'var(--color-bg-base)', fg: 'var(--color-text-secondary)', border: 'var(--color-border)' };
}
function StatePill({ state }) {
  const c = statePill(state);
  return (
    <span style={{ display:'inline-flex',alignItems:'center',padding:'4px 10px',borderRadius:9999,fontSize:12,fontWeight:600,background:c.bg,color:c.fg,border:`1px solid ${c.border}`,whiteSpace:'nowrap' }}>
      {state}
    </span>
  );
}

// ─── Toast ────────────────────────────────────────────────────────────────────
const ToastCtx = React.createContext({ push: () => {} });
function ToastProvider({ children }) {
  const [toasts, setToasts] = React.useState([]);
  const push = React.useCallback((message, type = 'info') => {
    const id = Date.now() + Math.random();
    setToasts(p => [...p, { id, message, type }]);
    setTimeout(() => setToasts(p => p.filter(t => t.id !== id)), 4500);
  }, []);
  const remove = id => setToasts(p => p.filter(t => t.id !== id));
  const tones = {
    success: { bg:'var(--color-success-bg)', fg:'var(--color-success-fg)', border:'color-mix(in srgb,var(--color-success) 25%,transparent)', icon:'check-circle-2' },
    error:   { bg:'var(--color-danger-bg)',  fg:'var(--color-danger-fg)',  border:'color-mix(in srgb,var(--color-danger) 30%,transparent)',  icon:'alert-circle' },
    warning: { bg:'var(--color-warning-bg)', fg:'var(--color-warning-fg)', border:'color-mix(in srgb,var(--color-warning) 30%,transparent)', icon:'alert-circle' },
    info:    { bg:'var(--color-bg-surface)', fg:'var(--color-text-primary)', border:'var(--color-border)', icon:'info' }
  };
  return (
    <ToastCtx.Provider value={{ push }}>
      {children}
      <div style={{ position:'fixed',right:16,bottom:80,display:'flex',flexDirection:'column',gap:8,zIndex:9999,maxWidth:420 }}>
        {toasts.map(t => {
          const tone = tones[t.type] || tones.info;
          return (
            <div key={t.id} role="alert"
              style={{ display:'flex',alignItems:'center',gap:12,padding:'12px 16px',borderRadius:12,border:`1px solid ${tone.border}`,background:tone.bg,color:tone.fg,boxShadow:'0 10px 15px -3px rgba(0,0,0,.1),0 4px 6px -2px rgba(0,0,0,.05)',fontSize:13,fontWeight:500 }}>
              <Icon name={tone.icon} size={18} />
              <span style={{ flex:1 }}>{t.message}</span>
              <button onClick={() => remove(t.id)} aria-label="Dismiss"
                style={{ border:'none',background:'transparent',color:'inherit',opacity:.7,cursor:'pointer',padding:2,display:'inline-flex' }}>
                <Icon name="x" size={16} />
              </button>
            </div>
          );
        })}
      </div>
    </ToastCtx.Provider>
  );
}
const useToast = () => React.useContext(ToastCtx);

// ─── Button ───────────────────────────────────────────────────────────────────
function Button({ children, variant='primary', icon, iconAfter, onClick, disabled, busy, size='md', style, type='button' }) {
  const [hov, setHov] = React.useState(false);
  const variants = {
    primary: { bg: hov?'var(--color-primary-hover)':'var(--color-primary)', fg:'var(--color-primary-fg)', border:'transparent', shadow:'0 1px 2px 0 rgba(0,0,0,.05)' },
    secondary:{ bg: hov?'var(--color-bg-muted)':'var(--color-bg-surface)', fg:'var(--color-text-primary)', border:'var(--color-border)', shadow:'0 1px 2px 0 rgba(0,0,0,.05)' },
    ghost:    { bg: hov?'var(--color-bg-base)':'transparent', fg: hov?'var(--color-text-primary)':'var(--color-text-secondary)', border:'transparent', shadow:'none' },
    danger:   { bg: hov?'#b91c1c':'var(--color-danger)', fg:'#fff', border:'transparent', shadow:'0 1px 2px 0 rgba(0,0,0,.05)' },
    success:  { bg: hov?'var(--color-success-fg)':'var(--color-success)', fg:'#fff', border:'transparent', shadow:'0 1px 2px 0 rgba(0,0,0,.05)' },
    warning:  { bg: hov?'#92400e':'var(--color-warning)', fg:'#fff', border:'transparent', shadow:'0 1px 2px 0 rgba(0,0,0,.05)' },
  };
  const sizes = { sm:{padding:'4px 10px',fontSize:12,borderRadius:6,gap:4}, md:{padding:'7px 12px',fontSize:13,borderRadius:8,gap:6}, lg:{padding:'10px 16px',fontSize:14,borderRadius:10,gap:8} };
  const v = variants[variant] || variants.primary;
  const s = sizes[size] || sizes.md;
  return (
    <button type={type} onClick={onClick} disabled={disabled||busy}
      onMouseEnter={() => setHov(true)} onMouseLeave={() => setHov(false)}
      style={{ display:'inline-flex',alignItems:'center',fontFamily:'inherit',fontWeight:500,cursor:(disabled||busy)?'not-allowed':'pointer',opacity:(disabled||busy)?.6:1,transition:'background .15s,color .15s',background:v.bg,color:v.fg,border:`1px solid ${v.border}`,boxShadow:v.shadow,...s,...style }}>
      {busy ? <Icon name="loader-2" size={14} className="spin" /> : icon ? <Icon name={icon} size={14} /> : null}
      {children}
      {!busy && iconAfter && <Icon name={iconAfter} size={14} />}
    </button>
  );
}

// ─── Cards ────────────────────────────────────────────────────────────────────
function SectionCard({ title, subtitle, children, style, actions }) {
  return (
    <section style={{ background:'var(--color-bg-surface)',border:'1px solid var(--color-border)',borderRadius:16,padding:24,boxShadow:'0 4px 6px -1px rgba(0,0,0,.05),0 2px 4px -1px rgba(0,0,0,.03)',...style }}>
      {(title||actions) && (
        <div style={{ display:'flex',alignItems:'flex-start',justifyContent:'space-between',gap:12,marginBottom:20 }}>
          <div>
            {title && <h2 style={{ margin:0,fontSize:18,fontWeight:600,color:'var(--color-text-primary)' }}>{title}</h2>}
            {subtitle && <p style={{ margin:'4px 0 0',fontSize:13,color:'var(--color-text-secondary)' }}>{subtitle}</p>}
          </div>
          {actions}
        </div>
      )}
      {children}
    </section>
  );
}

function RowCard({ children, style, onClick }) {
  const [hov, setHov] = React.useState(false);
  return (
    <div onClick={onClick} onMouseEnter={() => setHov(true)} onMouseLeave={() => setHov(false)}
      style={{ background:'var(--color-bg-surface)',border:`1px solid ${hov?'color-mix(in srgb,var(--color-primary) 30%,transparent)':'var(--color-border)'}`,borderRadius:12,boxShadow:'0 1px 2px 0 rgba(0,0,0,.05)',overflow:'hidden',transition:'border-color .2s',...style }}>
      {children}
    </div>
  );
}

function Eyebrow({ children, style }) {
  return <span style={{ fontSize:10,fontWeight:700,letterSpacing:'0.05em',textTransform:'uppercase',color:'var(--color-text-secondary)',...style }}>{children}</span>;
}

// ─── AccordionCard ────────────────────────────────────────────────────────────
function AccordionCard({ title, children, defaultOpen=true, disabled=false, errorCount=0, icon, headerActions }) {
  const [open, setOpen] = React.useState(defaultOpen);
  return (
    <div style={{ background:'var(--color-bg-surface)',border:'1px solid var(--color-border)',borderRadius:16,overflow:'hidden',boxShadow:'0 4px 6px -1px rgba(0,0,0,.05),0 2px 4px -1px rgba(0,0,0,.03)',opacity:disabled?.65:1 }}>
      <button onClick={() => !disabled && setOpen(o => !o)} disabled={disabled}
        style={{ width:'100%',display:'flex',alignItems:'center',justifyContent:'space-between',gap:12,padding:24,background:'transparent',border:'none',cursor:disabled?'not-allowed':'pointer',textAlign:'left' }}>
        <div style={{ display:'flex',alignItems:'center',gap:10,flexWrap:'wrap' }}>
          {icon && <Icon name={icon} size={18} style={{ color:'var(--color-text-secondary)' }} />}
          <span style={{ fontSize:18,fontWeight:600,color:'var(--color-text-primary)' }}>{title}</span>
          {disabled && <span style={{ fontSize:10,fontWeight:700,letterSpacing:'0.05em',textTransform:'uppercase',padding:'2px 8px',borderRadius:9999,background:'var(--color-bg-muted)',color:'var(--color-text-muted)' }}>Requires Connection</span>}
          {errorCount>0 && <span style={{ fontSize:11,fontWeight:700,padding:'2px 8px',borderRadius:9999,background:'var(--color-danger-bg)',color:'var(--color-danger-fg)',border:'1px solid color-mix(in srgb,var(--color-danger) 20%,transparent)' }}>{errorCount} error{errorCount!==1?'s':''}</span>}
        </div>
        <div style={{ display:'flex',alignItems:'center',gap:8 }}>
          {headerActions}
          <Icon name={open?'chevron-up':'chevron-down'} size={20} style={{ color:'var(--color-text-secondary)',flexShrink:0 }} />
        </div>
      </button>
      {open && <div style={{ padding:'0 24px 24px' }}>{children}</div>}
    </div>
  );
}

// ─── Form Controls ────────────────────────────────────────────────────────────
function FormInput({ label, value, onChange, type='text', placeholder, helper, error, disabled, monospace }) {
  const [focus, setFocus] = React.useState(false);
  return (
    <div style={{ display:'flex',flexDirection:'column',gap:6 }}>
      {label && <label style={{ fontSize:13,fontWeight:500,color:'var(--color-text-primary)' }}>{label}</label>}
      <input type={type} value={value} onChange={onChange} placeholder={placeholder} disabled={disabled}
        onFocus={() => setFocus(true)} onBlur={() => setFocus(false)}
        style={{ padding:'8px 12px',borderRadius:8,border:`1px solid ${focus?'var(--color-primary)':error?'var(--color-danger)':'var(--color-input-border)'}`,background:'var(--color-input-bg)',color:'var(--color-input-text)',fontSize:13,fontFamily:monospace?'var(--font-mono)':'inherit',outline:'none',transition:'border .15s',opacity:disabled?.6:1,width:'100%',boxSizing:'border-box' }} />
      {error && <span style={{ fontSize:11,color:'var(--color-danger)' }}>{error}</span>}
      {helper && !error && <span style={{ fontSize:11,color:'var(--color-text-muted)' }}>{helper}</span>}
    </div>
  );
}

function FormSelect({ label, value, onChange, options=[], helper, disabled }) {
  const [focus, setFocus] = React.useState(false);
  return (
    <div style={{ display:'flex',flexDirection:'column',gap:6 }}>
      {label && <label style={{ fontSize:13,fontWeight:500,color:'var(--color-text-primary)' }}>{label}</label>}
      <select value={value} onChange={onChange} disabled={disabled}
        onFocus={() => setFocus(true)} onBlur={() => setFocus(false)}
        style={{ padding:'8px 12px',borderRadius:8,border:`1px solid ${focus?'var(--color-primary)':'var(--color-input-border)'}`,background:'var(--color-input-bg)',color:'var(--color-input-text)',fontSize:13,fontFamily:'inherit',outline:'none',opacity:disabled?.6:1,width:'100%',boxSizing:'border-box' }}>
        {options.map(o => <option key={o.value||o} value={o.value||o}>{o.label||o}</option>)}
      </select>
      {helper && <span style={{ fontSize:11,color:'var(--color-text-muted)' }}>{helper}</span>}
    </div>
  );
}

function FormToggle({ label, checked, onChange, helper, disabled }) {
  return (
    <div style={{ display:'flex',alignItems:'flex-start',gap:12,padding:'6px 0' }}>
      <button role="switch" aria-checked={checked} onClick={() => !disabled && onChange(!checked)}
        style={{ width:36,height:20,borderRadius:10,background:checked?'var(--color-primary)':'var(--color-border)',border:'none',cursor:disabled?'not-allowed':'pointer',position:'relative',transition:'background .2s',flexShrink:0,marginTop:2,padding:0 }}>
        <div style={{ position:'absolute',top:2,left:checked?18:2,width:16,height:16,borderRadius:9999,background:'white',transition:'left .2s',boxShadow:'0 1px 3px rgba(0,0,0,.2)' }} />
      </button>
      <div>
        <div style={{ fontSize:13,fontWeight:500,color:'var(--color-text-primary)' }}>{label}</div>
        {helper && <div style={{ fontSize:11,color:'var(--color-text-muted)',marginTop:2 }}>{helper}</div>}
      </div>
    </div>
  );
}

// ─── PageHeader ────────────────────────────────────────────────────────────────
function PageHeader({ title, description, actions }) {
  return (
    <div style={{ display:'flex',justifyContent:'space-between',alignItems:'flex-start',gap:16,marginBottom:28,flexWrap:'wrap' }}>
      <div>
        <h1 style={{ margin:0,fontSize:24,fontWeight:700,letterSpacing:'-0.01em',color:'var(--color-text-primary)',lineHeight:1.2 }}>{title}</h1>
        {description && <p style={{ margin:'4px 0 0',fontSize:13,color:'var(--color-text-secondary)' }}>{description}</p>}
      </div>
      {actions && <div style={{ display:'flex',alignItems:'center',gap:8,flexWrap:'wrap' }}>{actions}</div>}
    </div>
  );
}

// ─── SecondaryTabBar ──────────────────────────────────────────────────────────
function SecondaryTabBar({ tabs, active, onChange }) {
  return (
    <div style={{ position:'sticky',top:64,zIndex:20,background:'color-mix(in srgb,var(--color-bg-base) 85%,transparent)',backdropFilter:'blur(8px)',WebkitBackdropFilter:'blur(8px)',borderBottom:'1px solid var(--color-border)',margin:'0 -32px 24px',padding:'0 32px' }}>
      <nav style={{ display:'flex',gap:4,overflowX:'auto',scrollbarWidth:'none',padding:'8px 0' }}>
        {tabs.map(t => {
          const isActive = (t.id||t) === active;
          const label = t.label||t;
          const count = t.count;
          return (
            <button key={t.id||t} onClick={() => onChange(t.id||t)}
              style={{ display:'inline-flex',alignItems:'center',gap:6,whiteSpace:'nowrap',padding:'6px 12px',borderRadius:8,fontSize:13,fontWeight:500,fontFamily:'inherit',background:isActive?'var(--color-bg-surface)':'transparent',color:isActive?'var(--color-primary)':'var(--color-text-secondary)',border:`1px solid ${isActive?'var(--color-border)':'transparent'}`,boxShadow:isActive?'0 1px 2px 0 rgba(0,0,0,.05)':'none',cursor:'pointer',transition:'all .15s' }}>
              {label}
              {count !== undefined && (
                <span style={{ padding:'1px 7px',borderRadius:9999,fontSize:10,fontWeight:600,background:isActive?'color-mix(in srgb,var(--color-primary) 10%,transparent)':'var(--color-bg-muted)',color:isActive?'var(--color-primary)':'var(--color-text-secondary)',border:`1px solid ${isActive?'transparent':'var(--color-border)'}` }}>{count}</span>
              )}
            </button>
          );
        })}
      </nav>
    </div>
  );
}

// ─── EmptyState ────────────────────────────────────────────────────────────────
function EmptyState({ icon='inbox', title, body, action, warn }) {
  return (
    <div style={{ display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',padding:'64px 24px',textAlign:'center',background:'var(--color-bg-surface)',border:`1px dashed ${warn?'var(--color-warning)':'var(--color-border)'}`,borderRadius:16 }}>
      <div style={{ width:52,height:52,borderRadius:9999,background:warn?'var(--color-warning-bg)':'var(--color-bg-muted)',color:warn?'var(--color-warning-fg)':'var(--color-text-secondary)',display:'flex',alignItems:'center',justifyContent:'center',marginBottom:16 }}>
        <Icon name={icon} size={26} />
      </div>
      <h3 style={{ margin:0,fontSize:16,fontWeight:700,color:'var(--color-text-primary)' }}>{title}</h3>
      <p style={{ margin:'6px 0 0',fontSize:13,color:'var(--color-text-secondary)',maxWidth:400 }}>{body}</p>
      {action && <div style={{ marginTop:20 }}>{action}</div>}
    </div>
  );
}

// ─── Divider ──────────────────────────────────────────────────────────────────
function Divider({ style }) {
  return <div style={{ height:1,background:'var(--color-border)',margin:'16px 0',...style }} />;
}

Object.assign(window, {
  Icon, statePill, StatePill,
  ToastCtx, ToastProvider, useToast,
  Button, SectionCard, RowCard, Eyebrow, AccordionCard, Divider,
  FormInput, FormSelect, FormToggle,
  PageHeader, SecondaryTabBar, EmptyState
});
