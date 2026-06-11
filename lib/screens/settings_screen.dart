import 'package:flutter/material.dart';

import '../data/prep_seed_data.dart';
import '../state/prep_board_controller.dart';
import '../widgets/prep_widgets.dart';

// page_id source marker: settings
// page_id: settings | route_name: /settings | widget_class: SettingsScreen | state_key: settingsState
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  static const routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _stationPreference = 'Hot line';
  String _serviceWindowDefault = '11:30 lunch';
  int _rulesRevision = 3;
  bool _quietAlerts = true;
  bool _handoffReadbackRequired = true;
  bool _ownerAgreementRequired = true;
  bool _backupPanAgreement = false;
  String _savedReadback =
      'No settings revision saved yet. Review station rules before service.';

  @override
  Widget build(BuildContext context) {
    final controller = PrepBoardScope.of(context);
    final stationNames = controller.stations
        .map((station) => station.station)
        .toSet()
        .toList(growable: false);

    if (!stationNames.contains(_stationPreference) && stationNames.isNotEmpty) {
      _stationPreference = stationNames.first;
    }

    return PrepScaffold(
      contract: pageContracts[7],
      children: [
        InfoCard(
          title: 'Station rules revision controls',
          trailing: StatusChip('Revision $_rulesRevision'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                key: const Key('settings-station-rule-dropdown'),
                value: _stationPreference,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Station preference',
                ),
                items: [
                  for (final station in stationNames)
                    DropdownMenuItem(value: station, child: Text(station)),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _stationPreference = value;
                    _savedReadback =
                        'Draft revision $_rulesRevision now targets $value station rules.';
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('settings-service-window-dropdown'),
                value: _serviceWindowDefault,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Service window default',
                ),
                items: const [
                  DropdownMenuItem(
                    value: '11:30 lunch',
                    child: Text('11:30 lunch'),
                  ),
                  DropdownMenuItem(
                    value: '12:00 rush',
                    child: Text('12:00 rush'),
                  ),
                  DropdownMenuItem(
                    value: '17:30 dinner',
                    child: Text('17:30 dinner'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _serviceWindowDefault = value;
                    _savedReadback =
                        'Draft revision $_rulesRevision applies to $value.';
                  });
                },
              ),
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('settings-revision-decrement'),
                      tooltip: 'Previous revision',
                      onPressed: _rulesRevision <= 1
                          ? null
                          : () {
                              setState(() {
                                _rulesRevision -= 1;
                                _savedReadback =
                                    'Viewing station rules revision $_rulesRevision.';
                              });
                            },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Expanded(
                      child: Text(
                        'Station rules revision $_rulesRevision',
                        key: const Key('settings-revision-visible-readback'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      key: const Key('settings-revision-increment'),
                      tooltip: 'Next revision',
                      onPressed: () {
                        setState(() {
                          _rulesRevision += 1;
                          _savedReadback =
                              'Drafting station rules revision $_rulesRevision.';
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        InfoCard(
          title: 'Team agreement toggles',
          child: Column(
            children: [
              SwitchListTile(
                key: const Key('settings-quiet-alerts-toggle'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Quiet alerts'),
                subtitle: const Text('Use low-noise reminders during service.'),
                value: _quietAlerts,
                onChanged: (value) {
                  setState(() {
                    _quietAlerts = value;
                    _savedReadback =
                        'Quiet alerts ${value ? 'enabled' : 'disabled'} for revision $_rulesRevision.';
                  });
                },
              ),
              SwitchListTile(
                key: const Key('settings-handoff-readback-toggle'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Handoff readback required'),
                subtitle: const Text(
                  'Owner reads back station state before handoff.',
                ),
                value: _handoffReadbackRequired,
                onChanged: (value) {
                  setState(() {
                    _handoffReadbackRequired = value;
                    _savedReadback =
                        'Handoff readback ${value ? 'required' : 'optional'} in revision $_rulesRevision.';
                  });
                },
              ),
              SwitchListTile(
                key: const Key('settings-owner-agreement-toggle'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Owner agreement required'),
                subtitle: const Text(
                  'Station owner confirms every rule revision.',
                ),
                value: _ownerAgreementRequired,
                onChanged: (value) {
                  setState(() {
                    _ownerAgreementRequired = value;
                    _savedReadback =
                        'Owner agreement ${value ? 'required' : 'not required'} for revision $_rulesRevision.';
                  });
                },
              ),
              SwitchListTile(
                key: const Key('settings-backup-pan-toggle'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Backup pan agreement'),
                subtitle: const Text(
                  'Team agrees backup pan checks stay visible.',
                ),
                value: _backupPanAgreement,
                onChanged: (value) {
                  setState(() {
                    _backupPanAgreement = value;
                    _savedReadback =
                        'Backup pan agreement ${value ? 'included' : 'removed'} from revision $_rulesRevision.';
                  });
                },
              ),
            ],
          ),
        ),
        InfoCard(
          title: 'Save revision',
          trailing: FilledButton.icon(
            key: const Key('settings-save-revision-button'),
            onPressed: () {
              setState(() {
                _savedReadback =
                    'Saved revision $_rulesRevision for $_stationPreference / $_serviceWindowDefault. '
                    'Agreements: quiet alerts ${_quietAlerts ? 'on' : 'off'}, '
                    'handoff readback ${_handoffReadbackRequired ? 'on' : 'off'}, '
                    'owner agreement ${_ownerAgreementRequired ? 'on' : 'off'}, '
                    'backup pan ${_backupPanAgreement ? 'on' : 'off'}.';
              });
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
          child: Text(
            _savedReadback,
            key: const Key('settings-save-revision-readback'),
          ),
        ),
      ],
    );
  }
}
