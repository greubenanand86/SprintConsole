/* SprintOps Console — Estimation Planner
   EstimationRow, EstimationPlannerPage
*/

const EST_FILTERS = ['None','Missing Original','Missing Remaining','Missing Completed','Missing Any','Overridden Only'];

// ─── EstimationRow ─────────────────────────────────────────────────────────────
function EstimationRow({ item, onUpdate }) {
  const toast = useToast();
  const [expanded, setExpanded] = React.useState(false);
  const [saving, setSaving] = React.useState(false);
  const [saveStatus, setSaveStatus] = React.useState('idle'); // idle | success | error

  const QA_PCT = 25;
  const UAT_PCT = 15;
  const ROUND = 0.5;

  const round = val => {
    if (val === '' || isNaN(val)) return val;
    return Math.round(val / ROUND) * ROUND;
  };

  const handleChange = (taskType, field, rawVal) => {
    const val = rawVal === '' ? '' : parseFloat(rawVal);
    const newTasks = { ...item.tasks };
    const updated = { ...newTasks[taskType], [field]: val };
    if (field === 'original' && taskType !== 'Dev') updated.isOverridden = true;
    if (taskType === 'Dev' && field === 'original') {
      if (!newTasks.QA.isOverridden) newTasks.QA = { ...newTasks.QA, original: val===''?'':round(val*(QA_PCT/100)) };
      if (!newTasks.UAT.isOverridden) newTasks.UAT = { ...newTasks.UAT, original: val===''?'':round(val*(UAT_PCT/100)) };
    }
    newTasks[taskType] = updated;
    onUpdate({ ...item, tasks: newTasks });
    setSaveStatus('idle');
  };

  const handleReset = taskType => {
    const devOrig = item.tasks.Dev.original;
    const resetVal = taskType==='QA' ? (devOrig===''?'':round(devOrig*(QA_PCT/100))) : (devOrig===''?'':round(devOrig*(UAT_PCT/100)));
    onUpdate({ ...item, tasks: { ...item.tasks, [taskType]: { ...item.tasks[taskType], original:resetVal, isOverridden:false } } });
    setSaveStatus('idle');
  };

  const handleSave = async () => {
    setSaving(true); setSaveStatus('idle');
    await new Promise(r => setTimeout(r, 900));
    setSaving(false); setSaveStatus('success');
    toast.push('Estimates saved successfully', 'success');
    setTimeout(() => setSaveStatus('idle'), 3000);
  };

  const totalOrig = ['Dev','QA','UAT'].reduce((s,t) => s + (Number(item.tasks[t].original)||0), 0);
  const totalRem  = ['Dev','QA','UAT'].reduce((s,t) => s + (Number(item.tasks[t].remaining)||0), 0);
  const c = statePill(item.state);
  const isBug = item.type === 'Bug';

  const inputStyle = { width:80,padding:'6px 8px',borderRadius:8,border:'1px solid var(--color-input-border)',background:'var(--color-input-bg)',color:'var(--color-input-text)',fontSize:13,fontFamily:'inherit',outline:'none',textAlign:'right',boxSizing:'border-box' };

  return (
    <RowCard>
      {/* Summary row */}
      <div onClick={() => setExpanded(x => !x)} style={{ display:'grid',gridTemplateColumns:'40px 76px minmax(180px,1fr) 90px 140px 100px 100px',alignItems:'center',gap:8,padding:'10px 16px',cursor:'pointer' }}>
        <div style={{ width:32,height:32,borderRadius:8,display:'flex',alignItems:'center',justifyContent:'center',color:'var(--color-text-secondary)' }}>
          <Icon name={expanded?'chevron-down':'chevron-right'} size={20} />
        </div>
        <a href="#" onClick={e => e.preventDefault()} style={{ display:'inline-flex',alignItems:'center',gap:4,fontSize:13,fontWeight:500,color:'var(--color-text-secondary)',textDecoration:'none' }}>
          #{item.id} <Icon name="external-link" size={11} style={{ opacity:.5 }} />
        </a>
        <div style={{ display:'flex',flexDirection:'column',gap:4,minWidth:0 }}>
          <span title={item.title} style={{ fontSize:13,fontWeight:600,color:'var(--color-text-primary)',overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap' }}>{item.title}</span>
          <div style={{ display:'flex',flexWrap:'wrap',gap:3 }}>
            {item.tags.map(t => <span key={t} style={{ fontSize:10,fontWeight:500,padding:'2px 6px',borderRadius:4,background:'var(--color-bg-base)',border:'1px solid var(--color-border)',color:'var(--color-text-secondary)' }}>{t}</span>)}
          </div>
        </div>
        <div style={{ display:'flex',alignItems:'center',gap:5,fontSize:12,fontWeight:500,color:'var(--color-text-secondary)' }}>
          <Icon name={isBug?'bug':'file-text'} size={14} style={{ color:isBug?'var(--color-danger)':'var(--color-primary)' }} />
          {item.type}
        </div>
        <div><StatePill state={item.state} /></div>
        <div style={{ textAlign:'right' }}>
          <Eyebrow style={{ display:'block' }}>Total Orig</Eyebrow>
          <span style={{ fontSize:14,fontWeight:700,color:'var(--color-text-primary)' }}>{totalOrig}</span>
        </div>
        <div style={{ textAlign:'right' }}>
          <Eyebrow style={{ display:'block' }}>Total Rem</Eyebrow>
          <span style={{ fontSize:14,fontWeight:700,color:'var(--color-primary)' }}>{totalRem}</span>
        </div>
      </div>

      {/* Expanded edit panel */}
      {expanded && (
        <div style={{ background:'color-mix(in srgb,var(--color-bg-muted) 35%,transparent)',borderTop:'1px solid var(--color-border)',padding:'16px 56px 20px' }}>
          <div style={{ overflowX:'auto' }}>
            <table style={{ width:'100%',borderCollapse:'collapse',minWidth:520 }}>
              <thead>
                <tr style={{ borderBottom:'1px solid var(--color-border)' }}>
                  {['Task Type','Original Est.','Remaining','Completed','Auto-Calc'].map(h => (
                    <th key={h} style={{ padding:'0 8px 10px',textAlign:h==='Task Type'?'left':'right',fontSize:10,fontWeight:700,letterSpacing:'0.05em',textTransform:'uppercase',color:'var(--color-text-secondary)' }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {['Dev','QA','UAT'].map(taskType => {
                  const task = item.tasks[taskType];
                  const noId = !task.id;
                  return (
                    <tr key={taskType} style={{ borderBottom:'1px solid var(--color-border-muted)' }}>
                      <td style={{ padding:'10px 8px',fontSize:13,fontWeight:600,color:'var(--color-text-primary)' }}>
                        {taskType} Task
                        {task.id && <span style={{ fontSize:11,fontWeight:400,color:'var(--color-text-secondary)',marginLeft:6 }}>#{task.id}</span>}
                        {noId && <span style={{ fontSize:10,fontWeight:500,color:'var(--color-warning-fg)',background:'var(--color-warning-bg)',padding:'2px 6px',borderRadius:4,marginLeft:6,border:'1px solid color-mix(in srgb,var(--color-warning) 20%,transparent)' }}>No task</span>}
                      </td>
                      {['original','remaining','completed'].map(field => (
                        <td key={field} style={{ padding:'10px 8px',textAlign:'right' }}>
                          <input type="number" step={0.5} min={0} disabled={noId||saving}
                            value={task[field]===undefined?'':task[field]}
                            onChange={e => handleChange(taskType, field, e.target.value)}
                            onFocus={e => e.target.style.borderColor='var(--color-primary)'}
                            onBlur={e => e.target.style.borderColor='var(--color-input-border)'}
                            style={{ ...inputStyle, opacity:noId?.5:1, cursor:noId?'not-allowed':'text' }} />
                        </td>
                      ))}
                      <td style={{ padding:'10px 8px',textAlign:'right' }}>
                        {taskType === 'Dev'
                          ? <span style={{ fontSize:11,color:'var(--color-text-muted)',fontStyle:'italic' }}>Source</span>
                          : task.isOverridden
                            ? <button onClick={() => handleReset(taskType)} style={{ fontSize:11,fontWeight:500,color:'var(--color-warning-fg)',background:'var(--color-warning-bg)',border:'1px solid color-mix(in srgb,var(--color-warning) 20%,transparent)',padding:'3px 8px',borderRadius:6,cursor:'pointer',fontFamily:'inherit' }}>Reset</button>
                            : <span style={{ fontSize:11,fontWeight:600,color:'var(--color-success-fg)',background:'var(--color-success-bg)',padding:'3px 8px',borderRadius:6,border:'1px solid color-mix(in srgb,var(--color-success) 20%,transparent)' }}>Auto</span>
                        }
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          {/* Save row */}
          <div style={{ marginTop:16,paddingTop:16,borderTop:'1px solid var(--color-border)',display:'flex',alignItems:'center',justifyContent:'flex-end',gap:12 }}>
            {saveStatus==='success' && (
              <div style={{ display:'inline-flex',alignItems:'center',gap:6,fontSize:12,fontWeight:500,color:'var(--color-success-fg)',background:'var(--color-success-bg)',padding:'6px 12px',borderRadius:8,border:'1px solid color-mix(in srgb,var(--color-success) 20%,transparent)' }}>
                <Icon name="check-circle-2" size={14} /> Saved to ADO
              </div>
            )}
            {saveStatus==='error' && (
              <div style={{ display:'inline-flex',alignItems:'center',gap:6,fontSize:12,color:'var(--color-danger-fg)',background:'var(--color-danger-bg)',padding:'6px 12px',borderRadius:8 }}>
                <Icon name="alert-circle" size={14} /> Save failed
              </div>
            )}
            <Button variant="primary" icon="save" busy={saving} onClick={handleSave}>Save Estimates</Button>
          </div>
        </div>
      )}
    </RowCard>
  );
}

// ─── EstimationPlannerPage ─────────────────────────────────────────────────────
function EstimationPlannerPage({ sprintName }) {
  const data = window.SPRINTOPS_DATA;
  const toast = useToast();
  const [activeTab, setActiveTab] = React.useState('All');
  const [activeFilter, setActiveFilter] = React.useState('None');
  const [rows, setRows] = React.useState(() => data.estimation);

  const tabs = data.tabs.map(t => ({ id:t, label:t, count: rows.filter(r => t==='All'||r.visibleTabs.includes(t)).length }));

  const filtered = rows.filter(r => {
    if (activeTab !== 'All' && !r.visibleTabs.includes(activeTab)) return false;
    const tasks = Object.values(r.tasks);
    switch (activeFilter) {
      case 'Missing Original': return tasks.some(t => t.original === '');
      case 'Missing Remaining': return tasks.some(t => t.remaining === '');
      case 'Missing Completed': return tasks.some(t => t.completed === '');
      case 'Missing Any': return tasks.some(t => t.original===''||t.remaining===''||t.completed==='');
      case 'Overridden Only': return tasks.some(t => t.isOverridden);
      default: return true;
    }
  });

  return (
    <div>
      <PageHeader title="Estimation Planner"
        description={`Plan Dev, QA and UAT hours for: ${sprintName}.`}
        actions={<Button variant="secondary" icon="refresh-cw" onClick={() => toast.push('Estimation data refreshed', 'info')}>Refresh Data</Button>} />

      <SecondaryTabBar tabs={tabs} active={activeTab} onChange={setActiveTab} />

      {/* Filters */}
      <div style={{ display:'flex',alignItems:'center',gap:12,marginBottom:24,flexWrap:'wrap' }}>
        <div style={{ display:'inline-flex',alignItems:'center',gap:6 }}>
          <Icon name="sliders-horizontal" size={16} style={{ color:'var(--color-text-secondary)' }} />
          <span style={{ fontSize:13,fontWeight:500,color:'var(--color-text-primary)' }}>Filter Estimations:</span>
        </div>
        <div style={{ display:'flex',flexWrap:'wrap',gap:6 }}>
          {EST_FILTERS.map(f => (
            <button key={f} onClick={() => setActiveFilter(f)}
              style={{ padding:'5px 12px',fontSize:12,fontWeight:500,borderRadius:8,border:`1px solid ${activeFilter===f?'var(--color-primary)':'var(--color-border)'}`,background:activeFilter===f?'var(--color-primary)':'var(--color-bg-surface)',color:activeFilter===f?'var(--color-primary-fg)':'var(--color-text-secondary)',cursor:'pointer',fontFamily:'inherit',boxShadow:activeFilter===f?'0 1px 2px 0 rgba(0,0,0,.05)':'none',transition:'all .15s' }}>{f}</button>
          ))}
        </div>
      </div>

      {/* Column headers */}
      <div style={{ display:'grid',gridTemplateColumns:'40px 76px minmax(180px,1fr) 90px 140px 100px 100px',gap:8,padding:'8px 16px',background:'var(--color-bg-surface)',border:'1px solid var(--color-border)',borderRadius:12,boxShadow:'0 1px 2px 0 rgba(0,0,0,.05)',position:'sticky',top:120,zIndex:10,marginBottom:10 }}>
        {['','ID','Title & Tags','Type','State','Total Orig','Total Rem'].map((h,i) => (
          <div key={i} style={{ fontSize:10,fontWeight:700,letterSpacing:'0.05em',textTransform:'uppercase',color:'var(--color-text-secondary)',textAlign:i>=5?'right':'left' }}>{h}</div>
        ))}
      </div>

      <div style={{ display:'flex',flexDirection:'column',gap:10 }}>
        <div style={{ fontSize:13,fontWeight:500,color:'var(--color-text-secondary)',padding:'0 4px' }}>
          Showing {filtered.length} item{filtered.length!==1?'s':''}
        </div>
        {filtered.length > 0
          ? filtered.map(item => (
              <EstimationRow key={item.id} item={item}
                onUpdate={next => setRows(prev => prev.map(r => r.id===next.id?next:r))} />
            ))
          : <EmptyState icon="sliders-horizontal" title="No items found" body="No items match the current tab and filter criteria." />
        }
      </div>
    </div>
  );
}

Object.assign(window, { EstimationRow, EstimationPlannerPage });
