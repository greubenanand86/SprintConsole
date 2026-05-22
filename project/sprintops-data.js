window.SPRINTOPS_DATA = (function () {
  function computeReadiness(item) {
    const parentReady = item.state === 'Ready for Production';
    const uatClosed = item.tasks && item.tasks.UAT && item.tasks.UAT.actionState === 'created' && item.tasks.UAT.adoState === 'Closed';
    const linkExists = item.link && item.link.actionState === 'created';
    const isApproved = item.approvalStatus === 'approved';
    const met = [parentReady, uatClosed, linkExists, isApproved].filter(Boolean).length;
    const percent = Math.round((met / 4) * 100);
    let label = 'Nothing started';
    if (percent === 100) label = 'All criteria met';
    else if (met === 3) {
      if (!parentReady) label = 'State not ready';
      else if (!uatClosed) label = 'UAT pending closure';
      else if (!linkExists) label = 'Link missing';
      else label = 'Approval pending';
    } else if (met === 2) label = '2 of 4 criteria met';
    else if (met === 1) label = '1 of 4 criteria met';
    return { percent, met, label, parentReady, uatClosed, linkExists, isApproved };
  }

  const BASE = [
    {
      id: 10101, title: 'Implement User Authentication Flow',
      type: 'User Story', state: 'Ready for Production',
      tags: ['Learner Wallet', 'Backend'],
      iterationPath: 'Performer\\Sprint 1', visibleTabs: ['All', 'Learner Wallet'],
      assignee: 'Prasanna G', childrenCount: 4, closedChildren: 4, relatedItems: 2,
      tasks: {
        Dev:  { id: 10102, actionState: 'created', adoState: 'Closed' },
        QA:   { id: 10103, actionState: 'created', adoState: 'Closed' },
        UAT:  { id: 10104, actionState: 'created', adoState: 'Closed' },
        Post: { id: 10105, actionState: 'created', adoState: 'New' }
      },
      link: { actionState: 'created', url: 'https://release.pipeline/123' },
      approvalStatus: 'approved'
    },
    {
      id: 10205, title: 'Fix Data Sync Delay in Dashboard',
      type: 'Bug', state: 'Active',
      tags: ['Edlusion', 'Production Issue'],
      iterationPath: 'Performer\\Sprint 1', visibleTabs: ['All', 'Edlusion', 'Production Issue'],
      assignee: 'Alex R', childrenCount: 3, closedChildren: 1, relatedItems: 1,
      tasks: {
        Dev:  { id: 10206, actionState: 'created', adoState: 'Resolved' },
        QA:   { actionState: 'creating' },
        UAT:  { actionState: 'absent' },
        Post: { actionState: 'absent' }
      },
      link: { actionState: 'absent' },
      approvalStatus: 'not_approved'
    },
    {
      id: 10342, title: 'Update NCSI Reporting Export Format',
      type: 'User Story', state: 'Resolved',
      tags: ['NCSI'],
      iterationPath: 'Performer\\Sprint 1', visibleTabs: ['All', 'NCSI'],
      assignee: 'David L', childrenCount: 4, closedChildren: 3, relatedItems: 0,
      tasks: {
        Dev:  { id: 10343, actionState: 'created', adoState: 'Closed' },
        QA:   { id: 10344, actionState: 'created', adoState: 'Closed' },
        UAT:  { id: 10345, actionState: 'created', adoState: 'Active' },
        Post: { actionState: 'absent' }
      },
      link: { actionState: 'failed' },
      approvalStatus: 'approved'
    },
    {
      id: 10450, title: 'Standalone Database Index Optimization',
      type: 'Bug', state: 'New',
      tags: ['Database', 'Performance'],
      iterationPath: 'Performer\\Sprint 1', visibleTabs: ['All', 'General'],
      assignee: 'Unassigned', childrenCount: 0, closedChildren: 0, relatedItems: 0,
      tasks: {
        Dev:  { actionState: 'absent' }, QA:   { actionState: 'absent' },
        UAT:  { actionState: 'absent' }, Post: { actionState: 'absent' }
      },
      link: { actionState: 'absent' },
      approvalStatus: 'not_approved'
    },
    {
      id: 10512, title: 'Emergency Patch for Login Timeout',
      type: 'Bug', state: 'Ready for Production',
      tags: ['Production Issue'],
      iterationPath: 'Performer\\Sprint 1', visibleTabs: ['All', 'General', 'Production Issue'],
      assignee: 'Prasanna G', childrenCount: 4, closedChildren: 3, relatedItems: 1,
      tasks: {
        Dev:  { id: 10513, actionState: 'created', adoState: 'Closed' },
        QA:   { id: 10514, actionState: 'created', adoState: 'Closed' },
        UAT:  { id: 10515, actionState: 'created', adoState: 'Closed' },
        Post: { actionState: 'absent' }
      },
      link: { actionState: 'created', url: 'https://release.pipeline/999' },
      approvalStatus: 'not_approved'
    },
    {
      id: 10623, title: 'Migrate Legacy Reports to New Export Engine',
      type: 'User Story', state: 'Active',
      tags: ['Learner Wallet', 'Backend'],
      iterationPath: 'Performer\\Sprint 1', visibleTabs: ['All', 'Learner Wallet'],
      assignee: 'Sarah J', childrenCount: 2, closedChildren: 0, relatedItems: 0,
      tasks: {
        Dev:  { id: 10624, actionState: 'created', adoState: 'Active' },
        QA:   { actionState: 'absent' },
        UAT:  { actionState: 'absent' },
        Post: { actionState: 'absent' }
      },
      link: { actionState: 'absent' },
      approvalStatus: 'not_approved'
    },
    {
      id: 10701, title: 'Implement Configurable Email Notifications',
      type: 'User Story', state: 'Ready for Production',
      tags: ['NCSI', 'Notifications'],
      iterationPath: 'Performer\\Sprint 1', visibleTabs: ['All', 'NCSI'],
      assignee: 'Mike T', childrenCount: 4, closedChildren: 4, relatedItems: 1,
      tasks: {
        Dev:  { id: 10702, actionState: 'created', adoState: 'Closed' },
        QA:   { id: 10703, actionState: 'created', adoState: 'Closed' },
        UAT:  { id: 10704, actionState: 'created', adoState: 'Closed' },
        Post: { id: 10705, actionState: 'created', adoState: 'Closed' }
      },
      link: { actionState: 'created', url: 'https://release.pipeline/701' },
      approvalStatus: 'approved'
    }
  ];

  const READINESS = BASE.map(item => ({ ...item, readiness: computeReadiness(item) }));

  const ESTIMATION = BASE.map((r, i) => {
    const base = {
      id: r.id, title: r.title, type: r.type, state: r.state, tags: r.tags, visibleTabs: r.visibleTabs,
      tasks: {
        Dev:  { id: r.tasks.Dev.id,  original: 8,   remaining: 4,   completed: 4,  isOverridden: false },
        QA:   { id: r.tasks.QA.id,   original: 2,   remaining: 2,   completed: 0,  isOverridden: false },
        UAT:  { id: r.tasks.UAT.id,  original: 1.5, remaining: 1.5, completed: 0,  isOverridden: false }
      }
    };
    if (i === 1) { base.tasks.Dev.original = ''; base.tasks.QA.original = ''; base.tasks.UAT.original = ''; }
    if (i === 2) { base.tasks.QA.original = 5; base.tasks.QA.isOverridden = true; }
    if (i === 5) { base.tasks.Dev.original = 12; base.tasks.QA.original = 3; base.tasks.UAT.original = 2; }
    if (i === 6) { base.tasks.Dev.remaining = 0; base.tasks.QA.remaining = 0; base.tasks.UAT.remaining = 0; }
    return base;
  });

  const RELEASES = [
    {
      id: 20001, title: 'Sprint Release task \u2014 LW \u2014 Sprint 1 \u2014 v1.2.0',
      product: 'LW', releaseType: 'Sprint', version: '1.2.0', state: 'Active',
      tags: ['Release task', 'Learner Wallet'],
      linkedItems: [
        { id: 10101, title: 'Implement User Authentication Flow', type: 'User Story', state: 'Ready for Production' },
        { id: 10623, title: 'Migrate Legacy Reports to New Export Engine', type: 'User Story', state: 'Active' }
      ],
      postDepTask: { actionState: 'created', adoState: 'New' },
      descriptionSynced: true
    },
    {
      id: 20002, title: 'Hotfix Release task \u2014 ED \u2014 Sprint 1 \u2014 v1.1.3',
      product: 'ED', releaseType: 'Hotfix', version: '1.1.3', state: 'Ready for Production',
      tags: ['Release task', 'Edlusion'],
      linkedItems: [
        { id: 10512, title: 'Emergency Patch for Login Timeout', type: 'Bug', state: 'Ready for Production' }
      ],
      postDepTask: { actionState: 'absent' },
      descriptionSynced: false
    },
    {
      id: 20003, title: 'Sprint Release task \u2014 NCSI \u2014 Sprint 1 \u2014 v2.0.1',
      product: 'NCSI', releaseType: 'Sprint', version: '2.0.1', state: 'Active',
      tags: ['Release task', 'NCSI'],
      linkedItems: [
        { id: 10342, title: 'Update NCSI Reporting Export Format', type: 'User Story', state: 'Resolved' },
        { id: 10701, title: 'Implement Configurable Email Notifications', type: 'User Story', state: 'Ready for Production' }
      ],
      postDepTask: { actionState: 'absent' },
      descriptionSynced: false
    }
  ];

  return {
    iteration: { name: 'Sprint 1', fullPath: 'Performer\\Sprint 1' },
    iterations: ['Performer\\Sprint 1', 'Performer\\Sprint 2', 'Performer\\Sprint 3'],
    tabs: ['All', 'Learner Wallet', 'Edlusion', 'NCSI', 'Production Issue', 'General'],
    readiness: READINESS,
    estimation: ESTIMATION,
    releases: RELEASES,
    computeReadiness
  };
})();
