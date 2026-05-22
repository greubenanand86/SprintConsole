/* SprintOps Console — Release Readiness
   ReleaseTaskCard, ReleaseReadinessPage
*/

const PRODUCT_COLORS = {
  LW:   { bg: 'color-mix(in srgb,var(--color-primary) 12%,transparent)', fg: 'var(--color-primary)',    border: 'color-mix(in srgb,var(--color-primary) 20%,transparent)' },
  ED:   { bg: 'color-mix(in srgb,var(--color-warning) 12%,transparent)', fg: 'var(--color-warning-fg)', border: 'color-mix(in srgb,var(--color-warning) 20%,transparent)' },
  NCSI: { bg: 'color-mix(in srgb,var(--color-success) 12%,transparent)', fg: 'var(--color-success-fg)', border: 'color-mix(in srgb,var(--color-success) 20%,transparent)' },
  DEFAULT: { bg: 'var(--color-bg-muted)', fg: 'var(--color-text-secondary)', border: 'var(--color-border)' }
};

function ProductBadge({ product }) {
  const c = PRODUCT_COLORS[product] || PRODUCT_COLORS.DEFAULT;
  return (
    <span style={{ fontSize:11,fontWeight:700,padding:'3px 8px',borderRadius:6,background:c.bg,color:c.fg,border:`1px solid ${c.border}`,letterSpacing:'0.03em' }}>{product}</span>
  );
}

function TypeBadge({ type }) {
  const isHotfix = type === 'Hotfix';
  return (
    <span style={{ fontSize:11,fontWeight:600,padding:'3px 8px',borderRadius:6,background:isHotfix?'var(--color-danger-bg)':'var(--color-secondary)',color:isHotfix?'var(--color-danger-fg)':'var(--color-secondary-fg)',border:`1px solid ${isHotfix?'color-mix(in srgb,var(--color-danger) 20%,transparent)':'var(--color-border)'}` }}>{type}</span>
  );
}

// ─── ReleaseTaskCard ──────────────────────────────────────────────────────────
function ReleaseTaskCard({ task, onAction }) {
  const [expanded, setExpanded] = React.useState(false);
  const [genBusy, setGenBusy] = React.useState(false);
  const [genDone, setGenDone] = React.useState(task.descriptionSynced);
  const [postBusy, setPostBusy] = React.useState(false);
  const [postTask, setPostTask] = React.useState(task.postDepTask);
  const toast = useToast();

  const readyCount = task.linkedItems.filter(i => i.state === 'Ready for Production').length;
  const total = task.linkedItems.length;
  const allReady = readyCount === total;
  const c = statePill(task.state);

  const handleGenerateScope = async () => {
    setGenBusy(true);
    await new Promise(r => setTimeout(r, 1400));
    setGenBusy(false);
    setGenDone(true);
    toast.push('Scope generated and synced to ADO Description', 'success');
  };

  const handleCreatePostDep = async () => {
    setPostBusy(true);
    await new Promise(r => setTimeout(r, 1100));
    setPostBusy(false);
    setPostTask({ actionState: 'created', adoState: 'New' });
    toast.push('Post-deployment task created successfully', 'success');
  };

  const closureItem = (() => {
    if (postTask.actionState === 'created') {
      if (postTask.adoState === 'Closed') return { icon:'check-circle-2', label:'Post-Deploy Closed', color:'var(--color-success-fg)', bg:'var(--color-success-bg)', border:'color-mix(in srgb,var(--color-success) 20%,transparent)' };
      return { icon:'clock', label:'Post-Deploy Open', color:'var(--color-info-fg)', bg:'var(--color-info-bg)', border:'color-mix(in srgb,var(--color-info) 20%,transparent)' };
    }
    return { icon:'alert-circle', label:'No Post-Deploy Task', color:'var(--color-warning-fg)', bg:'var(--color-warning-bg)', border:'color-mix(in srgb,var(--color-warning) 20%,transparent)' };
  })();

  return (
    <RowCard>
      {/* Header row */}
      <div style={{ padding:'14px 16px' }}>
        <div style={{ display:'flex',alignItems:'flex-start',gap:12 }}>
          <button onClick={() => setExpanded(x => !x)}
            style={{ width:32,height:32,borderRadius:8,border:'none',background:'transparent',cursor:'pointer',color:'var(--color-text-secondary)',display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0,marginTop:2 }}>
            <Icon name={expanded?'chevron-down':'chevron-right'} size={20} />
          </button>

          <div style={{ flex:1,minWidth:0 }}>
            {/* Title + badges */}
            <div style={{ display:'flex',alignItems:'center',gap:8,flexWrap:'wrap',marginBottom:8 }}>
              <ProductBadge product={task.product} />
              <TypeBadge type={task.releaseType} />
              <span style={{ fontSize:12,fontWeight:600,color:'var(--color-text-muted)',fontFamily:'var(--font-mono)' }}>v{task.version}</span>
              <StatePill state={task.state} />
            </div>
            <h3 style={{ margin:'0 0 8px',fontSize:14,fontWeight:600,color:'var(--color-text-primary)',overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap' }}
              title={task.title}>{task.title}</h3>

            {/* Meta row */}
            <div style={{ display:'flex',alignItems:'center',gap:12,flexWrap:'wrap' }}>
              {/* Linked items readiness */}
              <div style={{ display:'inline-flex',alignItems:'center',gap:6,fontSize:12,color:allReady?'var(--color-success-fg)':'var(--color-text-secondary)' }}>
                <Icon name={allReady?'check-circle-2':'circle'} size={14} style={{ color:allReady?'var(--color-success)':'var(--color-text-muted)' }} />
                <span><strong style={{ color:'var(--color-text-primary)' }}>{readyCount}/{total}</strong> items ready</span>
              </div>

              {/* Description sync */}
              <div style={{ display:'inline-flex',alignItems:'center',gap:6,fontSize:12,color:genDone?'var(--color-success-fg)':'var(--color-warning-fg)' }}>
                <Icon name={genDone?'file-check':'file-x'} size={14} />
                <span>{genDone?'Scope synced':'Scope not generated'}</span>
              </div>

              {/* Post-deploy status */}
              <div style={{ display:'inline-flex',alignItems:'center',gap:6,fontSize:12,color:closureItem.color }}>
                <Icon name={closureItem.icon} size={14} />
                {closureItem.label}
              </div>
            </div>
          </div>

          {/* Actions */}
          <div style={{ display:'flex',flexDirection:'column',gap:8,flexShrink:0,alignItems:'flex-end' }}>
            <Button variant="secondary" size="sm" icon={genDone?'refresh-cw':'file-text'} busy={genBusy} onClick={handleGenerateScope}>
              {genDone ? 'Re-generate Scope' : 'Generate Scope'}
            </Button>
            {postTask.actionState !== 'created' && (
              <Button variant="ghost" size="sm" icon="plus" busy={postBusy} onClick={handleCreatePostDep}>Create Post-Deploy</Button>
            )}
          </div>
        </div>
      </div>

      {/* Expanded: linked items */}
      {expanded && (
        <div style={{ background:'color-mix(in srgb,var(--color-bg-muted) 35%,transparent)',borderTop:'1px solid var(--color-border)',padding:'16px 56px 20px' }}>
          <Eyebrow style={{ display:'block',marginBottom:12 }}>Linked Work Items</Eyebrow>
          <div style={{ display:'flex',flexDirection:'column',gap:6 }}>
            {task.linkedItems.map(li => {
              const sc = statePill(li.state);
              const isBug = li.type === 'Bug';
              return (
                <div key={li.id} style={{ display:'flex',alignItems:'center',gap:10,padding:'10px 14px',background:'var(--color-bg-surface)',border:'1px solid var(--color-border)',borderRadius:10 }}>
                  <Icon name={isBug?'bug':'file-text'} size={15} style={{ color:isBug?'var(--color-danger)':'var(--color-primary)',flexShrink:0 }} />
                  <a href="#" onClick={e=>e.preventDefault()} style={{ fontSize:12,fontWeight:500,color:'var(--color-text-secondary)',textDecoration:'none',flexShrink:0 }}>#{li.id}</a>
                  <span style={{ fontSize:13,fontWeight:500,color:'var(--color-text-primary)',flex:1,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap' }}>{li.title}</span>
                  <StatePill state={li.state} />
                  {li.state==='Ready for Production' && <Icon name="check-circle-2" size={16} style={{ color:'var(--color-success)',flexShrink:0 }} />}
                </div>
              );
            })}
          </div>

          {/* Post-deploy task info */}
          {postTask.actionState === 'created' && (
            <div style={{ marginTop:16,padding:'12px 14px',background:'var(--color-bg-surface)',border:'1px solid var(--color-border)',borderRadius:10,display:'flex',alignItems:'center',gap:10 }}>
              <div style={{ width:28,height:28,borderRadius:6,background:closureItem.bg,color:closureItem.color,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0,border:`1px solid ${closureItem.border}` }}>
                <Icon name="rocket" size={14} />
              </div>
              <div>
                <Eyebrow style={{ display:'block' }}>Post-Deployment Task</Eyebrow>
                <span style={{ fontSize:13,fontWeight:500,color:'var(--color-text-primary)' }}>State: <strong>{postTask.adoState}</strong></span>
              </div>
            </div>
          )}
        </div>
      )}
    </RowCard>
  );
}

// ─── ReleaseReadinessPage ──────────────────────────────────────────────────────
function ReleaseReadinessPage({ sprintName, onNavigate }) {
  const data = window.SPRINTOPS_DATA;
  const toast = useToast();
  const [releases, setReleases] = React.useState(() => data.releases);

  const readyCount = releases.filter(r => r.state === 'Ready for Production').length;
  const total = releases.length;

  return (
    <div>
      <PageHeader title="Release Readiness"
        description={`Review release tasks and production readiness for: ${sprintName}.`}
        actions={
          <div style={{ display:'flex',gap:8 }}>
            <Button variant="secondary" icon="refresh-cw" onClick={() => toast.push('Release data refreshed', 'info')}>Refresh Data</Button>
            <Button variant="primary" icon="plus" onClick={() => toast.push('Create Release — configure in ADO', 'info')}>New Release</Button>
          </div>
        } />

      {/* Summary bar */}
      <div style={{ display:'flex',gap:12,marginBottom:24,flexWrap:'wrap' }}>
        {[
          { label:'Total Releases', value:total, icon:'rocket', color:'var(--color-primary)', bg:'var(--color-info-bg)' },
          { label:'Ready for Production', value:readyCount, icon:'check-circle-2', color:'var(--color-success)', bg:'var(--color-success-bg)' },
          { label:'In Progress', value:releases.filter(r=>r.state==='Active').length, icon:'clock', color:'var(--color-warning-fg)', bg:'var(--color-warning-bg)' },
          { label:'Hotfixes', value:releases.filter(r=>r.releaseType==='Hotfix').length, icon:'zap', color:'var(--color-danger-fg)', bg:'var(--color-danger-bg)' },
        ].map(stat => (
          <div key={stat.label} style={{ display:'flex',alignItems:'center',gap:12,padding:'12px 16px',background:'var(--color-bg-surface)',border:'1px solid var(--color-border)',borderRadius:12,boxShadow:'0 1px 2px 0 rgba(0,0,0,.05)',flex:'1 1 140px' }}>
            <div style={{ width:36,height:36,borderRadius:8,background:stat.bg,color:stat.color,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0 }}>
              <Icon name={stat.icon} size={18} />
            </div>
            <div>
              <div style={{ fontSize:22,fontWeight:700,color:'var(--color-text-primary)',lineHeight:1 }}>{stat.value}</div>
              <div style={{ fontSize:11,color:'var(--color-text-secondary)',marginTop:2 }}>{stat.label}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Release task list */}
      <div style={{ display:'flex',flexDirection:'column',gap:12 }}>
        <div style={{ fontSize:13,fontWeight:500,color:'var(--color-text-secondary)',padding:'0 4px' }}>
          {releases.length} release task{releases.length!==1?'s':''} in {sprintName}
        </div>
        {releases.map(task => (
          <ReleaseTaskCard key={task.id} task={task} />
        ))}
      </div>
    </div>
  );
}

Object.assign(window, { ReleaseTaskCard, ReleaseReadinessPage });
