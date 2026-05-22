/* SprintOps Console — Readiness Tracker
   TaskCell, ReadinessMeter, ReadinessRow, ReadinessTrackerPage
*/

// ─── TaskCell ─────────────────────────────────────────────────────────────────
function TaskCell({ actionState, adoState, isLink, onClick, onLinkExisting, title, disabled: cellDisabled }) {
  const [menuOpen, setMenuOpen] = React.useState(false);
  const [coords, setCoords] = React.useState({ top: 0, left: 0 });
  const triggerRef = React.useRef(null);
  const menuRef = React.useRef(null);

  const isClosed = adoState === 'Closed';
  const isClickable = (actionState === 'absent' || actionState === 'failed') && !cellDisabled;

  let cellStyle, icon;
  switch (actionState) {
    case 'absent':
      cellStyle = { background: 'var(--color-bg-surface)', border: '1px dashed var(--color-border)', color: 'var(--color-text-secondary)' };
      icon = isLink ? 'link' : 'plus'; break;
    case 'creating':
      cellStyle = { background: 'var(--color-info-bg)', border: '1px solid color-mix(in srgb,var(--color-info) 30%,transparent)', color: 'var(--color-info-fg)' };
      icon = 'loader-2'; break;
    case 'failed':
      cellStyle = { background: 'var(--color-danger-bg)', border: '1px solid var(--color-danger)', color: 'var(--color-danger-fg)' };
      icon = 'x'; break;
    case 'created':
      if (isLink || isClosed) {
        cellStyle = { background: 'var(--color-success-bg)', border: '1px solid color-mix(in srgb,var(--color-success) 30%,transparent)', color: 'var(--color-success-fg)' };
      } else {
        cellStyle = { background: 'var(--color-warning-bg)', border: '1px solid color-mix(in srgb,var(--color-warning) 30%,transparent)', color: 'var(--color-warning-fg)' };
      }
      icon = isLink ? 'link' : 'check'; break;
    default:
      cellStyle = { background: 'transparent', border: '1px dashed var(--color-border)', color: 'var(--color-text-secondary)' };
      icon = 'plus';
  }

  const updateCoords = React.useCallback(() => {
    if (triggerRef.current) {
      const rect = triggerRef.current.getBoundingClientRect();
      setCoords({ top: rect.bottom + 4, left: Math.min(rect.left, window.innerWidth - 175) });
    }
  }, []);

  React.useEffect(() => {
    if (!menuOpen) return;
    updateCoords();
    const onScroll = () => updateCoords();
    window.addEventListener('scroll', onScroll, true);
    window.addEventListener('resize', onScroll);
    return () => { window.removeEventListener('scroll', onScroll, true); window.removeEventListener('resize', onScroll); };
  }, [menuOpen, updateCoords]);

  React.useEffect(() => {
    if (!menuOpen) return;
    const onDown = e => {
      if (menuRef.current && !menuRef.current.contains(e.target) && triggerRef.current && !triggerRef.current.contains(e.target)) setMenuOpen(false);
    };
    document.addEventListener('mousedown', onDown);
    return () => document.removeEventListener('mousedown', onDown);
  }, [menuOpen]);

  const handleClick = e => {
    e.stopPropagation();
    if (!isClickable) return;
    if (onLinkExisting) { updateCoords(); setMenuOpen(o => !o); }
    else if (onClick) onClick();
  };

  const menuItem = (iconName, label, color, handler) => {
    const [hov, setHov] = React.useState(false);
    return (
      <button onClick={e => { e.stopPropagation(); setMenuOpen(false); handler && handler(); }}
        onMouseEnter={() => setHov(true)} onMouseLeave={() => setHov(false)}
        style={{ width:'100%',padding:'8px 12px',background:hov?'color-mix(in srgb,var(--color-bg-muted) 60%,transparent)':'transparent',border:'none',cursor:'pointer',textAlign:'left',fontSize:13,color:'var(--color-text-primary)',display:'flex',alignItems:'center',gap:10,fontFamily:'inherit' }}>
        <Icon name={iconName} size={16} style={{ color }} />
        {label}
      </button>
    );
  };

  return (
    <>
      <button ref={triggerRef} onClick={handleClick} title={title || actionState}
        disabled={!isClickable && actionState !== 'created'}
        style={{ width:32,height:32,borderRadius:6,display:'inline-flex',alignItems:'center',justifyContent:'center',cursor:isClickable?'pointer':'default',padding:0,border:'none',transition:'all .15s',flexShrink:0,...cellStyle }}>
        <Icon name={icon} size={16} className={actionState==='creating'?'spin':''} />
      </button>
      {menuOpen && ReactDOM.createPortal(
        <div ref={menuRef} style={{ position:'fixed',top:coords.top,left:coords.left,width:165,zIndex:9999,background:'var(--color-bg-surface)',border:'1px solid var(--color-border)',borderRadius:12,padding:'4px 0',boxShadow:'0 10px 15px -3px rgba(0,0,0,.12),0 4px 6px -2px rgba(0,0,0,.06)' }}>
          <div style={{ padding:'6px 12px',borderBottom:'1px solid var(--color-border)',marginBottom:4 }}>
            <Eyebrow>Task Action</Eyebrow>
          </div>
          {menuItem('plus', 'Create New', 'var(--color-primary)', onClick)}
          {menuItem('link', 'Link Existing', 'var(--color-info-fg)', onLinkExisting)}
        </div>,
        document.body
      )}
    </>
  );
}

// ─── ReadinessMeter ───────────────────────────────────────────────────────────
function ReadinessMeter({ item }) {
  const r = item.readiness || window.SPRINTOPS_DATA.computeReadiness(item);
  const total = 4;
  let fill = 'var(--color-primary)';
  if (r.percent === 100) fill = 'var(--color-success)';
  else if (r.percent < 40) fill = 'var(--color-warning)';

  const tooltipLines = [
    `${r.parentReady?'✅':'❌'} Parent Ready`,
    `${r.uatClosed?'✅':'❌'} UAT Closed`,
    `${r.linkExists?'✅':'❌'} Link Exists`,
    `${r.isApproved?'✅':'❌'} Approved`,
  ].join('\n');

  return (
    <div title={`Readiness Criteria:\n${tooltipLines}`} style={{ minWidth:110,display:'flex',flexDirection:'column',gap:5 }}>
      <div style={{ display:'flex',justifyContent:'space-between',alignItems:'center',fontSize:12 }}>
        <span style={{ fontWeight:500,color:'var(--color-text-secondary)' }}>Readiness</span>
        <span style={{ fontWeight:700,color:r.percent===100?'var(--color-success)':'var(--color-text-primary)' }}>{r.percent}%</span>
      </div>
      <div style={{ display:'flex',gap:2,height:8 }}>
        {Array.from({length:total}).map((_,i) => (
          <div key={i} style={{ flex:1,background:i<r.met?fill:'var(--color-progress-track)',borderTopLeftRadius:i===0?9999:0,borderBottomLeftRadius:i===0?9999:0,borderTopRightRadius:i===total-1?9999:0,borderBottomRightRadius:i===total-1?9999:0,transition:'background .4s' }} />
        ))}
      </div>
      <span style={{ fontSize:10,color:'var(--color-text-secondary)',lineHeight:1.3 }}>{r.label}</span>
    </div>
  );
}

// ─── ReadinessRow ─────────────────────────────────────────────────────────────
function ReadinessRow({ item, onAction }) {
  const [expanded, setExpanded] = React.useState(false);
  const isBug = item.type === 'Bug';
  const sprint = item.iterationPath.split('\\').pop();
  const c = statePill(item.state);

  const appr = {
    approved:     { icon:'check-circle-2', bg:'var(--color-success-bg)',  fg:'var(--color-success-fg)',  border:'color-mix(in srgb,var(--color-success) 30%,transparent)', clickable:false },
    unknown:      { icon:'help-circle',    bg:'var(--color-warning-bg)',  fg:'var(--color-warning-fg)',  border:'color-mix(in srgb,var(--color-warning) 30%,transparent)', clickable:false },
    not_approved: { icon:'check',          bg:'var(--color-bg-surface)',  fg:'var(--color-text-secondary)', border:'var(--color-border)', dashed:true, clickable:true }
  }[item.approvalStatus] || { icon:'check', bg:'var(--color-bg-surface)', fg:'var(--color-text-secondary)', border:'var(--color-border)', dashed:true, clickable:true };

  const gridStyle = {
    display:'grid',
    gridTemplateColumns:'40px 76px minmax(180px,1fr) 90px 140px 36px 36px 36px 36px 36px 36px 130px',
    alignItems:'center', gap:8, padding:'10px 16px'
  };

  return (
    <RowCard>
      <div style={gridStyle}>
        {/* Expand */}
        <button onClick={e => { e.stopPropagation(); setExpanded(x => !x); }}
          style={{ width:32,height:32,borderRadius:8,border:'none',background:'transparent',cursor:'pointer',color:'var(--color-text-secondary)',display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0 }}>
          <Icon name={expanded?'chevron-down':'chevron-right'} size={20} />
        </button>

        {/* ID */}
        <a href="#" onClick={e => e.preventDefault()}
          style={{ display:'inline-flex',alignItems:'center',gap:4,fontSize:13,fontWeight:500,color:'var(--color-text-secondary)',textDecoration:'none' }}>
          #{item.id} <Icon name="external-link" size={11} style={{ opacity:.5 }} />
        </a>

        {/* Title + tags */}
        <div style={{ display:'flex',flexDirection:'column',gap:5,minWidth:0 }}>
          <span title={item.title} style={{ fontSize:13,fontWeight:600,color:'var(--color-text-primary)',overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap' }}>{item.title}</span>
          <div style={{ display:'flex',flexWrap:'wrap',gap:3 }}>
            {item.tags.map(tag => (
              <span key={tag} style={{ fontSize:10,fontWeight:500,padding:'2px 6px',borderRadius:4,background:'var(--color-bg-base)',border:'1px solid var(--color-border)',color:'var(--color-text-secondary)',whiteSpace:'nowrap' }}>{tag}</span>
            ))}
          </div>
        </div>

        {/* Type */}
        <div style={{ display:'flex',alignItems:'center',gap:5,fontSize:12,fontWeight:500,color:'var(--color-text-secondary)' }}>
          <Icon name={isBug?'bug':'file-text'} size={14} style={{ color:isBug?'var(--color-danger)':'var(--color-primary)' }} />
          <span style={{ overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap' }}>{item.type}</span>
        </div>

        {/* State */}
        <div><StatePill state={item.state} /></div>

        {/* Approval */}
        <div style={{ display:'flex',justifyContent:'center' }}>
          <button title={`Approval: ${item.approvalStatus.replace(/_/g,' ')}`}
            onClick={e => { e.stopPropagation(); appr.clickable && onAction('approve', item.id); }}
            style={{ width:32,height:32,borderRadius:6,background:appr.bg,color:appr.fg,border:`1px ${appr.dashed?'dashed':'solid'} ${appr.border}`,cursor:appr.clickable?'pointer':'default',display:'flex',alignItems:'center',justifyContent:'center',padding:0,flexShrink:0 }}>
            <Icon name={appr.icon} size={16} />
          </button>
        </div>

        {/* Dev QA UAT Post */}
        {['Dev','QA','UAT','Post'].map(slot => (
          <div key={slot} style={{ display:'flex',justifyContent:'center',opacity:slot==='UAT'?1:.8 }}>
            <TaskCell {...item.tasks[slot]} title={`${slot} task`}
              onClick={() => onAction('createTask', { id:item.id, slot })}
              onLinkExisting={() => onAction('linkTask', { id:item.id, slot })} />
          </div>
        ))}

        {/* Link */}
        <div style={{ display:'flex',justifyContent:'center' }}>
          <TaskCell {...item.link} isLink title="Deployment link" onClick={() => onAction('createLink', item.id)} />
        </div>

        {/* Readiness */}
        <div style={{ display:'flex',justifyContent:'flex-end' }}>
          <ReadinessMeter item={item} />
        </div>
      </div>

      {/* Expanded panel */}
      {expanded && (
        <div style={{ background:'color-mix(in srgb,var(--color-bg-muted) 35%,transparent)',borderTop:'1px solid var(--color-border)',padding:'16px 56px 20px' }}>
          <div style={{ display:'flex',alignItems:'center',justifyContent:'space-between',marginBottom:16,flexWrap:'wrap',gap:8 }}>
            <Eyebrow>Core Tracking &amp; Links</Eyebrow>
            <span style={{ fontSize:12,color:'var(--color-text-secondary)',background:'var(--color-bg-surface)',border:'1px solid var(--color-border)',padding:'4px 10px',borderRadius:6 }}>
              Parent Sprint: <strong style={{ color:'var(--color-text-primary)',marginLeft:4 }}>{sprint}</strong>
            </span>
          </div>
          <div style={{ display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:12 }}>
            {[
              { eyebrow:'Parent Item',     icon:'file-text',      iconBg:'color-mix(in srgb,var(--color-primary) 10%,transparent)', iconFg:'var(--color-primary)',  v:`#${item.id}`,              sub: item.assignee || 'Unassigned' },
              { eyebrow:'Child Work Items',icon:'check-circle-2', iconBg:'var(--color-info-bg)',   iconFg:'var(--color-info-fg)',   v:`${item.childrenCount} Total`, sub:`${item.closedChildren} Closed` },
              { eyebrow:'Related Items',   icon:'tag',            iconBg:'var(--color-secondary)',  iconFg:'var(--color-secondary-fg)', v:`${item.relatedItems} Links`, sub:'0 Unavailable' },
              { eyebrow:'Deployment Link', icon:'link',           iconBg:'color-mix(in srgb,var(--color-primary) 10%,transparent)', iconFg:'var(--color-primary)',  v: item.link.actionState==='created'?'Open Task':'Not linked', sub:item.link.url||'No link yet' },
            ].map(card => (
              <div key={card.eyebrow} style={{ background:'var(--color-bg-surface)',border:'1px solid var(--color-border)',borderRadius:12,padding:14,boxShadow:'0 1px 2px 0 rgba(0,0,0,.05)' }}>
                <Eyebrow style={{ display:'block',marginBottom:8 }}>{card.eyebrow}</Eyebrow>
                <div style={{ display:'flex',alignItems:'center',gap:10 }}>
                  <div style={{ width:32,height:32,borderRadius:8,background:card.iconBg,color:card.iconFg,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0 }}>
                    <Icon name={card.icon} size={17} />
                  </div>
                  <div style={{ minWidth:0 }}>
                    <p style={{ margin:0,fontSize:13,fontWeight:700,color:'var(--color-text-primary)' }}>{card.v}</p>
                    <p style={{ margin:0,fontSize:11,color:'var(--color-text-secondary)',overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap' }}>{card.sub}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </RowCard>
  );
}

// ─── Column Headers ────────────────────────────────────────────────────────────
function ReadinessHeaders() {
  return (
    <div style={{ display:'grid',gridTemplateColumns:'40px 76px minmax(180px,1fr) 90px 140px 36px 36px 36px 36px 36px 36px 130px',gap:8,padding:'8px 16px',background:'var(--color-bg-surface)',border:'1px solid var(--color-border)',borderRadius:12,boxShadow:'0 1px 2px 0 rgba(0,0,0,.05)',position:'sticky',top:120,zIndex:10 }}>
      {[
        { label:'', w:'' },
        { label:'ID', w:'' },
        { label:'Title & Tags', w:'' },
        { label:'Type', w:'' },
        { label:'Parent State', w:'' },
        { label:'Appr*', color:'var(--color-primary)' },
        { label:'Dev', dim:true },
        { label:'QA', dim:true },
        { label:'UAT*', color:'var(--color-primary)' },
        { label:'Post', dim:true },
        { label:'Link*', color:'var(--color-primary)' },
        { label:'Readiness', align:'right' },
      ].map((col,i) => (
        <div key={i} style={{ fontSize:10,fontWeight:700,letterSpacing:'0.05em',textTransform:'uppercase',color:col.color||'var(--color-text-secondary)',opacity:col.dim?.7:1,textAlign:col.align||'left' }}>
          {col.label}
        </div>
      ))}
    </div>
  );
}

// ─── ReadinessTrackerPage ──────────────────────────────────────────────────────
function ReadinessTrackerPage({ sprintName, onNavigate }) {
  const data = window.SPRINTOPS_DATA;
  const toast = useToast();
  const [activeTab, setActiveTab] = React.useState('All');
  const [hideClosed, setHideClosed] = React.useState(false);
  const [filterState, setFilterState] = React.useState([]);
  const [filterType, setFilterType] = React.useState([]);
  const [rows, setRows] = React.useState(() => data.readiness);

  const closedStates = new Set(['Ready for Production','Production Deployed','Closed']);
  const allStates = [...new Set(rows.map(r => r.state))].sort();
  const allTypes = [...new Set(rows.map(r => r.type))].sort();

  const tabs = data.tabs.map(t => ({ id:t, label:t, count: rows.filter(r => t==='All'||r.visibleTabs.includes(t)).length }));

  const filtered = rows.filter(r => {
    if (activeTab !== 'All' && !r.visibleTabs.includes(activeTab)) return false;
    if (hideClosed && closedStates.has(r.state)) return false;
    if (filterState.length > 0 && !filterState.includes(r.state)) return false;
    if (filterType.length > 0 && !filterType.includes(r.type)) return false;
    return true;
  });

  const updateRow = (id, updater) => setRows(prev => prev.map(r => {
    if (r.id !== id) return r;
    const updated = updater(r);
    return { ...updated, readiness: data.computeReadiness(updated) };
  }));

  const handleAction = (kind, payload) => {
    if (kind === 'approve') {
      updateRow(payload, r => ({ ...r, approvalStatus: 'approved' }));
      toast.push('Work item approved successfully', 'success');
    } else if (kind === 'createTask') {
      const { id, slot } = payload;
      updateRow(id, r => ({ ...r, tasks: { ...r.tasks, [slot]: { ...r.tasks[slot], actionState:'creating' } } }));
      setTimeout(() => {
        updateRow(id, r => ({ ...r, tasks: { ...r.tasks, [slot]: { id: 90000+Math.floor(Math.random()*999), actionState:'created', adoState:'New' } } }));
        toast.push(`${slot} task created successfully`, 'success');
      }, 1200);
    } else if (kind === 'linkTask') {
      const { id, slot } = payload;
      toast.push(`Link Existing for ${slot} — enter work item ID in Configuration`, 'info');
    } else if (kind === 'createLink') {
      updateRow(payload, r => ({ ...r, link: { ...r.link, actionState:'creating' } }));
      setTimeout(() => {
        updateRow(payload, r => ({ ...r, link: { actionState:'created', url:'https://release.pipeline/'+payload } }));
        toast.push('Deployment link created', 'success');
      }, 1000);
    }
  };

  return (
    <div>
      <PageHeader title="Readiness Tracker"
        description={`Showing live data for iteration: ${sprintName}.`}
        actions={
          <Button variant="secondary" icon="refresh-cw" onClick={() => toast.push('Sprint data refreshed', 'info')}>Refresh Data</Button>
        } />

      <SecondaryTabBar tabs={tabs} active={activeTab} onChange={setActiveTab} />

      {/* Filters */}
      <div style={{ display:'flex',alignItems:'center',gap:8,marginBottom:24,flexWrap:'wrap' }}>
        <div style={{ display:'inline-flex',alignItems:'center',gap:4,background:'var(--color-bg-surface)',padding:6,borderRadius:12,border:'1px solid var(--color-border)',boxShadow:'0 1px 2px 0 rgba(0,0,0,.05)' }}>
          <div style={{ padding:'0 6px',color:'var(--color-text-secondary)',display:'flex' }}><Icon name="filter" size={16} /></div>
          <MiniDropdown label="State" options={allStates} selected={filterState}
            onChange={(val,on) => setFilterState(p => on?[...p,val]:p.filter(x=>x!==val))}
            onClear={() => setFilterState([])} />
          <div style={{ width:1,height:16,background:'var(--color-border)',margin:'0 2px' }} />
          <MiniDropdown label="Type" options={allTypes} selected={filterType}
            onChange={(val,on) => setFilterType(p => on?[...p,val]:p.filter(x=>x!==val))}
            onClear={() => setFilterType([])} />
          <div style={{ width:1,height:16,background:'var(--color-border)',margin:'0 2px' }} />
          <HideClosedBtn active={hideClosed} onClick={() => setHideClosed(h => !h)} />
        </div>
      </div>

      {/* Table */}
      <div style={{ display:'flex',flexDirection:'column',gap:10 }}>
        <div style={{ fontSize:13,fontWeight:500,color:'var(--color-text-secondary)',padding:'0 4px' }}>
          Showing {filtered.length} item{filtered.length!==1?'s':''}
        </div>
        <ReadinessHeaders />
        {filtered.length > 0
          ? filtered.map(item => <ReadinessRow key={item.id} item={item} onAction={handleAction} />)
          : <EmptyState icon="filter" title="No items found" body="No items found matching current filters." />
        }
      </div>
    </div>
  );
}

// ─── Filter helpers ───────────────────────────────────────────────────────────
function HideClosedBtn({ active, onClick }) {
  const [hov, setHov] = React.useState(false);
  return (
    <button onClick={onClick} onMouseEnter={() => setHov(true)} onMouseLeave={() => setHov(false)}
      style={{ fontSize:13,padding:'6px 10px',borderRadius:6,background:active?'color-mix(in srgb,var(--color-primary) 7%,transparent)':'transparent',border:`1px solid ${active||hov?'color-mix(in srgb,var(--color-primary) 30%,transparent)':'transparent'}`,color:active?'var(--color-primary)':'var(--color-text-primary)',fontWeight:active?500:400,cursor:'pointer',fontFamily:'inherit',transition:'all .15s' }}>
      Hide Closed
    </button>
  );
}

function MiniDropdown({ label, options, selected, onChange, onClear }) {
  const [open, setOpen] = React.useState(false);
  const [coords, setCoords] = React.useState({ top:0,left:0 });
  const ref = React.useRef(null);
  const menuRef = React.useRef(null);

  const updateCoords = React.useCallback(() => {
    if (ref.current) {
      const r = ref.current.getBoundingClientRect();
      setCoords({ top: r.bottom+4, left: r.left });
    }
  }, []);

  React.useEffect(() => {
    if (!open) return;
    updateCoords();
    const onDown = e => {
      if (menuRef.current&&!menuRef.current.contains(e.target)&&ref.current&&!ref.current.contains(e.target)) setOpen(false);
    };
    document.addEventListener('mousedown', onDown);
    return () => document.removeEventListener('mousedown', onDown);
  }, [open, updateCoords]);

  const summary = selected.length===0 ? `All ${label}s` : selected.length===1 ? selected[0] : `${selected.length} ${label}s`;
  const isActive = selected.length > 0;

  return (
    <>
      <button ref={ref} onClick={() => { setOpen(o=>!o); updateCoords(); }}
        style={{ fontSize:13,padding:'6px 10px',borderRadius:6,background:isActive||open?'color-mix(in srgb,var(--color-primary) 7%,transparent)':'transparent',border:`1px solid ${isActive||open?'color-mix(in srgb,var(--color-primary) 30%,transparent)':'transparent'}`,color:isActive||open?'var(--color-primary)':'var(--color-text-primary)',fontWeight:isActive?500:400,cursor:'pointer',fontFamily:'inherit',display:'inline-flex',alignItems:'center',gap:5,transition:'all .15s' }}>
        <span style={{ maxWidth:100,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap' }}>{summary}</span>
        <Icon name="chevron-down" size={13} style={{ color:'var(--color-text-secondary)',transition:'transform .15s',transform:open?'rotate(180deg)':'none' }} />
      </button>
      {open && ReactDOM.createPortal(
        <div ref={menuRef} style={{ position:'fixed',top:coords.top,left:coords.left,minWidth:200,zIndex:9999,background:'var(--color-bg-surface)',border:'1px solid var(--color-border)',borderRadius:12,padding:'4px 0',boxShadow:'0 10px 15px -3px rgba(0,0,0,.1),0 4px 6px -2px rgba(0,0,0,.06)' }}>
          <div style={{ padding:'6px 12px',borderBottom:'1px solid var(--color-border)',marginBottom:4,display:'flex',justifyContent:'space-between',alignItems:'center' }}>
            <Eyebrow>{label}</Eyebrow>
            <button onClick={() => { onClear(); setOpen(false); }} disabled={selected.length===0}
              style={{ fontSize:11,fontWeight:500,color:'var(--color-primary)',border:'none',background:'transparent',cursor:selected.length===0?'not-allowed':'pointer',opacity:selected.length===0?.5:1,fontFamily:'inherit' }}>Clear</button>
          </div>
          <div style={{ maxHeight:220,overflowY:'auto',padding:'4px 0' }}>
            {options.map(opt => {
              const on = selected.includes(opt);
              return (
                <button key={opt} onClick={() => onChange(opt,!on)}
                  style={{ width:'100%',display:'flex',alignItems:'center',gap:10,padding:'7px 12px',background:'transparent',border:'none',cursor:'pointer',textAlign:'left',fontFamily:'inherit',fontSize:13,color:'var(--color-text-primary)' }}>
                  <div style={{ width:16,height:16,borderRadius:4,border:`1px solid ${on?'var(--color-primary)':'var(--color-input-border)'}`,background:on?'var(--color-primary)':'var(--color-input-bg)',display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0 }}>
                    {on && <Icon name="check" size={11} strokeWidth={3} style={{ color:'white' }} />}
                  </div>
                  <span style={{ fontWeight:on?500:400 }}>{opt}</span>
                </button>
              );
            })}
          </div>
        </div>,
        document.body
      )}
    </>
  );
}

Object.assign(window, { TaskCell, ReadinessMeter, ReadinessRow, ReadinessTrackerPage });
