import 'package:flutter/material.dart';

import '../data/prep_seed_data.dart';
import '../widgets/prep_widgets.dart';

// page_id source marker: onboarding
// page_id: onboarding | route_name: /onboarding | widget_class: OnboardingScreen | state_key: onboardingState
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  static const routeName = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static final _contract = pageContracts[8];
  static const _mediaChoices = [
    _OnboardingMedia(
      id: 'prep-photo',
      label: 'Prep station photo',
      detail: 'Uploaded preview for the active batch handoff.',
      icon: Icons.photo_camera_outlined,
    ),
    _OnboardingMedia(
      id: 'quality-clip',
      label: 'Quality check clip',
      detail: 'Replacement preview showing the latest station condition.',
      icon: Icons.movie_outlined,
    ),
    _OnboardingMedia(
      id: 'label-scan',
      label: 'Label scan',
      detail: 'Readable attachment used for manager readback.',
      icon: Icons.document_scanner_outlined,
    ),
  ];

  _OnboardingMedia? _selectedMedia = _mediaChoices.first;
  bool _previewOpen = true;
  bool _removeConfirmationVisible = false;
  int _replaceIndex = 0;
  String _readback =
      'Readback: prep-photo attached, preview visible, remove confirmation idle.';

  void _addMedia() {
    setState(() {
      _selectedMedia = _mediaChoices.first;
      _previewOpen = true;
      _removeConfirmationVisible = false;
      _replaceIndex = 0;
      _readback =
          'Readback: ${_selectedMedia!.id} added and selected for preview.';
    });
  }

  void _previewMedia() {
    setState(() {
      _previewOpen = true;
      _removeConfirmationVisible = false;
      _readback = _selectedMedia == null
          ? 'Readback: no media selected; preview is empty.'
          : 'Readback: previewing ${_selectedMedia!.id} before handoff.';
    });
  }

  void _replaceMedia() {
    setState(() {
      _replaceIndex = (_replaceIndex + 1) % _mediaChoices.length;
      _selectedMedia = _mediaChoices[_replaceIndex];
      _previewOpen = true;
      _removeConfirmationVisible = false;
      _readback =
          'Readback: media replaced with ${_selectedMedia!.id}; preview refreshed.';
    });
  }

  void _requestDelete() {
    setState(() {
      _removeConfirmationVisible = true;
      _readback = _selectedMedia == null
          ? 'Readback: delete requested with no selected media.'
          : 'Readback: remove confirmation requested for ${_selectedMedia!.id}.';
    });
  }

  void _confirmDelete() {
    setState(() {
      final removedId = _selectedMedia?.id ?? 'no-media';
      _selectedMedia = null;
      _previewOpen = false;
      _removeConfirmationVisible = false;
      _readback =
          'Readback: $removedId removed; selected media preview is empty.';
    });
  }

  void _cancelDelete() {
    setState(() {
      _removeConfirmationVisible = false;
      _readback = _selectedMedia == null
          ? 'Readback: remove cancelled; no media is selected.'
          : 'Readback: remove cancelled; ${_selectedMedia!.id} remains selected.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedMedia = _selectedMedia;
    final previewStatus = selectedMedia == null
        ? 'Selected media preview: empty'
        : 'Selected media preview: ${selectedMedia.label}';

    return PrepScaffold(
      contract: _contract,
      children: [
        InfoCard(
          title: 'Flow media lifecycle',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Practice add, preview, replace, delete, and readback before '
                'using media in a live prep handoff.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    key: const Key('onboarding-add-media'),
                    onPressed: _addMedia,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Add'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('onboarding-preview-media'),
                    onPressed: _previewMedia,
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Preview'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('onboarding-replace-media'),
                    onPressed: _replaceMedia,
                    icon: const Icon(Icons.change_circle_outlined),
                    label: const Text('Replace'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('onboarding-delete-media'),
                    onPressed: selectedMedia == null ? null : _requestDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
        InfoCard(
          title: 'Selected media preview state',
          trailing: StatusChip(selectedMedia == null ? 'empty' : 'selected'),
          child: _MediaPreview(
            selectedMedia: selectedMedia,
            previewOpen: _previewOpen,
            previewStatus: previewStatus,
          ),
        ),
        InfoCard(
          title: 'Remove confirmation',
          trailing: StatusChip(
            _removeConfirmationVisible ? 'confirming' : 'idle',
            color: _removeConfirmationVisible ? Colors.orange : Colors.green,
          ),
          child: _RemoveConfirmation(
            visible: _removeConfirmationVisible,
            media: selectedMedia,
            onConfirm: _confirmDelete,
            onCancel: _cancelDelete,
          ),
        ),
        InfoCard(
          title: 'Readback steps',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LifecycleStep(
                icon: Icons.add_photo_alternate_outlined,
                title: 'Add',
                detail: 'Attach media to the active onboarding handoff.',
              ),
              const _LifecycleStep(
                icon: Icons.visibility_outlined,
                title: 'Preview',
                detail: 'Check the selected media preview before saving.',
              ),
              const _LifecycleStep(
                icon: Icons.change_circle_outlined,
                title: 'Replace',
                detail: 'Swap stale media and refresh the selected preview.',
              ),
              const _LifecycleStep(
                icon: Icons.delete_outline,
                title: 'Delete',
                detail: 'Ask for remove confirmation before clearing media.',
              ),
              const _LifecycleStep(
                icon: Icons.fact_check_outlined,
                title: 'Readback',
                detail: 'Confirm what remains visible after each action.',
              ),
              const SizedBox(height: 8),
              Text(_readback, key: const Key('onboarding-media-readback')),
            ],
          ),
        ),
      ],
    );
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({
    required this.selectedMedia,
    required this.previewOpen,
    required this.previewStatus,
  });

  final _OnboardingMedia? selectedMedia;
  final bool previewOpen;
  final String previewStatus;

  @override
  Widget build(BuildContext context) {
    final media = selectedMedia;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(previewStatus, key: const Key('onboarding-selected-preview')),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: media == null || !previewOpen
                ? const Row(
                    children: [
                      Icon(Icons.hide_image_outlined),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('No selected media is visible in preview.'),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        child: Icon(media.icon, size: 30),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              media.label,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(media.detail),
                            const SizedBox(height: 4),
                            Text('media_id: ${media.id}'),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _RemoveConfirmation extends StatelessWidget {
  const _RemoveConfirmation({
    required this.visible,
    required this.media,
    required this.onConfirm,
    required this.onCancel,
  });

  final bool visible;
  final _OnboardingMedia? media;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    if (!visible || media == null) {
      return const Text(
        'No remove confirmation is open.',
        key: Key('onboarding-remove-confirmation'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Remove confirmation: delete ${media!.label} from the selected media preview?',
          key: const Key('onboarding-remove-confirmation'),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              key: const Key('onboarding-confirm-remove'),
              onPressed: onConfirm,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Confirm remove'),
            ),
            OutlinedButton.icon(
              key: const Key('onboarding-cancel-remove'),
              onPressed: onCancel,
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }
}

class _LifecycleStep extends StatelessWidget {
  const _LifecycleStep({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text('$title: $detail')),
        ],
      ),
    );
  }
}

class _OnboardingMedia {
  const _OnboardingMedia({
    required this.id,
    required this.label,
    required this.detail,
    required this.icon,
  });

  final String id;
  final String label;
  final String detail;
  final IconData icon;
}
