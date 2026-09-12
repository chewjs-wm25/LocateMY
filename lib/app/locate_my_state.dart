import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../models/location.dart';
import '../models/property.dart';

class LocateMyState extends ChangeNotifier {
  LocateMyState() {
    propertyNameController = TextEditingController();
    propertyPriceController = TextEditingController();
    propertyNoteController = TextEditingController();
    const variants = {'A': 0, 'B': 1, 'C': 2};
    archiveVariant =
        variants[Uri.base.queryParameters['variant']?.toUpperCase()] ?? 0;
  }

  PageId page = PageId.home;
  PageId previous = PageId.home;
  int archiveVariant = 0;
  Place selected = Place.penang;
  Place? locationA = Place.kl;
  Place? locationB = Place.penang;
  bool single = true;
  bool saved = false;
  bool locationDetailExpanded = false;
  bool hasFiveAssessmentPreferences = true;
  bool hasCurrentAssessmentScenario = true;
  String safetyFilter = '全部';
  int medical = 7;
  int education = 4;
  int transit = 8;
  int detail = 0;
  final compared = <int>{};

  late final TextEditingController propertyNameController;
  late final TextEditingController propertyPriceController;
  late final TextEditingController propertyNoteController;
  int? editingProperty;
  Place formPlace = Place.penang;
  List<int> formRatings = [4, 3, 4, 4];
  bool formFlood = false;
  List<InspectionPhoto> draftPhotos = [];
  String? draftCoverPhotoId;
  int photoSequence = 0;

  final properties = <Property>[
    const Property(
      'Taman Seri 公寓',
      520000,
      Place.penang,
      4.2,
      76,
      1,
      false,
      '下午采光良好，主路车流在傍晚较明显。',
      photos: [
        InspectionPhoto(
          id: 'taman-1',
          source: PhotoSource.gallery,
          label: '客厅采光',
        ),
        InspectionPhoto(
          id: 'taman-2',
          source: PhotoSource.camera,
          label: '阳台视野',
        ),
        InspectionPhoto(
          id: 'taman-3',
          source: PhotoSource.gallery,
          label: '厨房水槽',
        ),
      ],
      coverPhotoId: 'taman-1',
    ),
    const Property(
      '海景花园排屋',
      680000,
      Place.penang,
      3.8,
      72,
      2,
      true,
      '排水沟需在雨季再次实地查看。',
      photos: [
        InspectionPhoto(
          id: 'seaview-1',
          source: PhotoSource.camera,
          label: '屋外排水沟',
          syncStatus: PhotoSyncStatus.failed,
        ),
        InspectionPhoto(
          id: 'seaview-2',
          source: PhotoSource.gallery,
          label: '客厅窗边',
          caption: '下午光线进入客厅。',
          syncStatus: PhotoSyncStatus.synced,
        ),
      ],
      coverPhotoId: 'seaview-1',
    ),
    const Property(
      'Bukit Bintang 住宅',
      730000,
      Place.kl,
      4.0,
      81,
      0,
      false,
      '公共交通便利，夜间环境待补充观察。',
      photos: [
        InspectionPhoto(
          id: 'bukit-1',
          source: PhotoSource.camera,
          label: '楼下入口',
        ),
      ],
      coverPhotoId: 'bukit-1',
    ),
  ];

  bool get hasValidComparison =>
      locationA != null && locationB != null && locationA != locationB;

  bool get isComparisonAnalysis => !single && hasValidComparison;

  void go(PageId value, {bool keepBack = true}) {
    if (keepBack) previous = page;
    page = value;
    notifyListeners();
  }

  void back() {
    page = previous;
    notifyListeners();
  }

  void home() {
    page = PageId.home;
    notifyListeners();
  }

  void map() {
    page = PageId.map;
    notifyListeners();
  }

  void selectPlace(Place value) {
    selected = value;
    locationDetailExpanded = false;
    notifyListeners();
  }

  void setSingle(bool value) {
    single = value;
    notifyListeners();
  }

  void swapLocations() {
    final x = locationA;
    locationA = locationB;
    locationB = x;
    notifyListeners();
  }

  void setLocationA(Place? value) {
    locationA = value;
    notifyListeners();
  }

  void setLocationB(Place? value) {
    locationB = value;
    notifyListeners();
  }

  void toggleLocationSummary() {
    locationDetailExpanded = !locationDetailExpanded;
    notifyListeners();
  }

  void toggleSaved() {
    saved = !saved;
    notifyListeners();
  }

  void setSafetyFilter(String value) {
    safetyFilter = value;
    notifyListeners();
  }

  void setMedical(int value) {
    medical = value;
    notifyListeners();
  }

  void setEducation(int value) {
    education = value;
    notifyListeners();
  }

  void setTransit(int value) {
    transit = value;
    notifyListeners();
  }

  void startNewProperty() {
    propertyNameController.text = '海风公寓（新实勘）';
    propertyPriceController.text = '598000';
    propertyNoteController.text = '记录噪音、采光等观察…';
    editingProperty = null;
    formPlace = Place.penang;
    formRatings = [4, 3, 4, 4];
    formFlood = false;
    draftPhotos = [];
    draftCoverPhotoId = null;
    photoSequence = 0;
    page = PageId.addProperty;
    notifyListeners();
  }

  void startEditProperty(int index) {
    final p = properties[index];
    propertyNameController.text = p.name;
    propertyPriceController.text = '${p.price}';
    propertyNoteController.text = p.note;
    editingProperty = index;
    formPlace = p.place;
    formRatings = [4, 3, 4, 4];
    formFlood = p.flood;
    draftPhotos = [...p.photos];
    draftCoverPhotoId =
        p.coverPhotoId ?? (p.photos.isEmpty ? null : p.photos.first.id);
    photoSequence = draftPhotos.length;
    page = PageId.addProperty;
    notifyListeners();
  }

  void setFormPlace(Place value) {
    formPlace = value;
    notifyListeners();
  }

  void setFormRating(int index, int value) {
    formRatings[index] = value;
    notifyListeners();
  }

  void setFormFlood(bool value) {
    formFlood = value;
    notifyListeners();
  }

  void saveProperty() {
    final name = propertyNameController.text.trim();
    final price = int.tryParse(propertyPriceController.text.trim()) ?? 0;
    final average = formRatings.reduce((a, b) => a + b) / formRatings.length;
    final index = editingProperty;
    final existing = index == null ? null : properties[index];
    final record = Property(
      name.isEmpty ? '未命名实勘' : name,
      price,
      formPlace,
      average,
      existing?.safety ?? 76,
      existing?.hazards ?? 1,
      formFlood,
      propertyNoteController.text.trim(),
      photos: [...draftPhotos],
      coverPhotoId: draftPhotos.isEmpty
          ? null
          : (draftCoverPhotoId ?? draftPhotos.first.id),
    );
    if (index == null) {
      properties.add(record);
      detail = properties.length - 1;
    } else {
      properties[index] = record;
      detail = index;
    }
    page = PageId.detail;
    notifyListeners();
  }

  void addDemoPhoto(PhotoSource source) {
    if (draftPhotos.length >= 20) return;
    final next = photoSequence + 1;
    photoSequence = next;
    draftPhotos = [
      ...draftPhotos,
      InspectionPhoto(
        id: 'draft-$next',
        source: source,
        label: source == PhotoSource.camera ? '相机现场照片' : '相册选择照片',
        syncStatus: source == PhotoSource.camera
            ? PhotoSyncStatus.pending
            : PhotoSyncStatus.synced,
      ),
    ];
    notifyListeners();
  }

  void removeDraftPhoto(String id) {
    final wasCover = draftCoverPhotoId == id;
    draftPhotos = draftPhotos.where((photo) => photo.id != id).toList();
    if (wasCover) {
      draftCoverPhotoId = draftPhotos.isEmpty ? null : draftPhotos.first.id;
    }
    notifyListeners();
  }

  void setDraftCover(String id) {
    draftCoverPhotoId = draftPhotos.firstWhere((photo) => photo.id == id).id;
    notifyListeners();
  }

  void updateDraftCaption(String id, String caption) {
    draftPhotos = draftPhotos
        .map(
          (photo) => photo.id == id ? photo.copyWith(caption: caption) : photo,
        )
        .toList();
    notifyListeners();
  }

  void retryPropertyPhoto(int propertyIndex, String photoId) {
    final p = properties[propertyIndex];
    properties[propertyIndex] = p.copyWith(
      photos: p.photos
          .map(
            (photo) => photo.id == photoId
                ? photo.copyWith(syncStatus: PhotoSyncStatus.synced)
                : photo,
          )
          .toList(),
    );
    notifyListeners();
  }

  void openProperty(int index) {
    detail = index;
    go(PageId.detail);
  }

  void toggleCompared(int index) {
    if (compared.contains(index)) {
      compared.remove(index);
    } else if (compared.length < 3) {
      compared.add(index);
    }
    notifyListeners();
  }

  void changeArchiveVariant(int offset) {
    const keys = ['A', 'B', 'C'];
    archiveVariant = (archiveVariant + offset + keys.length) % keys.length;
    SystemNavigator.routeInformationUpdated(
      uri: Uri(queryParameters: {'variant': keys[archiveVariant]}),
      replace: true,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    propertyNameController.dispose();
    propertyPriceController.dispose();
    propertyNoteController.dispose();
    super.dispose();
  }
}
