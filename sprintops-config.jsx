/* SprintOps Console — Configuration Page
   All config accordion sections + ConfigurationPage
*/

const DEFAULT_CONFIG = {
  ado: { orgUrl:'https://dev.azure.com/my-org/', project:'MyProject', team:'Performer' },
  iteration: { defaultCurrent:true, allowManual:true, selectedPath:'Performer\\Sprint 1' },
  mapping: {
    state:'System.State', tags:'System.Tags', iterationPath:'System.IterationPath',
    effort:'Microsoft.VSTS.Scheduling.Effort',
    originalEstimate:'Microsoft.VSTS.Scheduling.OriginalEstimate',
    remaining:'Microsoft.VSTS.Scheduling.RemainingWork',
    completed:'Microsoft.VSTS.Scheduling.CompletedWork'
  },
  tasks: {
    devPattern:'Dev task for <parent ID> - <parent title>',
    qaPattern:'QA task for <parent ID> - <parent title>',
    uatPattern:'UAT task for <parent ID> - <parent title>',
    postPattern:'Post-Deploy task for <parent ID> - <parent title>',
    inheritIteration:true, inheritArea:true
  },
  readiness: { requireUAT:true, requireLink:true, requireApproval:true, requireParentState:true },
  estimation: { qaPercentOfDev:25, uatPercentOfDev:15, roundToNearest:0.5 },
  grouping: { tagField:'System.Tags', productTags:['Learner Wallet','Edlusion','NCSI'] }
};

const MOCK_ITERATIONS = [
  { path:'Performer\\Sprint 1', name:'Sprint 1', timeFrame:'current' },
  { path:'Performer\\Sprint 2', name:'Sprint 2', timeFrame:'future' },
  { path:'Performer\\Sprint 3', name:'Sprint 3', timeFrame:'future' },
];

// ─── Session Review Panel ─────────────────────────────────────────────────────
function SessionReviewPanel({ config, connection, isDirty, onSave, onReset, onTest, saveStatus }) {
  const sections = [
    { label:'ADO Connection',     ok: connection==='success' },
    { label:'Iteration',          ok: !!config.iteration.selectedPath },
    { label:'Field Mapping',      ok: !!config.mapping.state },
    { label:'Task Rules',         ok: !!config.tasks.devPattern },
    { label:'Readiness Rules',    ok: true },
    { label:'Estimation Rules',   ok: true },
  ];
  const metCount = sections.filter(s => s.ok).length;
  const pct = Math.round((metCount/sections.length)*100);

  return (
    <SectionCard title="Session Review">
      <div style={{ display:'flex',flexDirection:'column',gap:16 }}>
        {/* Completeness bar */}
        <div>
          <div style={{ display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:8 }}>
            <Eyebrow>Completeness</Eyebrow>
            <span style={{ fontSize:12,fontWeight:700,color:pct===100?'var(--color-success)':'var(--color-text-primary)' }}>{pct}%</span>
          </div>
          <div style={{ height:8,background:'var(--color-progress-track)',borderRadius:9999,overflow:'hidden' }}>
            <div style={{ width:`${pct}%`,height:'100%',background:pct===100?'var(--color-success)':'var(--color-progress-fill)',borderRadius:9999,transition:'width .4s' }} />
          </div>
        </div>

        {/* Section checks */}
        <div style={{ display:'flex',flexDirection:'column',gap:8 }}>
          {sections.map(s => (
            <div key={s.label} style={{ display:'flex',alignItems:'center',justifyContent:'space-between',fontSize:13 }}>
              <span style={{ color:'var(--color-text-secondary)' }}>{s.label}</span>
              <Icon name={s.ok?'check-circle-2':'help-circle'} size={15}
                style={{ color:s.ok?'var(--color-success)':'var(--color-warning-fg)' }} />
            </div>
          ))}
        </div>

        {isDirty && (
          <div style={{ display:'flex',alignItems:'center',gap:6,padding:'8px 10px',borderRadius:8,background:'var(--color-warning-bg)',border:'1px solid color-mix(in srgb,var(--color-warning) 20%,transparent)',fontSize:12,color:'var(--color-warning-fg)' }}>
            <Icon name="alert-circle" size={14} />
            Unsaved changes
          </div>
        )}
        {saveStatus==='success' && (
          <div style={{ display:'flex',alignItems:'center',gap:6,padding:'8px 10px',borderRadius:8,background:'var(--color-success-bg)',border:'1px solid color-mix(in srgb,var(--color-success) 20%,transparent)',fontSize:12,color:'var(--color-success-fg)' }}>
            <Icon name="check-circle-2" size={14} />
            Configuration saved to session
          </div>
        )}

        <div style={{ display:'flex',flexDirection:'column',gap:8,paddingTop:4 }}>
          <Button variant="primary" icon="save" onClick={onSave} style={{ width:'100%',justifyContent:'center' }}>Save Configuration</Button>
          <Button variant="ghost" icon="rotate-ccw" onClick={onReset} style={{ width:'100%',justifyContent:'center' }}>Reset to Defaults</Button>
        </div>
      </div>
    </SectionCard>
  );
}

// ─── ADO Connection Section ───────────────────────────────────────────────────
function AdoConnectionSection({ data, onChange, connection, onTest }) {
  return (
    <AccordionCard title="Azure DevOps Connection" icon="shield-check">
      <div style={{ display:'flex',flexDirection:'column',gap:20 }}>
        <div style={{ padding:20,background:'var(--color-bg-base)',border:'1px solid var(--color-border)',borderRadius:12,textAlign:'center' }}>
          <div style={{ width:56,height:56,borderRadius:9999,display:'flex',alignItems:'center',justifyContent:'center',margin:'0 auto 12px',border:`2px solid ${connection==='success'?'color-mix(in srgb,var(--color-success) 30%,transparent)':'var(--color-border)'}`,background:connection==='success'?'var(--color-success-bg)':'var(--color-bg-muted)',color:connection==='success'?'var(--color-success)':'var(--color-text-secondary)' }}>
            {connection==='testing'
              ? <Icon name="loader-2" size={28} className="spin" />
              : <Icon name="shield-check" size={28} />
            }
          </div>
          <h3 style={{ margin:'0 0 6px',fontSize:14,fontWeight:600,color:'var(--color-text-primary)' }}>
            {connection==='success'?'ADO Connection Active':'Azure DevOps Configuration'}
          </h3>
          <p style={{ margin:'0 0 16px',fontSize:12,color:'var(--color-text-secondary)',maxWidth:320,marginLeft:'auto',marginRight:'auto' }}>
            SprintOps Console uses a server-side Personal Access Token (PAT) stored in Netlify environment variables.
          </p>
          <Button variant={connection==='success'?'success':'primary'} icon="refresh-cw" busy={connection==='testing'} onClick={onTest}>
            Test Server Connection
          </Button>
        </div>
        <div style={{ display:'grid',gridTemplateColumns:'1fr 1fr',gap:16 }}>
          <FormInput label="Organization URL" value={data.orgUrl} placeholder="https://dev.azure.com/org"
            onChange={e => onChange({...data,orgUrl:e.target.value})} helper="Full URL of your Azure DevOps organization." />
          <FormInput label="Project Name" value={data.project} placeholder="MyProject"
            onChange={e => onChange({...data,project:e.target.value})} helper="Project within the organization." />
          <FormInput label="Team Name" value={data.team} placeholder="MyTeam"
            onChange={e => onChange({...data,team:e.target.value})} helper="Team context for iterations and boards." />
          <FormInput label="PAT (server-side only)" type="password" value="••••••••••••••••"
            onChange={() => {}} helper="Stored in Netlify env vars. Never exposed to client." />
        </div>
      </div>
    </AccordionCard>
  );
}

// ─── Iteration Section ────────────────────────────────────────────────────────
function IterationSection({ data, onChange, disabled }) {
  return (
    <AccordionCard title="Iteration Settings" icon="calendar" disabled={disabled}>
      <div style={{ display:'flex',flexDirection:'column',gap:20 }}>
        <div style={{ display:'grid',gridTemplateColumns:'1fr 1fr',gap:16 }}>
          <FormToggle label="Default to Current Sprint" checked={data.defaultCurrent}
            onChange={v => onChange({...data,defaultCurrent:v})}
            helper="Automatically load the active sprint for the team." />
          <FormToggle label="Allow Manual Selection" checked={data.allowManual}
            onChange={v => onChange({...data,allowManual:v})}
            helper="Enable the sprint switcher in the top navigation bar." />
        </div>
        <FormSelect label="Selected Sprint Path" value={data.selectedPath}
          onChange={e => onChange({...data,selectedPath:e.target.value})}
          options={[{value:'',label:'Select a sprint\u2026'},...MOCK_ITERATIONS.map(i => ({value:i.path,label:`${i.name} (${i.timeFrame})`}))]}
          helper="Active iteration path used for all data queries." />
      </div>
    </AccordionCard>
  );
}

// ─── Field Mapping Section ────────────────────────────────────────────────────
function FieldMappingSection({ data, onChange, disabled }) {
  const fields = [
    { key:'state',           label:'State Field',         placeholder:'System.State' },
    { key:'tags',            label:'Tags Field',          placeholder:'System.Tags' },
    { key:'iterationPath',   label:'Iteration Path Field',placeholder:'System.IterationPath' },
    { key:'effort',          label:'Effort Field',        placeholder:'Microsoft.VSTS.Scheduling.Effort' },
    { key:'originalEstimate',label:'Original Estimate',   placeholder:'Microsoft.VSTS.Scheduling.OriginalEstimate' },
    { key:'remaining',       label:'Remaining Work',      placeholder:'Microsoft.VSTS.Scheduling.RemainingWork' },
    { key:'completed',       label:'Completed Work',      placeholder:'Microsoft.VSTS.Scheduling.CompletedWork' },
  ];
  return (
    <AccordionCard title="Field Mapping" icon="database" disabled={disabled}>
      <div style={{ display:'grid',gridTemplateColumns:'1fr 1fr',gap:16 }}>
        {fields.map(f => (
          <FormInput key={f.key} label={f.label} value={data[f.key]||''} placeholder={f.placeholder} monospace
            onChange={e => onChange({...data,[f.key]:e.target.value})}
            helper={`ADO reference name for ${f.label.toLowerCase()}.`} />
        ))}
      </div>
    </AccordionCard>
  );
}

// ─── Task Rules Section ───────────────────────────────────────────────────────
function TaskRulesSection({ data, onChange, disabled }) {
  return (
    <AccordionCard title="Task Rules" icon="list-checks" disabled={disabled}>
      <div style={{ display:'flex',flexDirection:'column',gap:20 }}>
        <div style={{ display:'grid',gridTemplateColumns:'1fr 1fr',gap:16 }}>
          {[
            { key:'devPattern',  label:'Dev Task Pattern' },
            { key:'qaPattern',   label:'QA Task Pattern' },
            { key:'uatPattern',  label:'UAT Task Pattern' },
            { key:'postPattern', label:'Post-Deploy Task Pattern' },
          ].map(f => (
            <FormInput key={f.key} label={f.label} value={data[f.key]||''} monospace
              onChange={e => onChange({...data,[f.key]:e.target.value})}
              helper="Use <parent ID> and <parent title> as placeholders." />
          ))}
        </div>
        <div style={{ display:'grid',gridTemplateColumns:'1fr 1fr',gap:16 }}>
          <FormToggle label="Inherit Iteration Path from Parent" checked={data.inheritIteration}
            onChange={v => onChange({...data,inheritIteration:v})}
            helper="New tasks adopt the parent's iteration path." />
          <FormToggle label="Inherit Area Path from Parent" checked={data.inheritArea}
            onChange={v => onChange({...data,inheritArea:v})}
            helper="New tasks adopt the parent's area path." />
        </div>
      </div>
    </AccordionCard>
  );
}

// ─── Readiness Rules Section ──────────────────────────────────────────────────
function ReadinessRulesSection({ data, onChange }) {
  return (
    <AccordionCard title="Readiness Rules" icon="shield" defaultOpen={false}>
      <div style={{ display:'flex',flexDirection:'column',gap:4 }}>
        <p style={{ margin:'0 0 12px',fontSize:13,color:'var(--color-text-secondary)' }}>Configure which gates are required for a work item to be considered release-ready.</p>
        <FormToggle label="Require Parent State = Ready for Production" checked={data.requireParentState}
          onChange={v => onChange({...data,requireParentState:v})} helper="Gate 1 — parent must be in the ready state." />
        <FormToggle label="Require UAT Task Closed" checked={data.requireUAT}
          onChange={v => onChange({...data,requireUAT:v})} helper="Gate 2 — UAT task must exist and be Closed." />
        <FormToggle label="Require Deployment Link" checked={data.requireLink}
          onChange={v => onChange({...data,requireLink:v})} helper="Gate 3 — a Related deployment link must be present." />
        <FormToggle label="Require Approval Comment" checked={data.requireApproval}
          onChange={v => onChange({...data,requireApproval:v})} helper="Gate 4 — a comment matching 'Approved' must exist." />
      </div>
    </AccordionCard>
  );
}

// ─── Estimation Rules Section ─────────────────────────────────────────────────
function EstimationRulesSection({ data, onChange }) {
  return (
    <AccordionCard title="Estimation Rules" icon="calculator" defaultOpen={false}>
      <p style={{ margin:'0 0 16px',fontSize:13,color:'var(--color-text-secondary)' }}>Auto-calculation percentages applied when updating Dev original estimate.</p>
      <div style={{ display:'grid',gridTemplateColumns:'1fr 1fr 1fr',gap:16 }}>
        <div style={{ display:'flex',flexDirection:'column',gap:6 }}>
          <label style={{ fontSize:13,fontWeight:500,color:'var(--color-text-primary)' }}>QA % of Dev</label>
          <div style={{ display:'flex',alignItems:'center',gap:8 }}>
            <input type="range" min={0} max={100} step={5} value={data.qaPercentOfDev}
              onChange={e => onChange({...data,qaPercentOfDev:parseInt(e.target.value)})}
              style={{ flex:1,accentColor:'var(--color-primary)' }} />
            <span style={{ fontSize:14,fontWeight:700,color:'var(--color-primary)',width:36,textAlign:'right' }}>{data.qaPercentOfDev}%</span>
          </div>
        </div>
        <div style={{ display:'flex',flexDirection:'column',gap:6 }}>
          <label style={{ fontSize:13,fontWeight:500,color:'var(--color-text-primary)' }}>UAT % of Dev</label>
          <div style={{ display:'flex',alignItems:'center',gap:8 }}>
            <input type="range" min={0} max={100} step={5} value={data.uatPercentOfDev}
              onChange={e => onChange({...data,uatPercentOfDev:parseInt(e.target.value)})}
              style={{ flex:1,accentColor:'var(--color-primary)' }} />
            <span style={{ fontSize:14,fontWeight:700,color:'var(--color-primary)',width:36,textAlign:'right' }}>{data.uatPercentOfDev}%</span>
          </div>
        </div>
        <FormSelect label="Round to Nearest" value={data.roundToNearest}
          onChange={e => onChange({...data,roundToNearest:parseFloat(e.target.value)})}
          options={[{value:0.5,label:'0.5 hrs'},{value:1,label:'1 hr'},{value:0.25,label:'0.25 hrs'}]} />
      </div>
    </AccordionCard>
  );
}

// ─── Grouping Rules Section ───────────────────────────────────────────────────
function GroupingRulesSection({ data, onChange }) {
  return (
    <AccordionCard title="Grouping & Tagging Rules" icon="tag" defaultOpen={false}>
      <div style={{ display:'flex',flexDirection:'column',gap:16 }}>
        <FormInput label="Tag Field Reference Name" value={data.tagField||''} monospace
          onChange={e => onChange({...data,tagField:e.target.value})} helper="Used to derive visible tab groups from work item tags." />
        <div>
          <label style={{ fontSize:13,fontWeight:500,color:'var(--color-text-primary)',display:'block',marginBottom:8 }}>Product Tags</label>
          <div style={{ display:'flex',flexWrap:'wrap',gap:8 }}>
            {(data.productTags||[]).map(tag => (
              <span key={tag} style={{ display:'inline-flex',alignItems:'center',gap:6,fontSize:12,fontWeight:500,padding:'4px 10px',borderRadius:8,background:'var(--color-secondary)',color:'var(--color-secondary-fg)',border:'1px solid var(--color-border)' }}>
                {tag}
                <button onClick={() => onChange({...data,productTags:(data.productTags||[]).filter(t=>t!==tag)})}
                  style={{ border:'none',background:'transparent',color:'inherit',cursor:'pointer',padding:0,display:'inline-flex',opacity:.6 }}>
                  <Icon name="x" size={12} />
                </button>
              </span>
            ))}
            <button style={{ fontSize:12,fontWeight:500,padding:'4px 10px',borderRadius:8,border:'1px dashed var(--color-border)',background:'transparent',color:'var(--color-text-secondary)',cursor:'pointer',display:'inline-flex',alignItems:'center',gap:4,fontFamily:'inherit' }}
              onClick={() => { const v = prompt('Add product tag:'); if(v) onChange({...data,productTags:[...(data.productTags||[]),v]}); }}>
              <Icon name="plus" size={12} /> Add Tag
            </button>
          </div>
        </div>
      </div>
    </AccordionCard>
  );
}

// ─── ConfigurationPage ────────────────────────────────────────────────────────
function ConfigurationPage({ connection, onTestConnection, onConnectionChange }) {
  const toast = useToast();
  const [cfg, setCfg] = React.useState(DEFAULT_CONFIG);
  const [committed, setCommitted] = React.useState(DEFAULT_CONFIG);
  const [saveStatus, setSaveStatus] = React.useState('idle');

  const isDirty = JSON.stringify(cfg) !== JSON.stringify(committed);

  const update = (section, val) => setCfg(prev => ({...prev,[section]:val}));

  const handleSave = () => {
    setCommitted(cfg);
    setSaveStatus('success');
    toast.push('Configuration saved to session', 'success');
    setTimeout(() => setSaveStatus('idle'), 3000);
  };

  const handleReset = () => {
    setCfg(DEFAULT_CONFIG);
    toast.push('Configuration reset to defaults', 'info');
  };

  return (
    <div>
      <PageHeader title="Configuration" description="Manage Azure DevOps connections and application settings." />

      {/* Connection banner */}
      <div style={{ marginBottom:24,background:connection==='success'?'color-mix(in srgb,var(--color-success-bg) 35%,transparent)':'color-mix(in srgb,var(--color-warning-bg) 35%,transparent)',border:`1px solid color-mix(in srgb,${connection==='success'?'var(--color-success)':'var(--color-warning)'} 20%,transparent)`,borderRadius:12,padding:'14px 16px',display:'flex',alignItems:'center',justifyContent:'space-between',gap:16,boxShadow:'0 1px 2px 0 rgba(0,0,0,.05)',flexWrap:'wrap' }}>
        <div style={{ display:'flex',alignItems:'flex-start',gap:12 }}>
          <Icon name={connection==='success'?'shield-check':'alert-circle'} size={20}
            style={{ color:connection==='success'?'var(--color-success)':'var(--color-warning-fg)',flexShrink:0,marginTop:2 }} />
          <div>
            <h3 style={{ margin:0,fontSize:14,fontWeight:600,color:'var(--color-text-primary)' }}>
              {connection==='success'?'Backend Connected':'Connection Required'}
            </h3>
            <p style={{ margin:'3px 0 0',fontSize:13,color:'var(--color-text-secondary)' }}>
              {connection==='success'?'Azure DevOps communication is active via server-side PAT.':'Please verify your Organization, Project, and Team settings below.'}
            </p>
          </div>
        </div>
        <Button variant={connection==='success'?'success':'primary'} icon="refresh-cw"
          busy={connection==='testing'} onClick={onTestConnection}>Test Connection</Button>
      </div>

      <div style={{ display:'flex',gap:24,alignItems:'flex-start',flexWrap:'wrap' }}>
        {/* Main config sections */}
        <div style={{ flex:'1 1 500px',display:'flex',flexDirection:'column',gap:20,minWidth:0 }}>
          <AdoConnectionSection data={cfg.ado} onChange={v => update('ado',v)} connection={connection} onTest={onTestConnection} />
          <IterationSection data={cfg.iteration} onChange={v => update('iteration',v)} disabled={connection!=='success'} />
          <FieldMappingSection data={cfg.mapping} onChange={v => update('mapping',v)} disabled={connection!=='success'} />
          <TaskRulesSection data={cfg.tasks} onChange={v => update('tasks',v)} disabled={connection!=='success'} />
          <ReadinessRulesSection data={cfg.readiness} onChange={v => update('readiness',v)} />
          <EstimationRulesSection data={cfg.estimation} onChange={v => update('estimation',v)} />
          <GroupingRulesSection data={cfg.grouping} onChange={v => update('grouping',v)} />
        </div>

        {/* Session review sidebar */}
        <div style={{ width:300,flexShrink:0,position:'sticky',top:80 }}>
          <SessionReviewPanel config={cfg} connection={connection} isDirty={isDirty}
            onSave={handleSave} onReset={handleReset} onTest={onTestConnection} saveStatus={saveStatus} />
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { ConfigurationPage });
