import '../models/prep_models.dart';

const String heroAsset = 'assets/images/prepline_hero.png';
const String batchAsset = 'assets/images/prepline_batch.png';

const pageContracts = <PageContract>[
  PageContract(
    pageId: 'line-board',
    routeName: '/line-board',
    widgetClass: 'LineBoardScreen',
    stateKey: 'lineBoardState',
    title: 'Line Board',
    purpose:
        'Scan active prep batches, station ownership, and service pressure.',
    mustShow: [
      'current service window',
      'station status cards',
      'latest saved batch state',
      'owner badges',
      'blocked batch count',
      'primary update control',
    ],
    layer: 'primary',
  ),
  PageContract(
    pageId: 'batch-detail',
    routeName: '/batch-detail',
    widgetClass: 'BatchDetailScreen',
    stateKey: 'batchDetailState',
    title: 'Batch Detail',
    purpose:
        'Inspect one prep batch with station, owner, quantity, and history.',
    mustShow: [
      'batch identity',
      'station assignment',
      'owner and backup',
      'state history preview',
      'edit and resolve controls'
    ],
    layer: 'primary',
  ),
  PageContract(
    pageId: 'state-entry',
    routeName: '/state-entry',
    widgetClass: 'StateEntryScreen',
    stateKey: 'stateEntryState',
    title: 'State Entry',
    purpose: 'Save current batch state with a clear confirmation surface.',
    mustShow: [
      'batch selector',
      'station selector',
      'state segmented control',
      'time adjustment',
      'short note field',
      'saved-state confirmation'
    ],
    layer: 'primary',
  ),
  PageContract(
      pageId: 'service-clock',
      routeName: '/service-clock',
      widgetClass: 'ServiceClockScreen',
      stateKey: 'serviceClockState',
      title: 'Service Clock',
      purpose: 'Track readiness windows and late-risk batches.',
      mustShow: [
        'service countdown',
        'ready and waiting lanes',
        'late-risk chips',
        'owner follow-up prompts',
        'station filter',
        'window close summary'
      ],
      layer: 'primary'),
  PageContract(
      pageId: 'station-timeline',
      routeName: '/station-timeline',
      widgetClass: 'StationTimelineScreen',
      stateKey: 'stationTimelineState',
      title: 'Station Timeline',
      purpose: 'Review station history after each saved update.',
      mustShow: [
        'date filter',
        'station filter',
        'chronological batch entries',
        'saved time and owner',
        'state change markers',
        'new entry inclusion'
      ],
      layer: 'primary'),
  PageContract(
      pageId: 'exception-queue',
      routeName: '/exception-queue',
      widgetClass: 'ExceptionQueueScreen',
      stateKey: 'exceptionQueueState',
      title: 'Exception Queue',
      purpose: 'Resolve blocked, late, or unclear prep batches.',
      mustShow: [
        'exception cards',
        'blocker reason',
        'assigned owner',
        'resolution actions',
        'resolution confirmation',
        'return-to-board control'
      ],
      layer: 'primary'),
  PageContract(
      pageId: 'prep-rules',
      routeName: '/prep-rules',
      widgetClass: 'PrepRulesScreen',
      stateKey: 'prepRulesState',
      title: 'Prep Rules',
      purpose: 'Keep station defaults and team agreements available.',
      mustShow: [
        'station defaults',
        'service-window presets',
        'handoff agreements',
        'owner rotation rules',
        'editable rule cards',
        'last updated readout'
      ],
      layer: 'primary'),
  PageContract(
      pageId: 'settings',
      routeName: '/settings',
      widgetClass: 'SettingsScreen',
      stateKey: 'settingsState',
      title: 'Settings',
      purpose: 'User preferences and app configuration.',
      mustShow: [
        'quiet alerts',
        'station preference',
        'service window default'
      ],
      layer: 'system'),
  PageContract(
      pageId: 'onboarding',
      routeName: '/onboarding',
      widgetClass: 'OnboardingScreen',
      stateKey: 'onboardingState',
      title: 'Onboarding',
      purpose: 'First-time guide for prep leads.',
      mustShow: ['value proposition', 'first saved state', 'review history'],
      layer: 'system'),
  PageContract(
      pageId: 'about',
      routeName: '/about',
      widgetClass: 'AboutScreen',
      stateKey: 'aboutState',
      title: 'About',
      purpose: 'App information, support, and legal.',
      mustShow: ['app information', 'support', 'legal'],
      layer: 'system'),
  PageContract(
      pageId: 'line-board_detail',
      routeName: '/line-board-detail',
      widgetClass: 'LineBoardDetailScreen',
      stateKey: 'lineBoardDetailState',
      title: 'Line Board Detail',
      purpose: 'Detailed board progress and station pressure.',
      mustShow: ['stepper progress', 'station pressure', 'latest log'],
      layer: 'secondary'),
  PageContract(
      pageId: 'batch-detail_detail',
      routeName: '/batch-detail-detail',
      widgetClass: 'BatchDetailDetailScreen',
      stateKey: 'batchDetailDetailState',
      title: 'Batch Detail Audit',
      purpose: 'Detailed audit trail for the selected batch.',
      mustShow: ['stepper progress', 'history ledger', 'resolution status'],
      layer: 'secondary'),
  PageContract(
      pageId: 'state-entry_detail',
      routeName: '/state-entry-detail',
      widgetClass: 'StateEntryDetailScreen',
      stateKey: 'stateEntryDetailState',
      title: 'State Entry Detail',
      purpose: 'Detailed saved-state readback and next action.',
      mustShow: ['stepper progress', 'saved confirmation', 'next action'],
      layer: 'secondary'),
];

const seedBatches = <PrepBatch>[
  PrepBatch(
      id: 'B-104',
      name: 'Roast chicken trays',
      station: 'Hot line',
      owner: 'Mika',
      backup: 'Ren',
      quantity: 18,
      state: 'Cooking',
      serviceWindow: '11:30 lunch',
      minutesToWindow: 24,
      note: 'Temp check due before transfer.',
      blocked: false),
  PrepBatch(
      id: 'B-118',
      name: 'Avocado toast mise',
      station: 'Cold bar',
      owner: 'Lena',
      backup: 'Sam',
      quantity: 32,
      state: 'Blocked',
      serviceWindow: '11:30 lunch',
      minutesToWindow: 18,
      note: 'Backup avocado pan requested.',
      blocked: true),
  PrepBatch(
      id: 'B-126',
      name: 'Soup garnish cups',
      station: 'Expo',
      owner: 'Jun',
      backup: 'Mika',
      quantity: 44,
      state: 'Ready',
      serviceWindow: '12:00 rush',
      minutesToWindow: 52,
      note: 'Stored on top rail.',
      blocked: false),
];

const seedLogs = <PrepLog>[
  PrepLog(
      batchId: 'B-104',
      batchName: 'Roast chicken trays',
      station: 'Hot line',
      state: 'Cooking',
      owner: 'Mika',
      note: 'Started second oven rotation.',
      savedAt: '10:58'),
  PrepLog(
      batchId: 'B-118',
      batchName: 'Avocado toast mise',
      station: 'Cold bar',
      state: 'Blocked',
      owner: 'Lena',
      note: 'Need backup avocado pan.',
      savedAt: '11:02'),
  PrepLog(
      batchId: 'B-126',
      batchName: 'Soup garnish cups',
      station: 'Expo',
      state: 'Ready',
      owner: 'Jun',
      note: 'Ready for rush rail.',
      savedAt: '11:06'),
];

const seedExceptions = <PrepException>[
  PrepException(
      id: 'EX-1',
      batchId: 'B-118',
      reason: 'Late-risk: backup pan missing',
      owner: 'Lena',
      resolved: false),
  PrepException(
      id: 'EX-2',
      batchId: 'B-104',
      reason: 'Owner confirmation needed before transfer',
      owner: 'Mika',
      resolved: false),
];
