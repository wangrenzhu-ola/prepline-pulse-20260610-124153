import '../models/prep_models.dart';

const String prepSampleAsset = 'assets/prep_sample.txt';

class PrepRepository {
  const PrepRepository();

  LineBoardSnapshot loadLineBoard() {
    return LineBoardSnapshot(
      pageId: 'line-board',
      serviceWindow: const ServiceWindow(
        label: 'Lunch service',
        timeRange: '11:30 AM - 1:30 PM',
        minutesRemaining: 24,
        pressure: 'Hot line needs one owner check before window open.',
      ),
      stations: const [
        StationStatus(
          station: 'Hot line',
          state: 'Cooking',
          owner: 'Mika',
          backup: 'Ren',
          activeBatchId: 'B-104',
          blocked: false,
        ),
        StationStatus(
          station: 'Cold bar',
          state: 'Blocked',
          owner: 'Lena',
          backup: 'Sam',
          activeBatchId: 'B-118',
          blocked: true,
        ),
        StationStatus(
          station: 'Expo',
          state: 'Ready',
          owner: 'Jun',
          backup: 'Mika',
          activeBatchId: 'B-126',
          blocked: false,
        ),
      ],
      batches: const [
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
          blocked: false,
        ),
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
          blocked: true,
        ),
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
          blocked: false,
        ),
      ],
      latestSavedState: const PrepLog(
        batchId: 'B-126',
        batchName: 'Soup garnish cups',
        station: 'Expo',
        state: 'Ready',
        owner: 'Jun',
        note: 'Ready for rush rail.',
        savedAt: '11:06',
      ),
      media: const MediaRecord(
        id: 'M-line-board',
        assetPath: prepSampleAsset,
        label: 'Station prep sample attached',
        attachedTo: 'line-board',
      ),
    );
  }
}
