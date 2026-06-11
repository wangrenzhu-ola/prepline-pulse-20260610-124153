import 'package:flutter/material.dart';

import '../state/prep_board_controller.dart';

class BatchSetupFields extends StatefulWidget {
  const BatchSetupFields({
    required this.controller,
    required this.keyPrefix,
    super.key,
  });

  final PrepBoardController controller;
  final String keyPrefix;

  @override
  State<BatchSetupFields> createState() => _BatchSetupFieldsState();
}

class _BatchSetupFieldsState extends State<BatchSetupFields> {
  late final TextEditingController _ownerController;
  String? _lastBatchId;
  String? _station;

  @override
  void initState() {
    super.initState();
    final batch = widget.controller.selectedBatch;
    _lastBatchId = batch.id;
    _station = batch.station;
    _ownerController = TextEditingController(text: batch.owner);
  }

  @override
  void didUpdateWidget(covariant BatchSetupFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncDraftWhenBatchChanges();
  }

  @override
  void dispose() {
    _ownerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _syncDraftWhenBatchChanges();
    final controller = widget.controller;
    final selectedBatch = controller.selectedBatch;
    final stations = controller.stationNames;
    if (!stations.contains(_station)) {
      _station = selectedBatch.station;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: Key('${widget.keyPrefix}-batch-selector'),
          value: controller.selectedBatchId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Active batch'),
          items: [
            for (final batch in controller.batches)
              DropdownMenuItem(
                value: batch.id,
                child: Text(
                  '${batch.id} ${batch.name}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            controller.selectBatch(value);
            _syncDraftWhenBatchChanges(force: true);
            setState(() {});
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          key: Key('${widget.keyPrefix}-station-selector'),
          value: _station,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Station'),
          items: [
            for (final station in stations)
              DropdownMenuItem(value: station, child: Text(station)),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() => _station = value);
            controller.updateSelectedBatchDetails(
              station: value,
              owner: _ownerController.text,
            );
          },
        ),
        const SizedBox(height: 10),
        TextField(
          key: Key('${widget.keyPrefix}-owner-field'),
          controller: _ownerController,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Owner'),
          onChanged: (value) {
            if (value.trim().isEmpty) {
              return;
            }
            controller.updateSelectedBatchDetails(
              station: _station,
              owner: value,
            );
          },
          onEditingComplete: () {
            if (_ownerController.text.trim().isEmpty) {
              _ownerController.text = widget.controller.selectedBatch.owner;
            }
            FocusScope.of(context).unfocus();
          },
        ),
      ],
    );
  }

  void _syncDraftWhenBatchChanges({bool force = false}) {
    final batch = widget.controller.selectedBatch;
    if (!force && _lastBatchId == batch.id) {
      return;
    }
    _lastBatchId = batch.id;
    _station = batch.station;
    _ownerController.text = batch.owner;
  }
}
